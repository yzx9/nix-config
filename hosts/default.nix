{
  self,
  nixpkgs,
  darwin,
  agenix,
  home-manager,
  ...
}@inputs:

let
  inherit (nixpkgs) lib;

  hosts = [
    (import ./cvcd-gpu0/config.nix)
    (import ./yzx9-mbp/config.nix)
    (import ./yzx9-rpi5/config.nix)
    (import ./yzx9-ws/config.nix)
  ];

  forHosts =
    type: f:
    lib.listToAttrs (
      lib.map (cfg: {
        name = cfg.vars.hostname;
        value = f cfg;
      }) (lib.filter (cfg: cfg.vars.type == type) hosts)
    );

  mkArgs =
    cfg:

    let
      inherit (cfg) vars;
      commonModules = [ ./${vars.hostname}/config.nix ];
      specialArgs = { inherit self inputs; };
    in
    {
      inherit vars specialArgs;
      pkgs = nixpkgs.legacyPackages.${vars.system};
      modules = commonModules ++ [ ./${vars.hostname}/host.nix ];
      hmSpecialArgs = specialArgs;
      hmModules = commonModules ++ [ ./${vars.hostname}/home.nix ];
    };

  mkHMConfiguration = args: {
    home-manager.useGlobalPkgs = false;
    home-manager.useUserPackages = false;
    home-manager.extraSpecialArgs = args.hmSpecialArgs;
    home-manager.users.${args.vars.user.name} = import ../home;
    home-manager.sharedModules = args.hmModules ++ [ agenix.homeManagerModules.default ];
  };
in
{
  nixosConfigurations = forHosts "nixos" (
    cfg:

    let
      args = mkArgs cfg;
    in
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
    cfg:

    let
      args = mkArgs cfg;
    in
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
    cfg:

    let
      args = mkArgs cfg;
    in
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
