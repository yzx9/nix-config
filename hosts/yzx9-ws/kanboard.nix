{ self, vars, ... }:

{
  imports = [ ../../packages/kanboard/option.nix ];

  services.kanboard = {
    enable = true;
    package = self.packages.${vars.system}.kanboard;

    domain = "kanboard";
    nginx = {
      listen = [
        {
          addr = "127.0.0.1";
          port = 4090;
        }
      ];
    };
  };
}
