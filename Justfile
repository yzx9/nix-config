# just is a command runner, Justfile is very similar to Makefile, but simpler.

default:
  @just --list

############################################################################
#
#  Common commands(suitable for all machines)
#
############################################################################

# Run eval tests
test:
  nix eval .#evalTests --show-trace --print-build-logs --verbose

# update all the flake inputs
up:
  nix flake update

# Update specific input
# Usage: just upp nixpkgs
upp input:
  nix flake update {{input}}

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
hm-rebuild hostname:
  home-manager switch --flake .#{{hostname}}


############################################################################
#
#  Darwin related commands
#
############################################################################

[macos]
rebuild-noproxy:
  darwin-rebuild switch --flake .

[macos]
rebuild: rebuild-noproxy (proxy "set")

[macos]
rebuild-dev:
  darwin-rebuild switch --show-trace --flake .

[macos]
proxy mode="auto_switch":
  sudo python3 scripts/darwin_proxy.py {{mode}} http://127.0.0.1:10087
  sleep 1


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
