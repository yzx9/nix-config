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

# Run eval tests
[group('flake')]
test:
  nix eval .#evalTests --show-trace --print-build-logs --verbose

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

# remove all generations older than 7 days
[group('nix')]
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d

# Garbage collect all unused nix store entries
[group('nix')]
gc:
  # garbage collect all unused nix store entries
  sudo nix store gc --debug
  sudo nix-collect-garbage --delete-old

# Remove all reflog entries and prune unreachable objects
[group('nix')]
gitgc:
  git reflog expire --expire-unreachable=now --all
  git gc --prune=now


############################################################################
#
#  Linux related commands
#
############################################################################

[linux]
[group('os')]
switch:
  sudo nixos-rebuild switch --flake .

[linux]
[group('os')]
switch-dev:
  sudo nixos-rebuild switch --show-trace --verbose --flake .

[linux]
[group('os')]
rollback:
  sudo nixos-rebuild switch --rollback

[linux]
[group('os')]
hm-switch hostname = `hostname`:
  home-manager switch --flake .#{{hostname}}


############################################################################
#
#  Darwin related commands
#
############################################################################

[macos]
[group('os')]
switch-noproxy:
  sudo darwin-rebuild switch --flake .

[macos]
[group('os')]
switch: switch-noproxy (proxy "set")

[macos]
[group('os')]
switch-dev:
  sudo darwin-rebuild switch --show-trace --verbose --flake .

[macos]
[group('os')]
rollback: rollback-noproxy (proxy "set")

[macos]
[group('os')]
rollback-noproxy:
  sudo darwin-rebuild switch --rollback

[macos]
[group('os')]
proxy mode="auto_switch":
  sudo nix run nixpkgs#python3 scripts/darwin_proxy.py {{mode}} http://127.0.0.1:12345
  sleep 1

# Remote deployments with linux-builder: https://nixcademy.com/posts/macos-linux-builder/
[macos]
[group('os')]
deploy hostname:
  nix run nixpkgs#nixos-rebuild -- \
    switch \
      --fast \
      --target-host {{hostname}} \
      --flake .#{{hostname}} \
      --use-remote-sudo


############################################################################
#
#  Misc, other useful commands
#
############################################################################

fmt:
  # format the nix files in this repo
  nix fmt

edit-secret name:
  # edit a secret in the nixos-configuration repo
  cd secrets/ && nix run .#agenix -- -e {{name}}.age

path:
  echo $PATH | tr ':' '\n'
