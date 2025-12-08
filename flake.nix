{
  description = "yzx9's nix configuration";

  # the nixConfig here only affects the flake itself, not the system configuration!
  nixConfig = {
    # NOTE: don't forget to update `module/_shared/nix-core.nix`
    extra-substituters = [
      # Query the mirror first
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org"

      "https://nix-community.cachix.org"
      "https://yzx9.cachix.org"
      "https://nixos-raspberrypi.cachix.org"
    ];

    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "yzx9.cachix.org-1:h2efDUniPK7YZAKoWZUbKH9nnxsawcKXqRjAYGkNwig="
    ];
  };

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NOTE: dont override nixpkgs since it leads cache-missing
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi";

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
        systems.follows = "systems";
        darwin.follows = "nix-darwin";
        home-manager.follows = "home-manager";
      };
    };

    # Configure Neovim with Nix!
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    # A collection of Firefox add-ons packaged for Nix.
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=/pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Analyze. Interact. Manage Your Time, with calendar support
    aim = {
      url = "github:yzx9/aim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
  };

  # The `outputs` function will return all the build results of the flake.
  # A flake can have many use cases and different types of outputs, parameters
  # in `outputs` are defined in `inputs` and can be referenced by their names.
  #
  # However, `self` is an exception, this special parameter points to the
  # `outputs` itself (self-reference).
  #
  # The `@` syntax here is used to alias the attribute set of the inputs's
  # parameter, making it convenient to use inside the function.
  outputs =
    { nixpkgs, systems, ... }@inputs:

    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      inherit (import ./hosts inputs) nixosConfigurations darwinConfigurations homeConfigurations;

      lib = import ./lib.nix inputs;

      overlays = import ./overlays inputs;

      # nix run .#<command>
      packages = eachSystem (import ./packages inputs);

      # nix develop
      devShells = eachSystem (
        system:

        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.just
              pkgs.nixos-rebuild
              inputs.agenix.packages.${system}.default
              inputs.home-manager.packages.${system}.default
            ];
          };
        }
      );

      # nix flake init -t yzx9#<template_name>
      templates = import ./templates;

      # nix fmt: nix code formatter
      formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
