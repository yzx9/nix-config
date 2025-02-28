{ config, lib, ... }:

let
  inherit (config) vars;
  cfg = config.docker;
in
lib.mkIf cfg.enable {
  virtualisation.docker = {
    enable = true;

    rootless = lib.mkIf cfg.rootless {
      enable = true;
      setSocketVariable = true;
    };
  };

  # WARN: Beware that the docker group membership is effectively equivalent to being root!
  users.extraGroups.docker.members = lib.mkIf (!cfg.rootless) [ vars.user.name ];

  # use `docker run` with `--device nvidia.com/gpu=all`` and not `--gpus all`
  hardware.nvidia-container-toolkit.enable = config.nvidia.enable;
}
