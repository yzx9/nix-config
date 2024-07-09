{ inputs, ... }:

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim

    ./plugins
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    viAlias = true;
    vimAlias = true;

    luaLoader.enable = true;
  };

  home.shellAliases.v = "nvim";
}
