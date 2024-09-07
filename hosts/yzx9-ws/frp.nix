{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    frp # Fast reverse proxy
  ];

  age.secrets.frpc_yzx9-ws.file = ./secrets/frpc_yzx9-ws.toml.age;

  systemd.services.frpc = {
    # this service is "wanted by" (see systemd man pages, or other tutorials) the system 
    # level that allows multiple users to login and interact with the machine non-graphically 
    # (see the Red Hat tutorial or Arch Linux Wiki for more information on what each target means) 
    # this is the "node" in the systemd dependency graph that will run the service
    wantedBy = [ "multi-user.target" ];

    # systemd service unit declarations involve specifying dependencies and order of execution
    # of systemd nodes; here we are saying that we want our service to start after the network has 
    # set up (as our IRC client needs to relay over the network)
    after = [ "network.target" ];

    description = "frp client";

    serviceConfig = {
      # see systemd man pages for more information on the various options for "Type": "notify"
      # specifies that this is a service that waits for notification from its predecessor (declared in
      # `after=`) before starting
      Type = "simple";

      # the command to execute when the service starts up
      ExecStart = ''${pkgs.frp}/bin/frpc -c ${config.age.secrets.frpc_yzx9-ws.path}'';
    };
  };
}
