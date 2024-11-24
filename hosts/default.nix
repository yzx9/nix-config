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
          inherit self inputs vars;
        };
      in
      f {
        inherit vars specialArgs;
        pkgs = nixpkgs.legacyPackages.${vars.system};
        modules = [
          ./${vars.hostname}/config.nix
          ./${vars.hostname}/host.nix
        ];
        hmSpecialArgs = specialArgs;
        hmModules = [
          ./${vars.hostname}/config.nix
          ./${vars.hostname}/home.nix
        ];
      }
    );

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
  nixosConfigurations = forHosts [ "yzx9-ws" ] (
    args:
    nixpkgs.lib.nixosSystem {
      inherit (args) specialArgs;
      system = args.vars.system;
      modules = args.modules ++ [
        ../modules/nixos

        agenix.nixosModules.default

        home-manager.nixosModules.home-manager
        (mkHMConfiguration args)
      ];
    }
  );

  darwinConfigurations = forHosts [ "yzx9-mbp" ] (
    args:
    darwin.lib.darwinSystem {
      inherit (args) specialArgs;
      system = args.vars.system;
      modules = args.modules ++ [
        ../modules/nix-darwin

        agenix.darwinModules.default

        home-manager.darwinModules.home-manager
        (mkHMConfiguration args)
      ];
    }
  );

  homeConfigurations = forHosts [ "cvcd-gpu0" ] (
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
