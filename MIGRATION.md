# Nix Configuration Modularization - Migration Guide

This document describes the changes made to modularize your Nix configuration.

## What Changed

### Old Structure (Flat)
```
.
├── flake.nix
├── darwin-configuration.nix  (monolithic)
└── home.nix                  (monolithic)
```

### New Structure (Modular)
```
.
├── flake.nix                 (updated with flake-parts)
├── nix/
│   ├── modules/              # Reusable system modules
│   │   ├── common.nix        # Cross-platform config
│   │   ├── darwin-base.nix   # macOS base config
│   │   ├── linux-base.nix    # Linux/NixOS base config
│   │   ├── darwin/
│   │   │   └── homebrew.nix  # Homebrew configuration
│   │   ├── cloud/
│   │   │   ├── ec2-base.nix  # AWS EC2 config
│   │   │   └── gce-base.nix  # GCP GCE config
│   │   └── secrets/
│   │       └── sops.nix      # SOPS configuration
│   ├── profiles/             # Feature profiles
│   │   ├── cloud-cli.nix     # Cloud tools (AWS, GCP, K8s)
│   │   ├── developer.nix     # Development tools
│   │   └── hardware-security.nix  # Ledger/GPG/SSH
│   ├── overlays/             # Package overlays
│   └── packages/             # Custom packages
├── hosts/                    # Host-specific configs
│   ├── wikigen-mac.nix       # Your MacBook Pro
│   ├── linux-workstation.nix # Future Linux support
│   └── README.md
└── home/                     # Home Manager configs
    └── users/
        └── wikigen.nix       # User-specific config
```

## Key Improvements

### 1. **Multi-Platform Support**
- **Systems**: `aarch64-darwin`, `x86_64-linux`, `aarch64-linux`
- **Platforms**: macOS (Darwin), Linux (NixOS), Cloud (EC2, GCE)
- Ready to add NixOS workstations and cloud deployments

### 2. **Modular Organization**
- **Base modules**: Platform-specific foundations (darwin-base, linux-base)
- **Common module**: Shared configuration across all platforms
- **Profiles**: Composable feature sets (cloud-cli, developer, hardware-security)
- **Hosts**: Machine-specific configurations

### 3. **Flake-parts Integration**
- Better organization with `perSystem` for cross-platform packages
- Cleaner separation between system configurations and packages
- Easier to add new platforms and architectures

### 4. **Future-Ready**
- Placeholder modules for Linux and cloud deployments
- Commented-out inputs for nixos-generators, impermanence, etc.
- Structure follows the design.md specifications

## How to Use

### Apply the New Configuration

```bash
# Build and switch to the new configuration
darwin-rebuild switch --flake .#wikigen-mac

# Or using sudo if needed
sudo darwin-rebuild switch --flake .#wikigen-mac
```

### Build Specific Outputs

```bash
# Build packages
nix build .#ai-clis
nix build .#ledger-agent

# Enter dev shell
nix develop

# Check flake outputs
nix flake show
```

### Adding a New Host

1. Create a new file in `hosts/` (e.g., `hosts/my-server.nix`)
2. Import the appropriate base module and profiles
3. Add the host to `flake.nix` in the appropriate configuration section

Example for a NixOS machine:
```nix
# hosts/my-server.nix
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "my-server";
  # ... host-specific config
}
```

Then add to `flake.nix`:
```nix
nixosConfigurations.my-server = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./nix/modules/common.nix
    ./nix/modules/linux-base.nix
    ./nix/profiles/cloud-cli.nix
    ./hosts/my-server.nix
    # ... more modules
  ];
};
```

## What Stays the Same

- All your existing functionality is preserved
- Ledger hardware wallet integration (SSH + GPG)
- SOPS secrets management
- Homebrew for macOS-specific apps
- AI CLI tools
- All packages and overlays

## Testing

The configuration has been tested with:
```bash
nix build .#darwinConfigurations.wikigen-mac.system --dry-run
```

All deprecation warnings have been fixed:
- ✅ Updated `pinentryPackage` → `pinentry.package`
- ✅ Updated `initExtra` → `initContent`

## Next Steps

### Immediate
1. Test the new configuration: `darwin-rebuild switch --flake .#wikigen-mac`
2. Commit the changes to git
3. Remove old files: `darwin-configuration.nix` and `home.nix` (after confirming everything works)

### Future Enhancements
1. **Add Linux support**: Uncomment NixOS configuration in `flake.nix`
2. **Cloud deployments**: Enable nixos-generators for EC2/GCE images
3. **Colima declarative config**: Add to `nix/modules/darwin/colima.nix`
4. **Kubernetes**: Add kubenix for K8s manifests
5. **Infrastructure as Code**: Add terranix for Terraform generation

## Troubleshooting

### Build fails with "version mismatch"
- Make sure you're using `nixpkgs-unstable` for macOS (required by nix-darwin)
- Run `nix flake update` to update lock file

### Permission denied on flake.lock
- If you ran `sudo nix flake update`, the lock file may be owned by root
- Fix with: `sudo chown wikigen:staff flake.lock`

### Module not found
- Make sure all paths in imports are correct
- Use relative paths from the importing file

## Reference

- Design specification: `docs/design.md`
- Hosts documentation: `hosts/README.md`
- Original configs preserved in git history
