# An installer image with ZFS, SSH access, the disk scripts,
# and the complete amateur-swine system.
{
  config,
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  toplevel = inputs.self.nixosConfigurations.amateur-swine.config.system.build.toplevel;
  scripts = pkgs.callPackage ../scripts {
    inherit toplevel;
    zfs = config.boot.zfs.package;
  };
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    inputs.determinate.nixosModules.default
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  image.baseName = lib.mkForce "amateur-swine-installer";
  isoImage.storeContents = [ toplevel ];

  boot.supportedFilesystems.zfs = true;
  networking.hostId = "4e1b6f2a";

  # Log in from another machine with: ssh root@nixos
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = import ../lib/ssh-keys.nix;
  users.users.nixos.openssh.authorizedKeys.keys = import ../lib/ssh-keys.nix;

  environment.systemPackages = [
    scripts.prepare-disk
    scripts.install-system
  ];

  # A copy of this flake, for changes during installation.
  environment.etc."amateur-swine".source = inputs.self;
}
