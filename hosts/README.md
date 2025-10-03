# Hosts

This directory contains host-specific configurations for different machines.

## Current Hosts

- **wikigen-mac.nix** - WikiGen's MacBook Pro (aarch64-darwin)

## Placeholder Hosts

- **linux-workstation.nix** - Placeholder for future Linux/NixOS workstation
- Future: EC2 and GCE cloud instances

## Adding a New Host

1. Create a new `.nix` file in this directory
2. Import the appropriate base module:
   - For macOS: `../nix/modules/darwin-base.nix`
   - For Linux: `../nix/modules/linux-base.nix`
   - For EC2: `../nix/modules/cloud/ec2-base.nix`
   - For GCE: `../nix/modules/cloud/gce-base.nix`
3. Import common module: `../nix/modules/common.nix`
4. Import desired profiles from `../nix/profiles/`
5. Add host-specific configuration
6. Update `flake.nix` to include the new host
