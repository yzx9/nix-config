{
  description = "yzx9's nix configuration";

  ## the nixConfig here only affects the flake itself, not the system configuration!
  ##
  ## Skip mirror since we are using proxy
  # nixConfig = {
  #   substituters = [
  #     # Query the mirror of USTC first, and then the official cache.
  #     "https://mirrors.ustc.edu.cn/nix-channels/store"
  #     "https://cache.nixos.org"
  #   ];
  # };

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # nur.url = "github:nix-community/NUR";

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-darwin.follows = "darwin";
        home-manager.follows = "home-manager";
      };
    };
  };

  # The `outputs` function will return all the build results of the flake.
  # A flake can have many use cases and different types of outputs,
  # parameters in `outputs` are defined in `inputs` and can be referenced by their names.
  # However, `self` is an exception, this special parameter points to the `outputs` itself (self-reference)
  # The `@` syntax here is used to alias the attribute set of the inputs's parameter, making it convenient to use inside the function.
  outputs =
    inputs@{
      nixpkgs,
      darwin,
      home-manager,
      ...
    }:

    let
      inherit (nixpkgs) lib;

      toHostAttrs =
        list:
        lib.listToAttrs (
          lib.forEach list (v: {
            name = v.hostname;
            value = v;
          })
        );

      yzx9 = {
        name = "yzx9";
        nickname = "yzx9";
        email = "yuan.zx@outlook.com";
        gpg = {
          key = "0xC2DD1916FE471BE2";
        };
      };

      hosts = toHostAttrs [
        {
          hostname = "yzx9-mbp";
          system = "aarch64-darwin";
          user = yzx9;
        }
        {
          hostname = "yzx9-ws";
          system = "x86_64-linux";
          user = yzx9;
        }
        {
          hostname = "cvcd-gpu0";
          system = "x86_64-linux";
          user = yzx9 // {
            name = "yzx";
          };
        }
      ];

      forHosts =
        hostnames: f:
        lib.genAttrs hostnames (
          hostname:
          let
            vars = hosts.${hostname};
            specialArgs = {
              inherit inputs vars;
            };
          in
          f {
            inherit vars specialArgs;
            pkgs = nixpkgs.legacyPackages.${vars.system};
            modules = [
              ./options.nix
              ./hosts/${vars.hostname}/config.nix
              ./hosts/${vars.hostname}/host.nix
            ];
            hmSpecialArgs = specialArgs;
            hmModules = [
              ./options.nix
              ./hosts/${vars.hostname}/config.nix
              ./hosts/${vars.hostname}/home.nix
            ];
          }
        );

      systems = lib.unique lib.attrValues lib.mapAttrs (name: value: value.system) hosts;
      forEachSystem = f: lib.genAttrs systems (system: f { pkgs = nixpkgs.legacyPackages.${system}; });
    in
    {
      nixosConfigurations = forHosts [ "yzx9-ws" ] (
        args:
        nixpkgs.lib.nixosSystem {
          inherit (args) specialArgs;
          system = args.vars.system;
          modules = args.modules ++ [
            ./modules/linux

            # home manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = false;
              home-manager.extraSpecialArgs = args.hmSpecialArgs;
              home-manager.users.${args.vars.user.name} = import ./home;
              home-manager.sharedModules = args.hmModules;
            }
          ];
        }
      );

      darwinConfigurations = forHosts [ "yzx9-mbp" ] (
        args:
        darwin.lib.darwinSystem {
          inherit (args) specialArgs;
          system = args.vars.system;
          modules = args.modules ++ [
            ./modules/darwin

            # home manager
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = false;
              home-manager.extraSpecialArgs = args.hmSpecialArgs;
              home-manager.users.${args.vars.user.name} = import ./home;
              home-manager.sharedModules = args.hmModules;
            }
          ];
        }
      );

      homeConfigurations = forHosts [ "cvcd-gpu0" ] (
        args:
        home-manager.lib.homeManagerConfiguration {
          inherit (args) pkgs;

          modules = args.hmModules ++ [
            ./home
            ./options.nix
          ];

          extraSpecialArgs = args.hmSpecialArgs;
        }
      );

      # nix code formatter
      formatter = forEachSystem ({ pkgs, ... }: pkgs.nixfmt-rfc-style);
    };
}
