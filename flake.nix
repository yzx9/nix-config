{
  description = "yzx9's nix configuration";

  # the nixConfig here only affects the flake itself, not the system configuration!
  nixConfig = {
    # NOTE: don't forget to update `module/_shared/nix-core.nix`
    extra-substituters = [
      # Query the mirror first
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"

      "https://nix-community.cachix.org"
      # "https://cache.nixos.org"
    ];

    # NOTE: don't forget to update `module/_shared/nix-core.nix`
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      # "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    raspberry-pi-nix = {
      url = "github:nix-community/raspberry-pi-nix";

      # NOTE: dont override nixpkgs since it leads cache-missing
      # See also: https://github.com/nix-community/raspberry-pi-nix/issues/113#issuecomment-2624809306
      #
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    # Manage a user environment using Nix
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # age-encrypted secrets for NixOS and Home manager
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "nix-darwin";
        home-manager.follows = "home-manager";
      };
    };

    # Configure Neovim with Nix!
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  # The `outputs` function will return all the build results of the flake.
  # A flake can have many use cases and different types of outputs,
  # parameters in `outputs` are defined in `inputs` and can be referenced by their names.
  # However, `self` is an exception, this special parameter points to the `outputs` itself (self-reference)
  # The `@` syntax here is used to alias the attribute set of the inputs's parameter, making it convenient to use inside the function.
  outputs =
    { nixpkgs, home-manager, ... }@inputs:

    let
      hosts = import ./hosts inputs;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      inherit (hosts) nixosConfigurations darwinConfigurations homeConfigurations;

      # nix run .#<command>
      packages = forEachSystem (system: import ./packages (inputs // { inherit system; }));

      # nix develop
      devShells = forEachSystem (
        system:

        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = [
              pkgs.just
              home-manager.packages.${system}.default
              inputs.agenix.packages.${system}.default
            ];
          };
        }
      );

      # nix flake init -t yzx9#<template_name>
      templates = import ./templates;

      # nix fmt: nix code formatter
      formatter = forEachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
