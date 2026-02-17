{
  description = "NixOS configuration for proasync";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";

    mkHost = { hostModule, homeModule ? ./home/home.nix }: nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        hostModule
        ./modules/common.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.proasync = import homeModule;
        }
      ];
    };
  in
  {
    nixosConfigurations = {
      home-desktop = mkHost {
        hostModule = ./hosts/desktop/configuration.nix;
      };
    };
  };
}
