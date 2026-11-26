{ ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.grahamc = import ../../home/grahamc.nix;
  };
}
