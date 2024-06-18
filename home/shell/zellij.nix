{ ... }:

{
  programs.zellij = {
    enable = true;
    settings = {
      default_shell = "nu";
      on_force_close = "detach";

      simplified_ui = false; # no tips if set to true
      pane_frames = false;
      theme = "default";

      default_mode = "normal"; # normal, locked
      mouse_mode = true;
      scroll_buffer_size = 10000;
    };
  };

  home.file.".config/zellij/layouts/default".text = ''
    template:
      direction: Horizontal # 排布方向
      parts:
        # TabBar
        - direction: Vertical
          borderless: true
          split_size:
            Fixed: 1
          run:
            plugin:
              location: "zellij:tab-bar"

        # Main
        - direction: Vertical # part 2
          body: true

        # StatusBar
        - direction: Vertical # part 3
          borderless: true
          split_size:
            Fixed: 2
          run:
            plugin:
              location: "zellij:status-bar"

    tabs:
      - name: "Tab 1"
        direction: Horizontal
        parts:
          - direction: Vertical
            split_size:
              Percent: 60

          - direction: Vertical
            parts:
              - direction: Horizontal
              - direction: Horizontal
  '';
}
