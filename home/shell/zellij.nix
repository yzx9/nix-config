{ ... }:

{
  programs.zellij = {
    enable = true;
    settings = {
      default_shell = "nu";

      pane_frames = false;
      theme = "dracula";
    };
  };

  home.file.".config/zellij/layouts/default.kdl".text = ''
    layout {
      pane size=1 borderless=true {
        plugin location="zellij:tab-bar"
      }
      pane split_direction="vertical" {
        pane focus=true borderless=false
        pane size="30%" {
          pane size="40%"
          pane size="60%"
        }
      }
      pane size=2 borderless=true {
        plugin location="zellij:status-bar"          
      }
    }
  '';
}
