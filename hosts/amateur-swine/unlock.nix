# Unlock the encrypted pool without a person at the console.
#
# 1. The initrd gets an address with DHCP on the USB-C Ethernet adapter.
# 2. It downloads the passphrase from the URL in /etc/zfs-key-url.
# 3. If the download fails, it asks for the passphrase.
#    Answer at the console, or over SSH:
#      ssh -p 2222 root@amateur-swine
#      systemd-tty-ask-password-agent
#
# The URL is not in this repository.
# prepare-disk writes it to /persist/etc/secrets/initrd/zfs-key-url,
# and the bootloader installation copies it into the initrd.
# Anyone who can read the boot partition can read the URL.
# If someone steals the machine, delete the gist.
{ config, pkgs, ... }:
let
  sshKeys = import ../../lib/ssh-keys.nix;
  cacert = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
in
{
  # The NixOS ZFS module must not ask for the passphrase.
  # zfs-unlock-rpool does that.
  boot.zfs.requestEncryptionCredentials = false;

  boot.initrd.secrets."/etc/zfs-key-url" = "/persist/etc/secrets/initrd/zfs-key-url";

  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 2222;
      hostKeys = [ "/persist/etc/secrets/initrd/ssh_host_ed25519_key" ];
      authorizedKeys = sshKeys;
    };
  };

  boot.initrd.systemd = {
    network = {
      enable = true;
      networks."10-ethernet" = {
        matchConfig.Name = "en*";
        networkConfig.DHCP = "yes";
      };
    };

    extraBin.curl = "${pkgs.curl}/bin/curl";
    storePaths = [ cacert ];

    services.zfs-unlock-rpool = {
      description = "Load the encryption key for rpool";
      wantedBy = [ "initrd.target" ];
      requires = [ "zfs-import-rpool.service" ];
      after = [
        "zfs-import-rpool.service"
        "systemd-tmpfiles-setup.service"
        "systemd-networkd.service"
        "systemd-resolved.service"
      ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -o pipefail

        if [ "$(zfs get -H -o value keystatus rpool)" = available ]; then
          exit 0
        fi

        if [ -s /etc/zfs-key-url ]; then
          url=$(cat /etc/zfs-key-url)
          for attempt in $(seq 1 30); do
            if curl --fail --silent --show-error --max-time 10 \
                --cacert ${cacert} "$url" \
                | zfs load-key rpool; then
              echo "Loaded the rpool key from the URL."
              exit 0
            fi
            echo "Attempt $attempt to download the rpool key failed."
            sleep 2
          done
        else
          echo "/etc/zfs-key-url is missing."
        fi

        echo "Waiting for the rpool passphrase."
        echo "Type it at the console, or run 'systemd-tty-ask-password-agent' over SSH on port ${toString config.boot.initrd.network.ssh.port}."
        until ${config.boot.initrd.systemd.package}/bin/systemd-ask-password \
            --timeout=0 --id=zfs:rpool "Passphrase for rpool:" \
            | zfs load-key rpool; do
          echo "That passphrase did not work."
        done
      '';
    };
  };
}
