{
  description = "amateur-swine: a Dell XPS 13 9300 that lives in a rack";

  inputs = {
    # nixos-unstable is in cache.nixos.org, so CI builds little.
    # The secure-packages branch switches to Determinate Secure Packages rolling.
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    # The FlakeHub copy of nixos-hardware stopped updating in October 2025.
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # FlakeHub has only the home-manager release branches.
    # Secure Packages rolling is nixpkgs master, so use home-manager master.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "https://flakehub.com/f/nix-community/impermanence/*";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "";
    };

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
