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
    lib = nixpkgs.lib;

    # One name drives everything: flake attribute = networking.hostName =
    # hosts/<name>/ (so `nrs`, which uses $(hostname), always finds its host).
    # A host may add hosts/<name>/home.nix for per-host Home Manager overrides.
    mkHost = name: lib.nixosSystem {
      inherit system;
      modules = [
        ./hosts/${name}/configuration.nix
        ./modules/common.nix
        { networking.hostName = name; }

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.proasync.imports =
            [ ./home/home.nix ]
            ++ lib.optional (builtins.pathExists ./hosts/${name}/home.nix)
                 ./hosts/${name}/home.nix;
        }
      ];
    };
  in
  {
    nixosConfigurations = lib.genAttrs [
      "home-desktop"
      "proasync-laptop"
      "work-desktop"
    ] mkHost;
  };
}
