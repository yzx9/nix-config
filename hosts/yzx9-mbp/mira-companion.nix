{
  config,
  inputs,
  ...
}:

{
  imports = [ inputs.mira-panel.darwinModules.panelCompanion ];

  # The controller device key, agenix-managed (secrets/mira-companion.age).
  # The companion runs as the user's launchd agent, so the runtime file must
  # be owned by the user — agenix's root-only default would be unreadable to
  # it and presence would silently idle.
  age.secrets.mira-companion = {
    file = ../../secrets/mira-companion.age;
    owner = config.my.user.name;
    group = "staff";
    mode = "400";
  };

  # Notifier + screen-presence sensor for the Mira panel served by yzx9-ws
  # (10.6.141.235, static — see hosts/yzx9-ws/networking.nix).
  services.mira-panel-companion = {
    enable = true;
    panelUrl = "ws://10.6.141.235:15932/ws";

    # Auto-unlock while this Mac's screen is unlocked. Rotating the key
    # means re-encrypting the .age file and running a switch.
    enablePresence = true;
    controllerKeyFile = config.age.secrets.mira-companion.path;
  };
}
