# GCP GCE base configuration
# Placeholder for future GCE deployments
{ config, pkgs, lib, ... }:
{
  # GCE-specific boot settings
  boot.growPartition = true;
  boot.kernelParams = [ "console=ttyS0" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  # Google Guest Agent for GCE metadata
  services.google-guest-agent.enable = true;

  # Networking
  networking.firewall.enable = true;

  # Minimal environment for cloud
  environment.defaultPackages = [ ];
  documentation.enable = false;

  # Optional: Tailscale for secure access
  # services.tailscale.enable = true;
}
