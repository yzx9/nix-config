{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  hasProxy = !(builtins.isNull config.proxy.httpProxy);
  gemini-cli = inputs.self.packages.${config.vars.system}.gemini-cli;

  gemini-cli-proxied = pkgs.writeShellApplication {
    name = "gemini";

    runtimeInputs = [ gemini-cli ];

    text = ''
      export HTTPS_PROXY=${config.proxy.httpProxy}
      exec gemini "$@"
    '';
  };
in
lib.mkIf config.purpose.daily {
  home.packages = [
    (if hasProxy then gemini-cli-proxied else gemini-cli)
  ];
}
