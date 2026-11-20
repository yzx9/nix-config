{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.github-runners;
  stateBase = "${config.xdg.stateHome}/github-runners";
  credentials = [
    ".runner"
    ".credentials"
    ".credentials_rsaparams"
  ];
  assignments = lib.mapAttrsToList (name: value: "${name}=${value}");
  escapeSpecifiers = lib.replaceStrings [ "%" ] [ "%%" ];
  command = lib.hm.strings.escapeSystemdExecArgs;
  enabled = lib.filterAttrs (_: runner: runner.enable) cfg;
  suffix = i: "-${toString i}";
  # Mirror NixOS's expansion. Use a list so duplicate keys cannot disappear
  # silently when turned into a set of systemd units.
  instances = lib.concatLists (
    lib.mapAttrsToList (
      key: runner:
      if runner.orgs == { } then
        if runner.count == 1 then
          [ (runner // { inherit key; }) ]
        else
          map (
            i:
            runner
            // {
              key = key + suffix i;
              name = if runner.name == null then null else runner.name + suffix i;
            }
          ) (lib.range 1 runner.count)
      else
        lib.concatLists (
          lib.mapAttrsToList (
            orgKey: org:
            map (
              i:
              let
                name = "${key}-${orgKey}${suffix i}";
              in
              runner
              // {
                key = name;
                inherit name;
                inherit (org) url;
                extraLabels = runner.extraLabels ++ org.extraLabels;
                githubApp = if runner.githubApp == null then null else runner.githubApp // { inherit (org) login; };
              }
            ) (lib.range 1 org.count)
          ) runner.orgs
        )
    ) enabled
  );

  layout =
    runner:
    let
      root = "${stateBase}/${runner.key}";
      home = "${root}/home";
      runtime =
        if runner.ephemeral && runner.workDir == null then "github-runners/${runner.key}" else null;
    in
    {
      inherit root runtime;
      work = if runner.workDir == null then "${root}/_work" else runner.workDir;
      listener = lib.getExe' runner.package "Runner.Listener";
      environment = {
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      }
      // runner.extraEnvironment
      // {
        RUNNER_ROOT = root;
        HOME = home;
        PATH = lib.makeBinPath (
          lib.unique (
            runner.extraPackages
            ++ (with pkgs; [
              bashInteractive
              coreutils
              git
              gnutar
              gzip
            ])
            ++ [ (if config.nix.package == null then pkgs.nix else config.nix.package) ]
          )
        );
        XDG_CACHE_HOME = "${home}/.cache";
        XDG_CONFIG_HOME = "${home}/.config";
        XDG_DATA_HOME = "${home}/.local/share";
        XDG_STATE_HOME = "${home}/.local/state";
      };
    };

  configureArgs =
    runner:
    [
      "configure"
      "--unattended"
      "--disableupdate"
      "--url"
      runner.url
    ]
    ++ lib.optionals (runner.name != null) [
      "--name"
      runner.name
    ]
    ++ lib.optionals (runner.extraLabels != [ ]) [
      "--labels"
      (lib.concatStringsSep "," runner.extraLabels)
    ]
    ++ lib.optionals (runner.runnerGroup != null) [
      "--runnergroup"
      runner.runnerGroup
    ]
    ++ lib.optional runner.noDefaultLabels "--no-default-labels"
    ++ lib.optional runner.replace "--replace"
    ++ lib.optional runner.ephemeral "--ephemeral";

  shellConfig =
    runner:
    let
      instance = layout runner;
    in
    ''
      # shellcheck disable=SC2016
      export ${lib.escapeShellArgs (assignments instance.environment)}
      listener=${lib.escapeShellArg instance.listener}
      work=${lib.escapeShellArg instance.work}
      explicit_work=${if runner.workDir == null then "0" else "1"}
      # A comma-delimited --labels value is a single argument.
      # shellcheck disable=SC2016,SC2054
      configure_args=(${lib.escapeShellArgs (configureArgs runner)})
    '';

  # Registration runs in a service hook; the main process is always Listener.
  registrationHook =
    runner:
    lib.getExe (
      pkgs.writeShellApplication {
        name = "github-runner-${runner.key}-registration";
        inheritPath = false;
        text = ''
          ${shellConfig runner}
          credentials=(${lib.escapeShellArgs credentials})
          token_file=${lib.escapeShellArg (if runner.tokenFile == null then "" else runner.tokenFile)}
          token_type=${lib.escapeShellArg runner.tokenType}
          store_dir=${lib.escapeShellArg builtins.storeDir}
          ephemeral=${if runner.ephemeral then "1" else "0"}
          ${lib.optionalString ((layout runner).runtime != null) ''
            work="$RUNTIME_DIRECTORY/_work"
          ''}
          ${builtins.readFile ./common.sh}
          ${lib.optionalString (runner.githubApp != null) ''
            app_id=${toString runner.githubApp.id}
            app_login=${lib.escapeShellArg runner.githubApp.login}
            key_file=${lib.escapeShellArg runner.githubApp.privateKeyFile}
            repo_url=${lib.escapeShellArg runner.url}
            runner_name=${lib.escapeShellArg (if runner.name == null then "" else runner.name)}
            dependencies=${
              lib.escapeShellArg (
                lib.makeBinPath [
                  pkgs.curl
                  pkgs.jq
                  pkgs.openssl
                ]
              )
            }
            ${builtins.readFile ./github-app.sh}
          ''}
          ${builtins.readFile ./managed.sh}
        '';
      }
    );

  instanceUnit =
    runner:
    let
      instance = layout runner;
      helper = registrationHook runner;
    in
    lib.nameValuePair "github-runner-${runner.key}" {
      Unit.Description = "GitHub Actions runner (${runner.key})";
      Install.WantedBy = [ "default.target" ];
      Service = {
        Environment = map (value: builtins.toJSON (escapeSpecifiers value)) (
          assignments instance.environment
        );
        ExecStart = command [
          instance.listener
          "run"
          "--startuptype"
          "service"
        ];
        KillSignal = "SIGINT";
        Restart = if runner.ephemeral then "on-success" else "no";
        RestartForceExitStatus = [ 2 ];
        RestartSec = "10s";
        UMask = "0077";
        ExecStartPre = command [
          helper
          "configure"
        ];
      }
      // lib.optionalAttrs (instance.runtime != null) {
        RuntimeDirectory = instance.runtime;
        RuntimeDirectoryMode = "0700";
      }
      // lib.optionalAttrs (runner.githubApp != null) {
        ExecStopPost = "-${
          command [
            helper
            "remove"
          ]
        }";
      }
      // runner.serviceOverrides;
    };

  validKey = key: builtins.match "[A-Za-z0-9][A-Za-z0-9_-]*" key != null;
  validUrl =
    url:
    url != null
    &&
      builtins.match "https://[A-Za-z0-9.-]+(:[0-9]+)?/[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)?/?" url != null;
  disjoint = a: b: a != b && !lib.hasPrefix "${a}/" b && !lib.hasPrefix "${b}/" a;
  explicitWork = map (runner: runner.workDir) (lib.filter (runner: runner.workDir != null) instances);
  unique = values: lib.length (lib.unique values) == lib.length values;
  reserved = [
    "HOME"
    "PATH"
    "RUNNER_ROOT"
    "XDG_CACHE_HOME"
    "XDG_CONFIG_HOME"
    "XDG_DATA_HOME"
    "XDG_STATE_HOME"
  ];
  validEnvironment =
    name:
    builtins.match "[A-Za-z_][A-Za-z0-9_]*" name != null
    && !(lib.elem name reserved)
    && !(lib.hasPrefix "ACTIONS_RUNNER_INPUT_" (lib.toUpper name));
  entryAssertions = lib.concatLists (
    lib.mapAttrsToList (key: runner: [
      {
        assertion = validKey key && lib.all validKey (builtins.attrNames runner.orgs);
        message = "services.github-runners.${key}: entry and org keys must be safe service and path names.";
      }
      {
        assertion = runner.orgs != { } || runner.count == 1 || runner.name != null;
        message = "services.github-runners.${key}: name cannot be null when count > 1 without orgs.";
      }
      {
        assertion = (runner.tokenFile == null) != (runner.githubApp == null);
        message = "services.github-runners.${key}: set exactly one of tokenFile or githubApp.";
      }
      {
        assertion = lib.all validEnvironment (builtins.attrNames runner.extraEnvironment);
        message = "services.github-runners.${key}: extraEnvironment must not override reserved paths or registration inputs.";
      }
      {
        assertion =
          !lib.any (field: builtins.hasAttr field runner.serviceOverrides) [
            "User"
            "Group"
            "DynamicUser"
          ];
        message = "services.github-runners.${key}: systemd user services run as the Home Manager user.";
      }
    ]) enabled
  );
  instanceAssertions = lib.concatMap (runner: [
    {
      assertion = validUrl runner.url;
      message = "services.github-runners.${runner.key}: supply an HTTPS repository, organization, or enterprise URL without credentials.";
    }
    {
      assertion =
        (!runner.noDefaultLabels || runner.extraLabels != [ ])
        && lib.all (label: builtins.match "[^,[:space:]]+" label != null) runner.extraLabels;
      message = "services.github-runners.${runner.key}: labels must be nonempty and contain no commas or whitespace; noDefaultLabels requires extraLabels.";
    }
    {
      assertion =
        runner.githubApp == null
        || (
          runner.githubApp.login != null && builtins.match "[A-Za-z0-9_.-]+" runner.githubApp.login != null
        );
      message = "services.github-runners.${runner.key}: provide a valid GitHub App installation login.";
    }
  ]) instances;
in
{
  options.services.github-runners = import ./options.nix { inherit lib pkgs; };

  config = lib.mkIf (enabled != { }) {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.github-runners" pkgs lib.platforms.linux)
      {
        assertion = unique (map (runner: runner.key) instances);
        message = "services.github-runners: expanded service names must be unique.";
      }
      {
        assertion = unique (
          map (runner: [
            (if runner.url == null then null else lib.toLower (lib.removeSuffix "/" runner.url))
            (if runner.name == null then null else lib.toLower runner.name)
          ]) instances
        );
        message = "services.github-runners: registration names must be unique within each URL.";
      }
      {
        assertion = builtins.match "/[^\r\n]*" config.xdg.stateHome != null;
        message = "services.github-runners needs an absolute xdg.stateHome path without line breaks.";
      }
      {
        assertion =
          unique explicitWork
          && lib.all (
            path:
            disjoint path stateBase
            && lib.all (other: path == other || disjoint path other) explicitWork
            && lib.all (part: part != ".." && part != "." && part != "") (
              lib.splitString "/" (lib.removePrefix "/" path)
            )
          ) explicitWork;
        message = "services.github-runners: explicit workDir paths must be distinct, canonical, and must not overlap runner state or one another.";
      }
    ]
    ++ entryAssertions
    ++ instanceAssertions;
    systemd.user.services = lib.listToAttrs (map instanceUnit instances);
  };
}
