{ ... }:

{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "autumn_night_transparent";
      editor.cursor-shape = {
        normal = "block";
        insert = "bar";
        select = "underline";
      };
    };
    themes = {
      autumn_night_transparent = {
        "inherits" = "autumn_night";
        "ui.background" = { };
      };
    };
  };

  programs.nushell.shellAliases = {
    vi = "hx";
    vim = "hx";
    nano = "hx";
  };
}
