# Linux/NixOS base configuration
# Placeholder for future Linux support
{ config, pkgs, lib, ... }:
{
  # NixOS system version (update when creating actual NixOS configs)
  system.stateVersion = "24.05";

  # Enable flakes for NixOS
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Basic system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  # Enable SSH by default
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      KbdInteractiveAuthentication = lib.mkDefault false;
    };
  };

  # Basic networking
  networking.firewall.enable = lib.mkDefault true;
}
