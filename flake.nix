{
  description = "Mi Configuracion de nixos vainilla";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = { nixpkgs, nix-index-database, nvf, ...}: {

    nixosConfigurations = {

      machine = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/machine/configuration.nix
          nix-index-database.nixosModules.nix-index
          nvf.nixosModules.default
        ];
      };

      server1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/server/configuration.nix
          nix-index-database.nixosModules.nix-index
        ];
      };
    };
  };
}
