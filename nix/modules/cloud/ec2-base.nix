# AWS EC2 base configuration
# Placeholder for future EC2 deployments
{ config, pkgs, lib, ... }:
{
  # EC2-specific boot settings
  boot.growPartition = true;
  boot.kernelParams = [ "console=ttyS0" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  # Cloud-init for EC2 metadata
  services.cloud-init.enable = true;

  # AWS SSM Agent for remote management
  # services.amazon-ssm-agent.enable = true;

  # Predictable network interface names
  networking.usePredictableInterfaceNames = false; # eth0

  # Minimal environment for cloud
  environment.defaultPackages = [ ];
  documentation.enable = false;

  # Optional: Tailscale for secure access
  # services.tailscale.enable = true;
}
