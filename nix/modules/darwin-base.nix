# macOS (Darwin) base configuration
{ config, pkgs, lib, ... }:
{
  # Darwin system version
  system.stateVersion = 5;

  # Allow unfree packages and unsupported systems
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # Disable nix-darwin's Nix management (using Determinate Nix)
  nix.enable = false;

  # Note: Garbage collection is managed by Determinate Nix when nix.enable = false
  # Configure via Determinate Nix's settings instead of nix-darwin

  # macOS system defaults (can be extended)
  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 14;
      KeyRepeat = 1;
    };
    dock = {
      autohide = true;
      show-recents = false;
    };
    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
    };
  };
}
