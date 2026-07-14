{ config, ... }:

let
  ssh = "${config.home.homeDirectory}/.ssh/";
in
{
  # ssh
  age.secrets.id-auth = {
    file = ../../secrets/id-auth.age;
    path = "${ssh}id_auth";
    mode = "400";
  };

  home.file.".ssh/id_auth.pub".source = ../../secrets/id-auth.pub;
}
