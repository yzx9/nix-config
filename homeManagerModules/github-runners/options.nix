# The public options mirror NixOS services.github-runners, except for the
# system service identity. See nixos/modules/services/continuous-integration/
# github-runner/options.nix in Nixpkgs.
{ lib, pkgs }:

let
  inherit (lib) mkOption types;
  nullable =
    type: description:
    mkOption {
      type = types.nullOr type;
      default = null;
      inherit description;
    };
  count =
    default:
    mkOption {
      type = types.ints.positive;
      inherit default;
      description = "Number of replicas. Each replica has its own service and registration.";
    };
  labels = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = "Additional labels applied at registration.";
  };
  runtimePath = types.addCheck types.str (
    path:
    lib.hasPrefix "/" path
    && !lib.hasInfix "\n" path
    && !lib.hasInfix "\r" path
    && !(path == builtins.storeDir || lib.hasPrefix "${builtins.storeDir}/" path)
  );
in
mkOption {
  default = { };
  description = "Named GitHub Actions self-hosted runners.";
  type = types.attrsOf (
    types.submodule (
      { name, config, ... }: {
        options = {
          enable = lib.mkEnableOption "the GitHub Actions runner";
          url = nullable types.str "Repository or organization URL. Required unless using `orgs`.";
          name = mkOption {
            type = types.nullOr types.str;
            default = name;
            defaultText = lib.literalExpression "<attribute name>";
            description = "GitHub registration name. Null uses the hostname for a single runner.";
          };
          count = count 1;
          orgs = mkOption {
            default = { };
            description = "Organizations or repositories served by this entry. Each expands to `<entry>-<org>-<n>`.";
            type = types.attrsOf (
              types.submodule (
                { name, ... }: {
                  options = {
                    url = mkOption {
                      type = types.str;
                      default = "https://github.com/${name}";
                      defaultText = lib.literalExpression ''"https://github.com/''${name}"'';
                      description = "GitHub URL for this organization or repository.";
                    };
                    login = mkOption {
                      type = types.str;
                      default = name;
                      defaultText = lib.literalExpression "<attribute name>";
                      description = "Account the GitHub App is installed on. Unused when using `tokenFile`.";
                    };
                    count = (count config.count) // {
                      defaultText = lib.literalMD "the entry-level `count`";
                    };
                    extraLabels = labels;
                  };
                }
              )
            );
          };
          extraLabels = labels;
          runnerGroup = nullable types.str "GitHub runner group; null uses GitHub's default.";
          noDefaultLabels = lib.mkEnableOption "registration without GitHub's default labels";
          replace = lib.mkEnableOption "replacing a remote runner with the same registration name";
          tokenFile = nullable runtimePath ''
            Absolute runtime path to a file containing a PAT or a short-lived registration
            token. Exactly one of `tokenFile` or `githubApp` must be set.
            The file must be outside the Nix store.
          '';
          tokenType = mkOption {
            type = types.enum [
              "auto"
              "access"
              "registration"
            ];
            default = "auto";
            description = ''
              Type of token stored in `tokenFile`. `auto` detects access token
              prefixes. For persistent runners, explicit `registration` only
              reads the file until an identity has been registered.
            '';
          };
          githubApp = nullable (types.submodule {
            options = {
              id = mkOption {
                type = types.ints.positive;
                description = "Numeric GitHub App ID.";
              };
              login = nullable types.str "Account the GitHub App is installed on. Required unless using `orgs`.";
              privateKeyFile = mkOption {
                type = runtimePath;
                description = "Absolute runtime path to the GitHub App PEM private key, outside the Nix store.";
              };
            };
          }) "GitHub App installation authentication. Mutually exclusive with `tokenFile`.";
          ephemeral = lib.mkEnableOption "one-job runners that register anew after each job";
          package = lib.mkPackageOption pkgs "github-runner" { } // {
            apply =
              pkg:
              if lib.isFunction (pkg.override or null) then
                pkg.override { inherit (config) nodeRuntimes; }
              else
                pkg;
          };
          nodeRuntimes = mkOption {
            type = types.nonEmptyListOf (types.enum [ "node24" ]);
            default = [ "node24" ];
            description = "Node.js runtimes supported by the packaged runner.";
          };
          extraPackages = mkOption {
            type = types.listOf types.package;
            default = [ ];
            description = "Additional packages on the runner and job PATH.";
          };
          extraEnvironment = mkOption {
            type = types.attrsOf types.str;
            default = { };
            description = "Non-secret environment variables for registration and jobs. Values enter the Nix store.";
          };
          workDir = nullable runtimePath ''
            Absolute workspace path. Null uses a private workspace per instance; explicit
            paths must not be shared. Unlike NixOS, persistent workspaces are not wiped.
          '';
          serviceOverrides = mkOption {
            type = types.attrs;
            default = { };
            description = "Additional or overriding systemd user service settings in the [Service] section.";
          };
        };
      }
    )
  );
}
