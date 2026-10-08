{ pkgs, ... }:

{
  users.users.yzx9.extraGroups = [
    "video"
    "render"
  ];

  environment.systemPackages = with pkgs; [
    libdrm
    drm_info
  ];
}
