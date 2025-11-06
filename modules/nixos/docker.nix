{ config, lib, ... }:

let
  inherit (config) vars;
  cfg = config.docker;

  proxySettings = lib.mkIf config.proxy.selfHost.enable {
    "http-proxy" = "127.0.0.1:${builtins.toString config.proxy.selfHost.httpProxyPort}";
    "no-proxy" = "127.0.0.0/8";
  };
in
lib.mkIf cfg.enable {
  virtualisation.docker = {
    enable = true;

    daemon.settings = proxySettings;

    rootless = {
      enable = cfg.rootless;
      setSocketVariable = true;
      daemon.settings = proxySettings;
    };
  };

  # WARN: Beware that the docker group membership is effectively equivalent to being root!
  users.extraGroups.docker.members = lib.mkIf (!cfg.rootless) [ vars.user.name ];

  # use `docker run` with `--device nvidia.com/gpu=all`` and not `--gpus all`
  hardware.nvidia-container-toolkit.enable = config.nvidia.enable;
}
