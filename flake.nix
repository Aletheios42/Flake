{
  description = "Mi Configuracion de nixos vainilla con flakes dentriticos";

  inputs = {
    # 1. Nix repositorio official
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # 2. La base de datos de nix-index
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # 3. neovim
    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = { self, nixpkgs, nix-index-database, nvf, ...}@inputs: {

    nixosConfigurations = {
      machine = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/machine/configuration.nix
          nix-index-database.nixosModules.nix-index
          nvf.nixosModules.default
        ];
      };
      server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/server/configuration.nix
          nix-index-database.nixosModules.nix-index
        ];
      };
    };


  };
}

