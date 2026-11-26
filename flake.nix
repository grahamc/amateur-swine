{
  description = "amateur-swine: a Dell XPS 13 9300 that lives in a rack";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/secure-packages-rolling/0";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    nixos-hardware.url = "https://flakehub.com/f/NixOS/nixos-hardware/*";

    impermanence.url = "https://flakehub.com/f/nix-community/impermanence/*";

    rex = {
      url = "https://pkgs.superlogical.com/rex/nix/preview.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        amateur-swine = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/amateur-swine ];
        };

        installer = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ./installer ];
        };
      };

      packages.${system} = {
        default = self.packages.${system}.amateur-swine;
        amateur-swine = self.nixosConfigurations.amateur-swine.config.system.build.toplevel;
        installer-iso = self.nixosConfigurations.installer.config.system.build.isoImage;
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
