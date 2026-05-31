{
  description = "Mi Configuracion de nixos vainilla";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
    simple-nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, nix-index-database, nvf, impermanence, disko, sops-nix, simple-nixos-mailserver, ...}: {
    nixosModules.default = import ./modules/default.nix;

    nixosConfigurations = {
      machine = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/machine/configuration.nix
          nix-index-database.nixosModules.nix-index
          nvf.nixosModules.default
          impermanence.nixosModules.impermanence
          disko.nixosModules.disko # <--- VUELVE A AÑADIR DISKO AQUÍ
          sops-nix.nixosModules.sops
          simple-nixos-mailserver.nixosModule
        ];
      };

      server1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/server1/configuration.nix
          nix-index-database.nixosModules.nix-index
          nvf.nixosModules.default
          impermanence.nixosModules.impermanence
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          simple-nixos-mailserver.nixosModule
        ];
      };
    };
  };
}
