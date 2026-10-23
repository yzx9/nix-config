{
  config,
  inputs,
  ...
}:

{
  imports = [ inputs.mira-panel.homeManagerModules.panelCompanion ];

  # The controller device key, agenix-managed at the home level: decrypted
  # with the user's own key during activation, owned by the user by
  # construction. The path is pinned to a plain literal (the agenix default
  # embeds a `$(getconf DARWIN_USER_TEMP_DIR)` command substitution that
  # only resolves inside a shell — launchd EnvironmentVariables don't).
  age.secrets.mira-companion = {
    file = ../../secrets/mira-companion.age;
    path = "${config.home.homeDirectory}/.config/mira-panel/controller.key";
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
