{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.frpc;
in
{
  options.services.frpc = {
    enable = lib.mkEnableOption "frpc";

    package = lib.mkPackageOption pkgs "frp" { };

    configFile = lib.mkOption {
      type = lib.types.str;
      description = "frpc config";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.frpc = {
      # this service is "wanted by" (see systemd man pages, or other tutorials) the system
      # level that allows multiple users to login and interact with the machine non-graphically
      # (see the Red Hat tutorial or Arch Linux Wiki for more information on what each target means)
      # this is the "node" in the systemd dependency graph that will run the service
      wantedBy = [ "multi-user.target" ];

      wants = [ "network-online.target" ];

      # systemd service unit declarations involve specifying dependencies and order of execution
      # of systemd nodes; here we are saying that we want our service to start after the network has
      # set up (as our IRC client needs to relay over the network)
      after = [ "network-online.target" ];

      description = "frp client";

      serviceConfig = {
        # see systemd man pages for more information on the various options for "Type": "notify"
        # specifies that this is a service that waits for notification from its predecessor (declared in
        # `after=`) before starting
        Type = "simple";

        # the command to execute when the service starts up
        ExecStart = ''${lib.getExe' cfg.package "frpc"} -c ${cfg.configFile}'';
      };
    };
  };
}
