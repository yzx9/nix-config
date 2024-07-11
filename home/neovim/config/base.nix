{ pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    # Set 'vi' and 'vim' aliases to nixvim
    viAlias = true;
    vimAlias = true;

    luaLoader.enable = true;

    # Use <Space> as leader key
    globals.mapleader = " ";

    # Setup clipboard support
    clipboard = {
      # Use xsel as clipboard provider
      providers.xsel.enable = true;

      # Sync system clipboard
      register = if (pkgs.stdenv.isLinux) then "unnamedplus" else "unnamed";
    };
  };

  home.shellAliases.v = "nvim";
}
