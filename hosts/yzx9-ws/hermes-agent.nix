{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  nixpkgs = {
    overlays = [ inputs.hermes-agent.overlays.default ];
    config.permittedInsecurePackages = [ "olm-3.2.16" ];
  };

  age.secrets.hermes-env.file = ../../secrets/hermes-env.age;

  services.hermes-agent = {
    enable = true;
    package = pkgs.hermes-agent.override {
      dependency-groups = [
        "all"
        "matrix"
      ];
    };

    environmentFiles = [ config.age.secrets.hermes-env.path ];
    addToSystemPackages = true;

    settings = {
      model = {
        provider = "zai";
        default = "GLM-5-turbo";
        base_url = "https://open.bigmodel.cn/api/coding/paas/v4";
      };

      toolsets = [ "all" ];
      max_turns = 100;

      terminal = {
        backend = "local";
        cwd = ".";
        timeout = 180;
      };

      compression = {
        enabled = true;
        threshold = 0.85;
        summary_model = "GLM-5-turbo";
      };

      display = {
        compact = false;
        personality = "kawaii";
      };

      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };

      agent = {
        max_turns = 60;
        verbose = false;
      };

      matrix = {
        require_mention = false;
        auto_thread = true;
      };
    };
  };
}
