{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nil
    nixfmt-rfc-style
  ];

  programs.helix.languages.language = [
    {
      name = "nix";
      auto-format = true;
      formatter.command = "nixfmt";
    }
  ];
}
