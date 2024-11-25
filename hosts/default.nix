{
  self,
  nixpkgs,
  agenix,
  home-manager,
  darwin,
  ...
}@inputs:

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
    git = {
      name = "Zexin Yuan";
      email = "git@yzx9.xyz";
    };
  };

  hosts = toHostAttrs [
    {
      hostname = "yzx9-mbp";
      type = "nix-darwin";
      system = "aarch64-darwin";
      user = yzx9;
    }
    {
      hostname = "yzx9-ws";
      type = "nixos";
      system = "x86_64-linux";
      user = yzx9;
    }
    {
      hostname = "cvcd-gpu0";
      type = "home-manager";
      system = "x86_64-linux";
      user = yzx9 // {
        name = "yzx";
      };
    }
  ];

  forHosts =
    type: f:

    lib.mapAttrs (
      hostname: vars:
      let
        specialArgs = {
          inherit self inputs vars;
        };
      in
      f {
        inherit vars specialArgs;
        pkgs = nixpkgs.legacyPackages.${vars.system};
        modules = [
          ./${hostname}/config.nix
          ./${hostname}/host.nix
        ];
        hmSpecialArgs = specialArgs;
        hmModules = [
          ./${hostname}/config.nix
          ./${hostname}/home.nix
        ];
      }
    ) (lib.filterAttrs (k: v: v.type == type) hosts);

  mkHMConfiguration = args: {
    home-manager.useGlobalPkgs = false;
    home-manager.useUserPackages = false;
    home-manager.extraSpecialArgs = args.hmSpecialArgs;
    home-manager.users.${args.vars.user.name} = import ../home;
    home-manager.sharedModules = args.hmModules ++ [
      agenix.homeManagerModules.default
    ];
  };
in
{
  nixosConfigurations = forHosts "nixos" (
    args:
    nixpkgs.lib.nixosSystem {
      inherit (args) specialArgs;
      inherit (args.vars) system;
      modules = args.modules ++ [
        ../modules/nixos

        agenix.nixosModules.default

        home-manager.nixosModules.home-manager
        (mkHMConfiguration args)
      ];
    }
  );

  darwinConfigurations = forHosts "nix-darwin" (
    args:
    darwin.lib.darwinSystem {
      inherit (args) specialArgs;
      inherit (args.vars) system;
      modules = args.modules ++ [
        ../modules/nix-darwin

        agenix.darwinModules.default

        home-manager.darwinModules.home-manager
        (mkHMConfiguration args)
      ];
    }
  );

  homeConfigurations = forHosts "home-manager" (
    args:
    home-manager.lib.homeManagerConfiguration {
      inherit (args) pkgs;

      modules = args.hmModules ++ [
        ../home

        agenix.homeManagerModules.default
      ];
      extraSpecialArgs = args.hmSpecialArgs;
    }
  );
}
