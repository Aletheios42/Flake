{
  description = "Mi Configuracion de nixos con flakes y homemanager";

  inputs = {
    # 1. Nix repositorio official
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # 2. Home-manager repositorio official
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # 3. La base de datos de nix-index
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = { self, nixpkgs, home-manager, nix-index-database, nvf, ...}@inputs: {
    nixosConfigurations = {
      machine = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # Para que esta linea home-manager hereda todo lo de config.nix(es decir el sistema)
        specialArgs = { inherit inputs; };
        modules = [
          # 1. 
          ./configuration.nix

          # 3.
          nix-index-database.nixosModules.nix-index

          # 2.
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Asi gestiona home-manager las colisiones de nombres
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.aletheios42 = import ./home.nix;
          }
        ];
      };
    };
  };
}
