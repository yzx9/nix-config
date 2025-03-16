{
  self,
  nixpkgs,
  nix-darwin,
  agenix,
  home-manager,
  ...
}@inputs:

let
  specialArgs = { inherit self inputs; };
  mkModules = cfg: [
    cfg.config
    (cfg.host or { })
    (mkHMConfiguration cfg)
  ];
  mkHmModules = cfg: [
    cfg.config
    (cfg.home or { })
  ];

  mkHMConfiguration = cfg: {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = specialArgs;
    home-manager.users.${cfg.config.vars.user.name} = import ../../home;
    home-manager.sharedModules = (mkHmModules cfg) ++ [ agenix.homeManagerModules.default ];
  };
in
{
  mkNixosConfiguration = cfg: {
    nixosConfigurations."${cfg.config.vars.hostname}" = nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      inherit (cfg.config.vars) system;
      modules = (mkModules cfg) ++ [ ../../modules/nixos ];
    };
  };

  mkDarwinConfiguration = cfg: {
    darwinConfigurations."${cfg.config.vars.hostname}" = nix-darwin.lib.darwinSystem {
      inherit specialArgs;
      inherit (cfg.config.vars) system;
      modules = (mkModules cfg) ++ [ ../../modules/nix-darwin ];
    };
  };

  mkHomeConfiguration = cfg: {
    homeConfigurations."${cfg.config.vars.hostname}" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${cfg.config.vars.system};
      modules = (mkHmModules cfg) ++ [ ../../modules/home-manager ];
      extraSpecialArgs = specialArgs;
    };
  };
}
