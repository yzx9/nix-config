{
  # Disable auto-optimise-store because of this issue:
  #   https://github.com/NixOS/nix/issues/7273
  # "error: cannot link '/nix/store/.tmp-link-xxxxx-xxxxx' to '/nix/store/.links/xxxx': File exists"
  nix.settings.auto-optimise-store = false;

  # set up a launchd service to optimize the store
  nix.optimise.automatic = true;

  # Enable sandboxing for Nix builds
  nix.settings.sandbox = true;
}
