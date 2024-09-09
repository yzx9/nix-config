{ config, ... }:

{
  # Configure network proxy if necessary
  networking.proxy.default = "http://127.0.0.1:12345/";
  networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  age.secrets."xray_yzx9-ws.json" = {
    file = ../../secrets/xray_yzx9-ws.json.age;
    owner = "xray";
  };

  services.xray = {
    enable = true;
    settingsFile = config.age.secrets."xray_yzx9-ws.json".path;
  };
}
