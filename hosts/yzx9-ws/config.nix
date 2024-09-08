{ ... }:

{
  nvidia.enable = true;
  docker = {
    enable = true;
    rootless = false;
  };
}
