{ config, pkgs, ... }:

{
  services.github-runners.nex = {
    enable = true;
    url = "https://github.com/yzx9/nex";
    name = "cvcd-gpu1-nex";
    count = 2;

    # Get a short-lived registration token from **nex → Settings → Actions →
    # Runners → New self-hosted runner**. **MUST** single line without any
    # trailing newline. You can use `echo -n` to avoid the trailing newline, e.g.:
    # `echo -n "ghr_1234567890abcdef" > /path/to/token-file`
    tokenFile = "${config.xdg.stateHome}/github-runners/nex-registration-token";
    tokenType = "registration";

    extraLabels = [ "nix" ];
    extraPackages = [ pkgs.nix ];
    extraEnvironment = {
      http_proxy = config.my.proxy.httpPublic;
      https_proxy = config.my.proxy.httpPublic;
      no_proxy = "localhost,127.0.0.1,::1";
      NIX_CONFIG = "experimental-features = nix-command flakes";
    };
  };
}
