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
      users.${cfg.config.vars.user.name} = import ./home;
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
      modules = (mkModules cfg) ++ [ ./modules/nixos ];
    };
  };

  mkNixosRpiConfiguration = cfg: {
    nixosConfigurations."${cfg.config.vars.hostname}" = nixos-raspberrypi.lib.nixosSystem {
      inherit (cfg.config.vars) system;
      modules = (mkModules cfg) ++ [
        ./modules/nixos

        {
          # Rpi use custom bootloader
          boot.loader.systemd-boot.enable = false;
          boot.loader.efi.canTouchEfiVariables = false;

          nix.settings = {
            substituters = [
              "https://nixos-raspberrypi.cachix.org"
            ];

            trusted-public-keys = [
              "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
            ];
          };
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
      modules = (mkModules cfg) ++ [ ./modules/nix-darwin ];
    };
  };

  mkHomeConfiguration = cfg: {
    homeConfigurations."${cfg.config.vars.hostname}" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${cfg.config.vars.system};
      modules = (mkHmModules cfg) ++ [ ./modules/home-manager ];
      extraSpecialArgs = specialArgs;
    };
  };
}
