{ pkgs, homeManagerConfiguration }:

let
  inherit (pkgs) lib;
  fixtureHome = "/home/runner-example";
  stateHome = "${fixtureHome}/.local/state";
  listener = pkgs.writeShellApplication {
    name = "Runner.Listener";
    text = builtins.readFile ./listener.sh;
  };
  curl = pkgs.writeShellApplication {
    name = "curl";
    text = builtins.readFile ./curl.sh;
  };
  configuration =
    settings:
    homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../../homeManagerModules/github-runners
        {
          home.username = "runner-example";
          home.homeDirectory = fixtureHome;
          home.stateVersion = "26.05";
          xdg.stateHome = stateHome;
          services.github-runners = settings;
        }
      ];
    };
  runner = {
    enable = true;
    url = "https://github.com/example/project";
    package = listener;
    tokenFile = "${fixtureHome}/registration-token";
    tokenType = "registration";
    extraEnvironment = {
      https_proxy = "http://proxy.example.org:8080";
      TEST_VALUE = ''use $HOME "/x%y"'';
    };
  };
  file = runner // {
    tokenFile = "${fixtureHome}/access-token";
    tokenType = "auto";
  };
  settings = {
    solo = runner // {
      workDir = "${fixtureHome}/workspace";
      serviceOverrides.TimeoutStopSec = "20s";
    };
    group = runner // {
      name = "build-worker";
      count = 2;
      extraLabels = [ "build" ];
      runnerGroup = "pool";
      noDefaultLabels = true;
    };
    org = runner // {
      count = 2;
      extraLabels = [ "base" ];
      orgs = {
        alpha.extraLabels = [ "org-a" ];
        beta = {
          url = "https://github.com/example/another";
          count = 1;
        };
      };
    };
    inherit file;
    disposable = runner // {
      ephemeral = true;
    };
    app = runner // {
      tokenFile = null;
      githubApp = {
        id = 7;
        login = "example";
        privateKeyFile = "${fixtureHome}/app-key";
      };
    };
    off = { };
  };
  disabled = (configuration { off = { }; }).config;
  active = configuration settings;
  services = active.config.systemd.user.services;
  invalid = settings: !(builtins.tryEval (configuration settings).activationPackage.drvPath).success;
  optionKeys = option: builtins.attrNames (option.type.getSubOptions [ ]);
  nixos = lib.evalModules {
    specialArgs = { inherit pkgs; };
    modules = [
      (pkgs.path + "/nixos/modules/services/continuous-integration/github-runner/options.nix")
    ];
  };
  hook =
    key: field: action:
    let
      value = lib.head (lib.toList services."github-runner-${key}".Service.${field});
    in
    builtins.head (builtins.match ''-?"([^"]+)" "${action}"'' value);
  setup = key: hook key "ExecStartPre" "configure";
in
assert
  optionKeys active.options.services.github-runners
  == lib.subtractLists [ "user" "group" ] (optionKeys nixos.options.services.github-runners);
assert disabled.systemd.user.services == { };
assert !lib.any (p: lib.getName p == "github-runner-ctl") active.config.home.packages;
assert
  builtins.attrNames services == map (key: "github-runner-${key}") [
    "app"
    "disposable"
    "file"
    "group-1"
    "group-2"
    "org-alpha-1"
    "org-alpha-2"
    "org-beta-1"
    "solo"
  ];
assert active.config.services.github-runners.solo.name == "solo";
assert active.config.services.github-runners.solo.count == 1;
assert active.config.services.github-runners.solo.nodeRuntimes == [ "node24" ];
assert invalid {
  pool = runner // {
    count = 2;
  };
  pool-1 = runner;
};
assert invalid {
  x = runner // {
    name = "shared";
  };
  y = runner // {
    name = "shared";
  };
};
assert invalid {
  x = runner // {
    count = 2;
    workDir = "${fixtureHome}/shared";
  };
};
assert invalid {
  x = runner // {
    tokenFile = null;
  };
};
assert invalid {
  x = file // {
    inherit (settings.app) githubApp;
  };
};
assert invalid {
  x = runner // {
    serviceOverrides.User = "root";
  };
};
pkgs.runCommand "home-manager-github-runners-test" { nativeBuildInputs = [ pkgs.openssl ]; } ''
  generation=${active.activationPackage}
  units="$generation/home-files/.config/systemd/user"
  for key in app disposable file solo group-1 group-2 org-alpha-1 org-alpha-2 org-beta-1; do
    unit="$units/github-runner-$key.service"
    root="${stateHome}/github-runners/$key"
    grep -Fx 'WantedBy=default.target' "$unit"
    grep -Fx 'ExecStart="${lib.getExe' listener "Runner.Listener"}" "run" "--startuptype" "service"' "$unit"
    grep -Fx 'RestartForceExitStatus=2' "$unit"
    grep -q '^ExecStartPre=' "$unit"
    grep -Fx "Environment=\"RUNNER_ROOT=$root\"" "$unit"
    grep -Fx "Environment=\"HOME=$root/home\"" "$unit"
    grep -Fx 'Environment="https_proxy=http://proxy.example.org:8080"' "$unit"
    grep -Fx 'Environment="TEST_VALUE=use $HOME \"/x%%y\""' "$unit"
    ! grep -E '^ConditionFileNotEmpty=|^ExecCondition=' "$unit" || exit 1
  done
  grep -Fx 'TimeoutStopSec=20s' "$units/github-runner-solo.service"
  grep -Fx 'Restart=on-success' "$units/github-runner-disposable.service"
  grep -Fx 'RuntimeDirectory=github-runners/disposable' "$units/github-runner-disposable.service"
  grep -q '^ExecStopPost=-' "$units/github-runner-app.service"
  ! grep -rE 'test-token|ghp_fixture|app-registration|app-installation' "$units" ${setup "group-1"} ${setup "file"} ${setup "app"} || exit 1

  # Run the actual generated one-shot scripts with a writable fixture home.
  base="$TMPDIR/runner-home"
  mkdir -p "$base"
  scriptsInFixture() {
    substitute "$1" "$2" --replace-fail ${fixtureHome} "$base"
    chmod +x "$2"
  }
  roots="$base/.local/state/github-runners"
  scriptsInFixture ${setup "group-1"} "$TMPDIR/group-1"
  scriptsInFixture ${setup "group-2"} "$TMPDIR/group-2"
  for i in 1 2; do
    ! "$TMPDIR/group-$i" configure || exit 1
    test ! -e "$roots/group-$i/.runner"
  done
  printf 'test-token\n' > "$base/registration-token"
  AcTions_Runner_INPUT_ePHeMeRaL=true "$TMPDIR/group-1" configure
  "$TMPDIR/group-2" configure
  rm "$base/registration-token"
  for i in 1 2; do
    root="$roots/group-$i"
    touch "$root/home/keep" "$root/_work/keep"
    "$TMPDIR/group-$i" configure
    test "$(stat -c %a "$root")" = 700
    test -f "$root/home/keep"
    test -f "$root/_work/keep"
    test -s "$root/.runner"
    test ! -e "$root/.registration-digest"
    test ! -e "$root/_work/.runner"
    test "$(<"$root/calls")" = configure
    grep -Fx "build-worker-$i" "$root/configure-args"
    grep -Fx -- '--no-default-labels' "$root/configure-args"
    grep -Fx -- '--runnergroup' "$root/configure-args"
    grep -Fx 'pool' "$root/configure-args"
  done

  printf 'test-token\n' > "$base/registration-token"
  scriptsInFixture ${setup "org-alpha-1"} "$TMPDIR/org-alpha-1"
  "$TMPDIR/org-alpha-1" configure
  grep -Fx 'https://github.com/alpha' "$roots/org-alpha-1/configure-args"
  grep -Fx 'org-alpha-1' "$roots/org-alpha-1/configure-args"
  grep -Fx 'base,org-a' "$roots/org-alpha-1/configure-args"
  scriptsInFixture ${setup "solo"} "$TMPDIR/solo"
  "$TMPDIR/solo" configure
  grep -Fx "$base/workspace" "$roots/solo/configure-args"

  scriptsInFixture ${setup "file"} "$TMPDIR/file"
  printf 'ghp_fixture\n' > "$base/access-token"
  "$TMPDIR/file" configure
  touch "$roots/file/_work/keep"
  "$TMPDIR/file" configure
  test "$(grep -c '^configure$' "$roots/file/calls")" = 1
  printf 'ghp_invalid\n' > "$base/access-token"
  ! "$TMPDIR/file" configure || exit 1
  test "$(<"$roots/file/.runner")" = fixture
  printf 'github_pat_rotated\n' > "$base/access-token"
  "$TMPDIR/file" configure
  test "$(grep -c '^configure$' "$roots/file/calls")" = 2
  test -f "$roots/file/_work/keep"

  scriptsInFixture ${setup "disposable"} "$TMPDIR/disposable"
  export RUNTIME_DIRECTORY="$TMPDIR/runtime"
  printf 'test-token\n' > "$base/registration-token"
  "$TMPDIR/disposable" configure
  "$TMPDIR/disposable" configure
  grep -Fx -- '--ephemeral' "$roots/disposable/configure-args"
  grep -Fx "$RUNTIME_DIRECTORY/_work" "$roots/disposable/configure-args"
  test "$(grep -c '^configure$' "$roots/disposable/calls")" = 2

  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$base/app-key" 2>/dev/null
  substitute ${setup "app"} "$TMPDIR/app" \
    --replace-fail ${fixtureHome} "$base" \
    --replace-fail '${
      lib.makeBinPath [
        pkgs.curl
        pkgs.jq
        pkgs.openssl
      ]
    }' '${
      lib.makeBinPath [
        curl
        pkgs.jq
        pkgs.openssl
      ]
    }'
  chmod +x "$TMPDIR/app"
  "$TMPDIR/app" configure
  "$TMPDIR/app" configure
  "$TMPDIR/app" remove
  test "$(grep -c '^configure$' "$roots/app/calls")" = 2
  test "$(grep -c '^delete$' "$roots/app/api-calls")" = 3
  ! grep -rE 'test-token|ghp_fixture|github_pat_rotated|app-registration|app-installation' "$roots" || exit 1
  touch "$out"
''
