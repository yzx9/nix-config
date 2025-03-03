{
  self,
  nixpkgs,
  nix-darwin,
  agenix,
  home-manager,
  ...
}@inputs:

let
  inherit (nixpkgs) lib;

  specialArgs = { inherit self inputs; };
  mkModules = cfg: [ cfg ] ++ (ifPathExists ../${cfg.vars.hostname}/host.nix);
  mkHmModules = cfg: [ cfg ] ++ (ifPathExists ../${cfg.vars.hostname}/home.nix);

  mkHMConfiguration = cfg: {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = specialArgs;
    home-manager.users.${cfg.vars.user.name} = import ../../home;
    home-manager.sharedModules = (mkHmModules cfg) ++ [ agenix.homeManagerModules.default ];
  };

  ifPathExists = f: lib.optional (lib.pathExists f) f;
in
{
  mkNixosConfiguration = cfg: {
    nixosConfigurations."${cfg.vars.hostname}" = nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      inherit (cfg.vars) system;

      modules = (mkModules cfg) ++ [
        ../../modules/nixos

        (mkHMConfiguration cfg)
      ];
    };
  };

  mkDarwinConfiguration = cfg: {
    darwinConfigurations."${cfg.vars.hostname}" = nix-darwin.lib.darwinSystem {
      inherit specialArgs;
      inherit (cfg.vars) system;

      modules = (mkModules cfg) ++ [
        ../../modules/nix-darwin

        (mkHMConfiguration cfg)
      ];
    };
  };

  mkHomeConfiguration = cfg: {
    homeConfigurations."${cfg.vars.hostname}" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${cfg.vars.system};

      modules = (mkHmModules cfg) ++ [
        ../../modules/home-manager
      ];

      extraSpecialArgs = specialArgs;
    };
  };
}
