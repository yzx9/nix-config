{
  config,
  vars,
  lib,
  ...
}:

let
  cfg = config.docker;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;

      rootless = lib.mkIf cfg.rootless {
        enable = true;
        setSocketVariable = true;
      };
    };

    # WARN: Beware that the docker group membership is effectively equivalent to being root!
    users.extraGroups.docker.members = lib.mkIf (!cfg.rootless) [ vars.user.name ];

    hardware.nvidia-container-toolkit.enable = config.nvidia.enable;
  };
}
