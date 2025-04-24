# just is a command runner, Justfile is very similar to Makefile, but simpler.

default:
  @just --list

############################################################################
#
#  Common commands(suitable for all machines)
#
############################################################################

# Check whether the flake evaluates and run its tests
check:
  nix flake check --all-systems

# Run eval tests
test:
  nix eval .#evalTests --show-trace --print-build-logs --verbose

# Update all the flake inputs
up:
  nix flake update --commit-lock-file

# Update specific input, usage: just upp nixpkgs
upp input:
  nix flake update {{input}} --commit-lock-file

# List all generations of the system profile
history:
  nix profile history --profile /nix/var/nix/profiles/system

# Open a nix shell with the flake
repl:
  nix repl -f flake:nixpkgs

# remove all generations older than 7 days
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d

# Garbage collect all unused nix store entries
gc:
  # garbage collect all unused nix store entries
  sudo nix store gc --debug
  sudo nix-collect-garbage --delete-old

# Remove all reflog entries and prune unreachable objects
gitgc:
  git reflog expire --expire-unreachable=now --all
  git gc --prune=now


############################################################################
#
#  Linux related commands
#
############################################################################

[linux]
switch:
  sudo nixos-rebuild switch --flake .

[linux]
switch-dev:
  sudo nixos-rebuild switch --show-trace --verbose --flake .

[linux]
hm-switch hostname = `hostname`:
  home-manager switch --flake .#{{hostname}}


############################################################################
#
#  Darwin related commands
#
############################################################################

[macos]
switch-noproxy:
  darwin-rebuild switch --flake .

[macos]
switch: switch-noproxy (proxy "set")

[macos]
switch-dev:
  darwin-rebuild switch --show-trace --verbose --flake .

[macos]
proxy mode="auto_switch":
  sudo python3 scripts/darwin_proxy.py {{mode}} http://127.0.0.1:12345
  sleep 1

# Remote deployments with linux-builder: https://nixcademy.com/posts/macos-linux-builder/
[macos]
deploy hostname:
  nix run nixpkgs#nixos-rebuild -- \
    switch \
      --fast \
      --target-host {{hostname}} \
      --flake .#{{hostname}} \
      --use-remote-sudo \
      --use-substitutes


############################################################################
#
#  Misc, other useful commands
#
############################################################################

fmt:
  # format the nix files in this repo
  nix fmt

path:
  echo $PATH | tr ':' '\n'
