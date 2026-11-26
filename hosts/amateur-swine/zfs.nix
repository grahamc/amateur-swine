{ config, ... }:
{
  boot.supportedFilesystems.zfs = true;
  boot.zfs.forceImportRoot = false;
  boot.zfs.devNodes = "/dev/disk/by-partlabel";

  # ZFS needs a unique host ID.
  networking.hostId = "eba2f056";

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
    # Snapshots only the datasets with com.sun:auto-snapshot=true (rpool/safe).
    autoSnapshot.enable = true;
  };

  fileSystems = {
    "/" = {
      device = "rpool/local/root";
      fsType = "zfs";
    };
    "/nix" = {
      device = "rpool/local/nix";
      fsType = "zfs";
    };
    "/home" = {
      device = "rpool/safe/home";
      fsType = "zfs";
    };
    "/persist" = {
      device = "rpool/safe/persist";
      fsType = "zfs";
      neededForBoot = true;
    };
  };

  # Erase your darlings: each boot starts with an empty root dataset.
  boot.initrd.systemd.services.rollback-root = {
    description = "Roll back the root dataset to its blank snapshot";
    wantedBy = [ "initrd.target" ];
    requires = [ "zfs-unlock-rpool.service" ];
    after = [ "zfs-unlock-rpool.service" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      ${config.boot.zfs.package}/bin/zfs rollback -r rpool/local/root@blank
    '';
  };
}
