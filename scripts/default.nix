{
  lib,
  writeShellApplication,
  coreutils,
  curl,
  dosfstools,
  gawk,
  gptfdisk,
  mkpasswd,
  openssh,
  parted,
  systemd,
  util-linux,
  zfs,
  toplevel,
}:
{
  prepare-disk = writeShellApplication {
    name = "prepare-disk";
    runtimeInputs = [
      coreutils
      curl
      dosfstools
      gawk
      gptfdisk
      parted
      systemd
      util-linux
      zfs
    ];
    text = builtins.readFile ./prepare-disk.sh;
  };

  install-system = writeShellApplication {
    name = "install-system";
    runtimeInputs = [
      coreutils
      mkpasswd
      openssh
      systemd
      util-linux
      zfs
    ];
    text = ''
      TOPLEVEL=${lib.escapeShellArg toplevel}
    ''
    + builtins.readFile ./install-system.sh;
  };
}
