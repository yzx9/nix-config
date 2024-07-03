{ pkgs, ... }:

{
  home.packages = with pkgs; [
    marksman
    glow # markdown terminal previewer
    pandoc # convert markdown to other format
    texliveSmall
  ];

  programs.helix.languages.language = [
    {
      name = "markdown";
      soft-wrap.enable = true;
    }
  ];
}
