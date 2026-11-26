{ inputs, ... }:
{
  imports = [
    inputs.determinate.nixosModules.default
    inputs.nixos-hardware.nixosModules.dell-xps-13-9300
    inputs.impermanence.nixosModules.impermanence
    inputs.rex.nixosModules.default

    ./hardware.nix
    ./zfs.nix
    ./unlock.nix
    ./impermanence.nix
    ./network.nix
    ./server.nix
    ./desktop.nix
    ./rex.nix
    ./users.nix
  ];

  networking.hostName = "amateur-swine";

  time.timeZone = "UTC";

  # The release of NixOS that was first installed on this machine.
  # Do not change it after installation.
  system.stateVersion = "26.11";
}
