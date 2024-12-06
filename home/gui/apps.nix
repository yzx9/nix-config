{
  self,
  vars,
  config,
  pkgs,
  lib,
  ...
}:

let
  purpose = config.purpose;
in
{
  config = lib.mkIf purpose.gui {
    # Allow unfree packages
    # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ ];

    # The home.packages option allows you to install Nix packages into your
    # environment.
    home.packages =
      (with pkgs; [
        gopass-jsonapi # you have to run `gopass-jsonapi configure` manually, because I dont know how to do it automatically
        dbeaver-bin # SQL client
        logseq
      ])
      # customized apps
      ++ [ ]
      # darwin will install these apps using homebrew
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.inkscape # SVG design
      ]
      # darwin only
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        self.packages.${vars.system}.vaa3d-x
        pkgs.stats
      ];
  };
}
