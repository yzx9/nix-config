# Soothing pastel theme for (Neo)vim
# homepage: https://github.com/catppuccin/nvim
# nixvim doc: https://nix-community.github.io/nixvim/colorschemes/catppuccin/index.html
{
  colorscheme = "catppuccin";

  colorschemes.catppuccin = {
    enable = true;
    lazyLoad.enable = true;

    settings = {
      flavour = "mocha";

      # Needed to keep terminal transparency, if any
      transparent_background = true;
    };
  };
}
