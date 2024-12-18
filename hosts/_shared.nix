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

  mkArgs =
    cfg:

    let
      inherit (cfg) vars;
      specialArgs = { inherit self inputs; };
    in
    {
      inherit vars specialArgs;
      pkgs = nixpkgs.legacyPackages.${vars.system};
      modules = [
        cfg
        (ifPathExists ./${vars.hostname}/host.nix)
      ];
      hmSpecialArgs = specialArgs;
      hmModules = [
        cfg
        (ifPathExists ./${vars.hostname}/home.nix)
      ];
    };

  mkHMConfiguration = args: {
    home-manager.useGlobalPkgs = false;
    home-manager.useUserPackages = false;
    home-manager.extraSpecialArgs = args.hmSpecialArgs;
    home-manager.users.${args.vars.user.name} = import ../home;
    home-manager.sharedModules = args.hmModules ++ [ agenix.homeManagerModules.default ];
  };

  ifPathExists = f: lib.optionalString (lib.pathExists f) f;
in
{
  mkNixosConfiguration =
    cfg:

    let
      args = mkArgs cfg;
    in
    {
      nixosConfigurations."${cfg.vars.hostname}" = nixpkgs.lib.nixosSystem {
        inherit (args) specialArgs;
        inherit (args.vars) system;
        modules = args.modules ++ [
          ../modules/nixos

          agenix.nixosModules.default

          home-manager.nixosModules.home-manager
          (mkHMConfiguration args)
        ];
      };
    };

  mkDarwinConfiguration =
    cfg:

    let
      args = mkArgs cfg;
    in
    {
      darwinConfigurations."${cfg.vars.hostname}" = darwin.lib.darwinSystem {
        inherit (args) specialArgs;
        inherit (args.vars) system;
        modules = args.modules ++ [
          ../modules/nix-darwin

          agenix.darwinModules.default

          home-manager.darwinModules.home-manager
          (mkHMConfiguration args)
        ];
      };
    };

  mkHomeConfiguration =
    cfg:

    let
      args = mkArgs cfg;
    in
    {
      homeConfigurations."${cfg.vars.hostname}" = home-manager.lib.homeManagerConfiguration {
        inherit (args) pkgs;

        modules = args.hmModules ++ [
          ../home

          agenix.homeManagerModules.default
        ];
        extraSpecialArgs = args.hmSpecialArgs;
      };
    };
}
