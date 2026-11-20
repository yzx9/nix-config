# GitHub Actions self-hosted runners

This Linux module mirrors the named `services.github-runners.<key>` options in
NixOS. It runs the Nixpkgs listener in the current user's systemd manager and
uses the same replica naming rules:

```nix
services.github-runners.build = {
  enable = true;
  url = "https://github.com/example/project";
  name = "builder";
  count = 2;
  tokenFile = "/home/example/.local/state/runner-registration-token";
  tokenType = "registration";
  extraLabels = [ "build" ];
};
```

This creates `github-runner-build-1.service` and `github-runner-build-2.service`
with GitHub names `builder-1` and `builder-2`. A single replica uses the bare
entry key for its unit and does not append a number to `name` (defaults to the
key). `orgs` entries expand to `<key>-<org>-<n>` for both names, with each org's
own URL, count and extra labels. Changing between one replica and multiple
replicas changes the instance keys; unregister the old instances first.

## Registration

Set exactly one of `tokenFile` or `githubApp`, as on NixOS. Give credential
files absolute runtime paths, not Nix path literals or store files.

- **Short-lived `tokenFile`:** For a persistent runner, explicitly set
  `tokenType = "registration"`. Put a fresh registration token in the file
  before first start. After **all** replicas are registered, remove the file;
  subsequent starts use the existing local identities and do not read it.
  Creating another token file or changing registration options does not
  update an existing identity. To start over, stop the service, remove the
  registration on GitHub, and move the old local identity files out of the
  runner state directory before providing a fresh token.
- **`tokenFile` with `access` or `auto`:** The file must remain readable at
  each startup. The service registers on first start or when inputs change
  and stores a digest rather than another copy of the token. If re-registering
  with the same GitHub name, unregister the old instance or explicitly opt
  into `replace`.
- **`githubApp`:** Set `id`, `login` (unless supplied by `orgs`), and
  `privateKeyFile`, an absolute runtime path. The service registers using a
  fresh installation/registration token on each start and attempts to remove
  matching offline entries before registration and on stop. Use names unique
  to this deployment. `githubApp` and `tokenFile` are mutually exclusive.
- **`ephemeral`:** Requires managed authentication. The listener registers
  anew after each job; use a PAT or GitHub App so it can obtain fresh tokens.
  Without an explicit `workDir`, systemd manages the temporary workspace.

## Differences from NixOS

- There are no `user`/`group` options or system privileges. The module does
  not enable lingering. `[Service]` settings in `serviceOverrides` apply to
  the user unit, not to a root-managed service.
- Credentials, logs and job homes are private per instance under
  `$XDG_STATE_HOME/github-runners/<instance>`. Persistent workspaces are not
  wiped on start or unregister. Explicit `workDir` paths must be absolute,
  distinct, non-overlapping, and free of symlinks; use the defaults with
  replicas, or assign each explicit workspace to a separate named entry.
- `extraEnvironment` is for non-secret variables (such as proxy settings);
  values are stored in Nix-generated files. Files accessible to the account
  running the service are also accessible to its workflow jobs, including
  any PAT or App key configured on that account. Separate homes and
  workspaces avoid collisions; they do not isolate jobs. Only run trusted
  workflows here.

Keep the Nix package current: the module disables automatic runner updates
at registration. Read the journal with `journalctl --user -u <unit>`.
