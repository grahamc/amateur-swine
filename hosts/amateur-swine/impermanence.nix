# Everything on / is erased at boot.
# These paths are kept on rpool/safe/persist.
# /nix and /home are separate datasets, and they are not erased.
{ ... }:
{
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/tailscale"
      "/var/lib/fwupd"
      "/var/lib/rex"
      {
        directory = "/var/lib/private";
        mode = "0700";
      }
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}
