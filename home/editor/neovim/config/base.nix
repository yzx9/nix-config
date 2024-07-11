{ pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    # Set 'vi' and 'vim' aliases to nixvim
    viAlias = true;
    vimAlias = true;

    luaLoader.enable = true;

    # Setup clipboard support
    clipboard = {
      # Use xsel as clipboard provider
      providers.xsel.enable = true;

      # Sync system clipboard
      register = if (pkgs.stdenv.isLinux) then "unnamedplus" else "unnamed";
    };

    # Use <Space> as leader key
    globals.mapleader = " ";

    opts = {
      number = true; # Show line numbers
      relativenumber = true; # Show relative line numbers

      shiftwidth = 2; # Tab width should be 2
    };

    colorschemes = {
      catppuccin = {
        enable = true;

        settings = {
          flavour = "mocha";

          # Needed to keep terminal transparency, if any
          transparent_background = true;
        };
      };
    };
  };

  home.shellAliases.v = "nvim";
}
