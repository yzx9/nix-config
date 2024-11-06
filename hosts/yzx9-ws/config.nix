{ ... }:

{
  proxy.enable = true;
  nvidia.enable = true;
  docker = {
    enable = true;
    rootless = false;
  };
}
