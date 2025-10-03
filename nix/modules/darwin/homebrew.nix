# Homebrew configuration for macOS
# Used for macOS-specific and GUI apps not available in nixpkgs
{ config, pkgs, lib, ... }:
{
  homebrew = {
    enable = true;

    # CLI tools that work better through Homebrew on macOS
    brews = [
      "colima"
      "docker"
      "docker-compose"
    ];

    # GUI applications
    casks = [
      "ledger-live"  # GUI app for Ledger device management (not available in nixpkgs for ARM Mac)
    ];

    # Homebrew maintenance
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
  };
}
