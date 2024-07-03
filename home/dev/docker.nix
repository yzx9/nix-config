{ pkgs, ... }:

{
  # docker was installed by brew
  home.packages = with pkgs; [
    dockerfile-language-server-nodejs
    docker-compose-language-service
  ];
}
