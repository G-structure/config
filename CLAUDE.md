# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a modular Nix configuration repository supporting macOS (nix-darwin), Linux (NixOS), and cloud deployments. The architecture emphasizes modularity, reusability, and hardware security integration with Ledger hardware wallets for GPG signing and SSH authentication.

## Essential Commands

### System Configuration

```bash
# Apply configuration changes (macOS)
darwin-rebuild switch --flake .#wikigen-mac

# Build without applying
darwin-rebuild build --flake .#wikigen-mac

# Update flake dependencies
nix flake update

# View all available outputs
nix flake show

# Check flake validity
nix flake check
```

### Package Management

```bash
# Build specific packages
nix build .#ai-clis
nix build .#ledger-agent
nix build .#ledger-ssh-agent

# Enter development shell
nix develop

# Enter docs development shell (includes Astro/Starlight)
nix develop .#docs
```

### Documentation Site

```bash
# From docs dev shell:
cd site && npm run dev    # Start dev server (port 4321)
npm run build             # Build static site
npm run preview           # Preview built site
```

### Ledger Hardware Security

```bash
# Test Ledger agent connection
ledger-agent -c ssh://ledger@localhost

# Import Ledger GPG key
ledger-gpg-agent --homedir ~/.gnupg-ledger -v

# Test GPG signing with Ledger
echo "test" | gpg --homedir ~/.gnupg-ledger --clearsign
```

### Secrets Management (SOPS)

```bash
# Edit encrypted secrets (requires Ledger connected)
GNUPGHOME=~/.gnupg-ledger sops nix/secrets/secrets.yaml

# Encrypt new file with Ledger key
GNUPGHOME=~/.gnupg-ledger sops -e secrets.yaml > secrets.enc.yaml
```

## Architecture

### Directory Structure

- **`flake.nix`** - Main entry point defining all system configurations and packages
- **`nix/modules/`** - Base system modules (common, darwin-base, linux-base)
  - `common.nix` - Cross-platform configuration
  - `darwin-base.nix` - macOS base settings
  - `linux-base.nix` - NixOS base settings
  - `darwin/homebrew.nix` - Homebrew integration for GUI apps
  - `secrets/sops.nix` - SOPS secrets management with Ledger GPG
  - `cloud/` - EC2/GCE modules (placeholder)
- **`nix/profiles/`** - Composable feature profiles (developer, cloud-cli, hardware-security)
- **`nix/overlays/`** - Package overlays for custom builds
  - `ledger-agent.nix` - Builds trezor-agent with Ledger support
  - `ledger-ssh-agent.nix` - Ledger SSH agent overlay
- **`nix/packages/`** - Standalone package definitions
  - `ai-clis.nix` - AI CLI tools bundle (Claude Code, MCP Inspector, etc.)
- **`nix/secrets/`** - SOPS-encrypted secrets (GPG-encrypted with Ledger key)
- **`hosts/`** - Host-specific configurations (wikigen-mac.nix, etc.)
- **`home/users/`** - Home Manager user configurations
- **`extern/`** - Git submodules for external projects and references
- **`docs/`** - Comprehensive documentation (Markdown)
- **`site/`** - Astro/Starlight documentation site

### Modular Design Philosophy

The configuration uses **flake-parts** for organization and follows a layered architecture:

1. **Base modules** (`nix/modules/`) - Core system settings
2. **Profiles** (`nix/profiles/`) - Feature bundles (e.g., cloud-cli, developer, hardware-security)
3. **Overlays** (`nix/overlays/`) - Package customizations and patches
4. **Host configs** (`hosts/`) - Machine-specific settings
5. **Home Manager** (`home/users/`) - User environment configuration

### Hardware Security Integration

This config has deep integration with Ledger hardware wallets:

- **GPG Signing**: Git commits are signed using GPG keys stored on Ledger OpenPGP card
- **SSH Authentication**: SSH keys are generated and stored on the Ledger device
- **SOPS Encryption**: All secrets are encrypted with Ledger GPG key (never exposed to disk)
- **Custom Patches**: The `ledger-agent.nix` overlay includes critical patches for GPG signing compatibility

**Key GPG Configuration**:
- GPG keyring location: `~/.gnupg-ledger` (isolated from system GPG)
- GPG key: `D2A7EC63E350CC488197CB2ED369B07E00FB233E`
- Git uses wrapper scripts to auto-start `ledger-gpg-agent` when signing commits
- launchd services (macOS) auto-start Ledger agents on login

### External Project Submodules

The `extern/` directory contains git submodules:
- **Ledger apps**: `app-ssh-agent`, `app-openpgp` (Ledger firmware apps)
- **trezor-agent**: Base implementation for hardware wallet agents
- **Personal projects**: pastebin, lucksacks, bash-agent, kopf-agent, notes, etc.

These serve as reference implementations and inspiration for Nix configurations.

## Common Development Tasks

### Adding a New Package

1. Add to `environment.systemPackages` in a profile or module
2. Or create a custom package in `nix/packages/`
3. Rebuild: `darwin-rebuild switch --flake .#wikigen-mac`

### Creating a New Profile

1. Create `nix/profiles/my-profile.nix`
2. Define `environment.systemPackages` or other settings
3. Import in host config or flake.nix module list
4. See `nix/profiles/developer.nix` for a minimal example

### Adding a New macOS Host

1. Create `hosts/my-mac.nix` with user and hostname
2. Add to `flake.nix` under `darwinConfigurations`
3. Activate: `darwin-rebuild switch --flake .#my-mac`

### Working with Overlays

Overlays modify or add packages to nixpkgs. See `nix/overlays/ledger-agent.nix` for a complex example that:
- Patches Python package dependencies
- Applies source code patches for Ledger compatibility
- Builds custom Python applications with specific dependencies

### Troubleshooting Ledger Issues

If GPG signing fails:
1. Ensure Ledger is connected and unlocked
2. Check `ledger-gpg-agent` is running: `pgrep -f ledger-gpg-agent`
3. Restart agent: `pkill -f ledger-gpg-agent` then let launchd restart it
4. Verify key import: `gpg --homedir ~/.gnupg-ledger --card-status`

If SSH auth fails:
1. Check `SSH_AUTH_SOCK` points to: `$(gpgconf --list-dirs agent-ssh-socket)`
2. Ensure `gpg-agent` has SSH support enabled (in hardware-security profile)
3. Verify SSH key is visible: `ssh-add -L`

## Key Implementation Details

### Nix Flake Structure

The flake uses **flake-parts** with `perSystem` for cross-platform package builds and `flake` outputs for system configurations:

- `packages.<system>.*` - Built via `perSystem` (ai-clis, ledger-agent, etc.)
- `darwinConfigurations.*` - macOS systems using nix-darwin
- `nixosConfigurations.*` - Linux systems (currently placeholder)
- `devShells.<system>.*` - Development environments (default, docs)

### SOPS Integration

Secrets workflow:
1. `.sops.yaml` defines encryption rules (uses Ledger GPG key)
2. `nix/modules/secrets/sops.nix` configures SOPS integration
3. `GNUPGHOME=~/.gnupg-ledger` ensures Ledger GPG keyring is used
4. Secrets in `nix/secrets/*.yaml` are encrypted at rest
5. On system activation, SOPS decrypts to `/run/secrets/*` (requires Ledger connected)

### Home Manager Integration

Home Manager is integrated at the **system level** (not standalone):
- Imported in `flake.nix` as a darwinModule
- User config: `home/users/wikigen.nix`
- Shares nixpkgs with system config (`useGlobalPkgs = true`)
- Hardware security profile is a Home Manager module (in `nix/profiles/hardware-security.nix`)

## Documentation

Comprehensive docs are in `docs/` directory:
- **Getting Started**: Installation, quickstart, first steps
- **Architecture**: Design philosophy, structure, Nix concepts
- **Guides**: Hardware security, secrets management, development, deployment
- **Reference**: Module/profile docs, CLI commands, troubleshooting

The docs are also available as a Starlight site in `site/` - built with Astro, accessible via `nix develop .#docs`.

## Important Notes

- Uses **Determinate Nix installer** (not official Nix installer)
- macOS uses **nixpkgs-unstable** (required by nix-darwin)
- Homebrew handles GUI apps not in nixpkgs (Ledger Live, Docker Desktop via Colima)
- Git signing wrapper scripts auto-start `ledger-gpg-agent` on demand
- All system builds require flake reference (e.g., `.#wikigen-mac`)
