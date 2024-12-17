{ self, vars, ... }:

{
  services.kanboard = {
    enable = true;
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
