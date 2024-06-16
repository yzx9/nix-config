# just is a command runner, Justfile is very similar to Makefile, but simpler.

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
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

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
#  Darwin related commands, harmonica is my macbook pro's hostname
#
############################################################################

[macos]
darwin-proxy-set:
  sudo python3 scripts/darwin_proxy.py set
  sleep 1


[macos]
darwin-proxy-unset:
  sudo python3 scripts/darwin_proxy.py unset
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
   $env.PATH | split row ":"
