# just is a command runner, Justfile is very similar to Makefile, but simpler.
set default-list := true

############################################################################
#
#  Nix commands (suitable for all machines)
#
############################################################################

# Check whether the flake evaluates and run its tests
[group('flake')]
check:
  nix flake check --all-systems

# Force every host entry (nixos/darwin/home/images) to fully evaluate
# (--json: the plain printer would render broken entries as «error» strings
# and still exit 0)
[group('flake')]
test:
  nix eval --json .#evalTests --show-trace

# Update all the flake inputs
[group('flake')]
up:
  nix flake update --commit-lock-file

# Update specific input, usage: just upp nixpkgs
[group('flake')]
upp input:
  nix flake update {{input}} --commit-lock-file

# List all generations of the system profile
[group('flake')]
history:
  nix profile history --profile /nix/var/nix/profiles/system

# Open a nix shell with the flake
[group('flake')]
repl:
  nix repl -f flake:nixpkgs

# Remove all generations older than 7 days
[group('nix')]
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d

# Garbage collect all unused nix store entries
[group('nix')]
gc:
  sudo nix store gc --debug
  sudo nix-collect-garbage --delete-old

# Remove all reflog entries and prune unreachable objects
[group('nix')]
gitgc:
  git reflog expire --expire-unreachable=now --all
  git gc --prune=now

# Remote deployments
[group('os')]
deploy hostname:
  nix run nixpkgs#nixos-rebuild -- \
    switch \
      --no-reexec \
      --target-host {{hostname}} \
      --flake .#{{hostname}} \
      --elevate=sudo

############################################################################
#
#  Linux related commands
#
############################################################################

# Boot the system with the latest configuration (requires sudo)
[linux]
[group('os')]
boot:
  sudo nixos-rebuild boot --flake .

# Switch the system to the latest configuration (requires sudo)
[linux]
[group('os')]
switch:
  sudo nixos-rebuild switch --flake .

# Switch the system to the latest configuration (requires sudo) with verbose output and show trace on error
[linux]
[group('os')]
switch-dev:
  sudo nixos-rebuild switch --show-trace --verbose --flake .

# Rollback to the previous configuration (requires sudo)
[linux]
[group('os')]
rollback:
  sudo nixos-rebuild switch --rollback

# Switch the system to the latest configuration (requires sudo) with verbose output and show trace on error
[linux]
[group('os')]
hm-switch hostname = `hostname`:
  home-manager switch --flake .#{{hostname}}


############################################################################
#
#  Darwin related commands
#
############################################################################

# Boot the system with the latest configuration (requires sudo)
[macos]
[group('os')]
switch-noproxy:
  sudo darwin-rebuild switch --flake .

# Switch the system to the latest configuration (requires sudo)
[macos]
[group('os')]
switch: switch-noproxy (proxy "set")

# Switch the system to the latest configuration (requires sudo) with verbose output and show trace on error
[macos]
[group('os')]
switch-dev:
  sudo darwin-rebuild switch --show-trace --verbose --flake .

# Rollback to the previous configuration (requires sudo)
[macos]
[group('os')]
rollback: rollback-noproxy (proxy "set")

# Rollback to the previous configuration (requires sudo)
[macos]
[group('os')]
rollback-noproxy:
  sudo darwin-rebuild switch --rollback

# Switch the system to the latest configuration (requires sudo) with verbose output and show trace on error
[macos]
[group('os')]
proxy mode="auto_switch":
  sudo nix run nixpkgs#python3 scripts/darwin_proxy.py {{mode}} http://127.0.0.1:12345
  sleep 1

############################################################################
#
#  Misc, other useful commands
#
############################################################################

# format the nix files in this repo
fmt:
  nix fmt

# edit an age secret with shell path-completion, e.g. `just edit-secret secrets/my_secret.age`
edit-secret path:
  cd secrets/ && nix run .#agenix -- -e $(basename {{path}})

# List the current PATH, one entry per line
path:
  echo $PATH | tr ':' '\n'
