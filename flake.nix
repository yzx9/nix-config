{
  description = "Nix for macOS configuration";

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
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # The `outputs` function will return all the build results of the flake.
  # A flake can have many use cases and different types of outputs,
  # parameters in `outputs` are defined in `inputs` and can be referenced by their names.
  # However, `self` is an exception, this special parameter points to the `outputs` itself (self-reference)
  # The `@` syntax here is used to alias the attribute set of the inputs's parameter, making it convenient to use inside the function.
  outputs =
    inputs@{
      self,
      nixpkgs,
      darwin,
      home-manager,
      ...
    }:

    let
      inherit (nixpkgs) lib;

      username = "yzx9";
      useremail = "yuan.zx@outlook.com";
      hosts = {
        yzx9-mbp = {
          inherit username useremail;
          system = "aarch64-darwin";
        };
        cvcd-gpu0 = {
          inherit useremail;
          system = "x86_64-linux";
          username = "yzx";
        };
      };
      systems = lib.unique lib.attrValues lib.mapAttrs (name: value: value.system) hosts;

      forEachHost =
        f:
        lib.mapAttrs (
          hostname: host:
          let
            specialArgs = {
              inherit inputs hostname;
              inherit (host) username useremail;
            };
          in
          f {
            inherit hostname specialArgs;
            inherit (host) system;
            pkgs = nixpkgs.legacyPackages.${host.system};
            hmSpecialArgs = builtins.removeAttrs specialArgs [ "hostname" ];
          }
        ) hosts;
      forEachSystem = f: lib.genAttrs systems (system: f { pkgs = nixpkgs.legacyPackages.${system}; });
    in
    {
      darwinConfigurations = forEachHost (
        args:
        darwin.lib.darwinSystem {
          inherit (args) system specialArgs;
          modules = [
            ./modules/nix-core.nix
            ./modules/system-darwin.nix
            ./modules/apps.nix
            ./modules/homebrew.nix
            ./modules/host-users.nix

            # home manager
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = false;
              home-manager.extraSpecialArgs = args.hmSpecialArgs;
              home-manager.users.${username} = import ./home;
              # home-manager.sharedModules = [ nur.hmModules.nur ];
            }
          ];
        }
      );

      homeConfigurations = forEachHost (
        { pkgs, hmSpecialArgs, ... }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [ ./home ];

          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
          extraSpecialArgs = hmSpecialArgs;
        }
      );

      # nix code formatter
      formsdfatter = forEachSystem ({ pkgs, ... }: pkgs.nixfmt-rfc-style);
    };
}
