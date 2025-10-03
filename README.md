# Nix Configuration - Multi-Platform Modular Setup

A modular Nix configuration supporting macOS (Darwin), Linux (NixOS), and cloud deployments (AWS EC2, GCP GCE).

## Quick Start

### Initial Setup

1. **Install Nix** (Determinate Systems installer)
```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
```

2. **Install Homebrew** (macOS only)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. **First-time activation**
```bash
mv ~/.zshrc ~/.zshrc.backup  # Backup existing config
sudo nix run nix-darwin -- switch --flake .#wikigen-mac
```

### Daily Usage

```bash
# Apply configuration changes
darwin-rebuild switch --flake .#wikigen-mac

# Build specific packages
nix build .#ai-clis
nix build .#ledger-agent

# Enter development shell
nix develop

# Update flake inputs
nix flake update

# View all flake outputs
nix flake show
```

## Repository Structure

```
.
├── flake.nix                 # Main flake configuration
├── flake.lock                # Locked dependencies
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
│   │       └── sops.nix      # SOPS secrets management
│   ├── profiles/             # Composable feature profiles
│   │   ├── cloud-cli.nix     # AWS/GCP/K8s tools
│   │   ├── developer.nix     # Development utilities
│   │   └── hardware-security.nix  # Ledger/GPG/SSH
│   ├── overlays/             # Package overlays
│   │   ├── ledger-agent.nix
│   │   └── ledger-ssh-agent.nix
│   ├── packages/             # Custom packages
│   │   └── ai-clis.nix
│   └── secrets/              # SOPS encrypted secrets
├── hosts/                    # Host-specific configurations
│   ├── wikigen-mac.nix       # MacBook Pro config
│   ├── linux-workstation.nix # Linux workstation (placeholder)
│   └── README.md
└── home/                     # Home Manager configurations
    └── users/
        └── wikigen.nix       # User-specific config
```

## Features

### Hardware Security
- **Ledger hardware wallet** integration for SSH and GPG
- GPG signing with OpenPGP card
- SSH authentication via hardware wallet
- SOPS secrets management with GPG encryption

### Development Tools
- AI CLI tools (Claude Code, MCP Inspector)
- Container tools (Colima, Docker, Skopeo, Dive)
- Cloud CLIs (AWS, GCP, Kubernetes, Terraform)
- Development utilities (jq, yq, tree, just)

### Multi-Platform Support
- **macOS** (Darwin) - fully configured
- **Linux** (NixOS) - ready for deployment
- **Cloud** (EC2/GCE) - placeholder modules

## Adding New Hosts

### macOS Host
Create `hosts/my-mac.nix`:
```nix
{ config, pkgs, self, ... }:
{
  system.primaryUser = "username";
  users.users.username = {
    name = "username";
    home = "/Users/username";
  };
}
```

Add to `flake.nix`:
```nix
darwinConfigurations.my-mac = darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    ./nix/modules/common.nix
    ./nix/modules/darwin-base.nix
    ./nix/modules/darwin/homebrew.nix
    ./nix/profiles/cloud-cli.nix
    ./nix/profiles/developer.nix
    ./hosts/my-mac.nix
    # ... home-manager config
  ];
};
```

### Linux/NixOS Host
Uncomment the NixOS configuration in `flake.nix` and customize `hosts/linux-workstation.nix`.

## Documentation

- **Design Specifications**: `docs/design.md` - Architecture and future roadmap
- **Host Configuration**: `hosts/README.md` - Host-specific setup guide
- **SOPS/Secrets**: `docs/sops.md` - Secrets management
- **GPG Setup**: `docs/gpg.md` - GPG and Ledger configuration
- **Git Signing**: `docs/git-sign.md` - GPG-based commit signing

## References

- [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [Home Manager](https://github.com/nix-community/home-manager)
- [flake-parts](https://github.com/hercules-ci/flake-parts)
- [SOPS-nix](https://github.com/Mic92/sops-nix)
- [Colima](https://github.com/abiosoft/colima)
- [Ledger SSH/GPG Agent](https://github.com/LedgerHQ/app-ssh-agent)
- [Trezor Agent](https://github.com/romanz/trezor-agent)

## Future Roadmap

See `docs/design.md` for detailed plans on:
- NixOS workstation deployments
- Cloud images (EC2/GCE) with nixos-generators
- Kubernetes manifests via Kubenix
- Infrastructure as Code with Terranix
- GitOps with Flux/ArgoCD
- OCI image builds with dockerTools
