# Cross-platform common configuration
# Used by both Darwin and NixOS systems
{ lib, pkgs, config, ... }:
{
  # Nix configuration
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    warn-dirty = false;
    trusted-users = [ "root" "@admin" ];
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  # Enable automatic garbage collection (only if nix.enable is true)
  # Note: When using Determinate Nix (nix.enable = false), configure GC via Determinate Nix's settings
  nix.gc = lib.mkIf config.nix.enable {
    automatic = true;
    options = "--delete-older-than 14d";
  };

  # Common packages across all platforms
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
  ];

  # Default environment variables
  environment.variables = {
    EDITOR = "vim";
    PAGER = "less -SR";
  };
}
