{
  # set up a launchd service to optimize the store
  nix.optimise.automatic = true;

  # Enable sandboxing for Nix builds
  nix.settings.sandbox = true;
}
