{
  nixpkgs,
  nixos-raspberrypi,
  nix-darwin,
  agenix,
  home-manager,
  ...
}@inputs:

let
  specialArgs = { inherit inputs; };

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
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = specialArgs;
      users.${cfg.config.vars.user.name} = import ../../home;
      sharedModules = (mkHmModules cfg) ++ [
        agenix.homeManagerModules.default
      ];
    };
  };
in
{
  mkNixosConfiguration = cfg: {
    nixosConfigurations."${cfg.config.vars.hostname}" = nixpkgs.lib.nixosSystem {
      inherit (cfg.config.vars) system;
      inherit specialArgs;
      modules = (mkModules cfg) ++ [ ../nixos ];
    };
  };

  mkNixosRpiConfiguration = cfg: {
    nixosConfigurations."${cfg.config.vars.hostname}" = nixos-raspberrypi.lib.nixosSystem {
      inherit (cfg.config.vars) system;
      modules = (mkModules cfg) ++ [
        ../nixos

        {
          # Rpi use custom bootloader
          boot.loader.systemd-boot.enable = false;
          boot.loader.efi.canTouchEfiVariables = false;
        }
      ];
      specialArgs = specialArgs // {
        inherit (specialArgs) nixos-raspberrypi;
      };
    };
  };

  mkDarwinConfiguration = cfg: {
    darwinConfigurations."${cfg.config.vars.hostname}" = nix-darwin.lib.darwinSystem {
      inherit (cfg.config.vars) system;
      inherit specialArgs;
      modules = (mkModules cfg) ++ [ ../nix-darwin ];
    };
  };

  mkHomeConfiguration = cfg: {
    homeConfigurations."${cfg.config.vars.hostname}" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${cfg.config.vars.system};
      modules = (mkHmModules cfg) ++ [ ../home-manager ];
      extraSpecialArgs = specialArgs;
    };
  };
}
