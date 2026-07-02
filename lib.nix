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
        inputs.self.homeManagerModules.default
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

  mkNixosRpiConfiguration =
    cfg:
    let
      rpiCommonModules = (mkModules cfg) ++ [
        ./modules/nixos

        {
          # Rpi use custom bootloader
          boot.loader.raspberry-pi.bootloader = "kernel";
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

      rpiSpecialArgs = specialArgs // {
        inherit nixos-raspberrypi;
      };

      # Build the Raspberry Pi NixOS system from the shared module set.
      # `extraModules` is used to layer the `sd-image` module on top for image
      # builds without affecting the running system.
      rpiSystem =
        extraModules:
        nixos-raspberrypi.lib.nixosSystem {
          inherit (cfg.config.vars) system;
          modules = rpiCommonModules ++ extraModules;
          specialArgs = rpiSpecialArgs;
        };
    in
    {
      nixosConfigurations."${cfg.config.vars.hostname}" = rpiSystem [ ];

      # Pre-provisioned SD-card image, built from the very same host config.
      # The `sd-image` module is added only here so the running system stays
      # untouched; it produces `config.system.build.sdImage` with the
      # `FIRMWARE` / `NIXOS_SD` partition labels already expected by the
      # host's `hardware-configuration.nix`.
      images."${cfg.config.vars.hostname}" =
        (rpiSystem [ nixos-raspberrypi.nixosModules.sd-image ]).config.system.build.sdImage;
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
