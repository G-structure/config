---
title: Hardware Security Guides
---


Comprehensive guides for using Ledger hardware wallets with this Nix configuration.

---

## Overview

This section covers hardware-backed security using Ledger Nano S for:
- GPG signing (git commits, messages, files)
- SSH authentication (GitHub, servers)
- Secrets management (SOPS encryption)

All operations require **physical confirmation** on your device, providing hardware-level security.

---

## Documentation in This Section

### [Ledger Setup Guide](./ledger-setup.md) ⭐
**Start here** for complete Ledger configuration from scratch.

**Covers:**
- Installing Ledger Live and SSH/GPG Agent app
- Initializing GPG keys on device
- Configuring SSH authentication
- Setting up SOPS secrets management
- Troubleshooting and verification

**Status:** ✅ Complete step-by-step guide

---

### [Ledger Overview](./ledger-overview.md)
**Deep dive** into hardware security architecture and implementation.

**Covers:**
- Comprehensive hardware wallet theory
- Security model and threat analysis
- Advanced configuration patterns
- Integration with cloud and CI/CD
- Best practices and operational security

**Status:** ✅ Comprehensive reference

---

### [GPG Signing](./gpg-signing.md)
Using Ledger for GPG operations and git commit signing.

**Covers:**
- GPG key management on Ledger
- Git commit signing (automatic)
- Manual GPG operations (sign, encrypt, verify)
- GitHub/GitLab integration
- Troubleshooting agent issues

**Status:** ✅ Complete with examples

---

### [SSH Authentication](./ssh-authentication.md)
SSH authentication with hardware-backed keys.

**Covers:**
- SSH agent configuration (GPG agent vs ledger-agent)
- Getting SSH public keys from Ledger
- Adding keys to GitHub/GitLab/servers
- Troubleshooting connection issues
- Advanced usage (forwarding, multiple keys)

**Status:** ✅ Complete with troubleshooting

---

## Quick Start

### Prerequisites

- Ledger Nano S device
- USB cable
- macOS with this Nix config installed

### Installation (5 minutes)

```bash
# 1. Enable hardware-security profile in your user config
# In home/users/yourname.nix:
imports = [
  ../../nix/profiles/hardware-security.nix
];

# 2. Rebuild
darwin-rebuild switch --flake .#your-hostname

# 3. Install Ledger Live via Homebrew
open -a "Ledger Live"

# 4. Follow Ledger Setup Guide
```

See [Ledger Setup Guide](./ledger-setup.md) for detailed instructions.

---

## What You Get

After completing the setup:

### GPG Signing ✅
```bash
# Automatic git commit signing
git commit -m "message"
# Ledger prompts for confirmation

# Verified badge on GitHub
```

### SSH Authentication ✅
```bash
# SSH with hardware key
ssh -T git@github.com
# Ledger prompts for confirmation

# Works with all SSH servers
ssh user@server.com
```

### SOPS Secrets ✅
```bash
# Encrypt/decrypt secrets with Ledger
sops nix/secrets/secrets.yaml
# Ledger prompts for confirmation

# Safe to commit encrypted secrets
git add nix/secrets/secrets.yaml
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Hardware Security Stack                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Application Layer                                          │
│  ├── Git (commit signing)                                   │
│  ├── SSH (authentication)                                   │
│  └── SOPS (secrets encryption)                              │
│         │                                                   │
│         ▼                                                   │
│  Agent Layer                                                │
│  ├── ledger-gpg-agent (GPG operations)                      │
│  └── ledger-ssh-agent (SSH operations)                      │
│         │                                                   │
│         ▼                                                   │
│  Hardware Layer                                             │
│  └── Ledger Nano S                                          │
│      ├── Private keys (never leave device)                  │
│      ├── SSH/GPG Agent app                                  │
│      └── Physical confirmation required                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Features

### 🔐 Hardware Security
- **Private keys on device** - Never exposed to computer
- **Physical confirmation** - Button press for every operation
- **Recovery seed** - Keys derived from 24-word phrase
- **Multi-purpose** - One device for GPG, SSH, and secrets

### 🔄 Nix Integration
- **Declarative config** - All settings in Nix files
- **Automatic agents** - launchd services start on login
- **Wrapper scripts** - Auto-manage agent lifecycle
- **Profile-based** - Enable with single import

### 🛡️ Operational Security
- **Audit trail** - All signed commits in Git history
- **Platform integration** - Verified badges on GitHub
- **No plaintext keys** - Keys never on disk
- **Backup strategy** - Recovery phrase + hardware backup

---

## Common Tasks

### Get Started
1. [Set up Ledger device](./ledger-setup.md)
2. [Configure GPG signing](./gpg-signing.md)
3. [Set up SSH authentication](./ssh-authentication.md)

### Daily Usage
```bash
# Git commits (automatic signing)
git commit -m "message"

# SSH to GitHub
ssh -T git@github.com

# Edit secrets
sops nix/secrets/secrets.yaml
```

### Troubleshooting
- [Ledger not responding](./ledger-setup.md#troubleshooting)
- [GPG signing issues](./gpg-signing.md#troubleshooting)
- [SSH connection problems](./ssh-authentication.md#troubleshooting)

---

## Security Model

### Threat Protection

**What hardware security protects against:**
- ✅ Key theft from compromised computer
- ✅ Malware extracting private keys
- ✅ Unauthorized signing/authentication
- ✅ Key exfiltration over network
- ✅ Accidental key exposure

**What it doesn't protect against:**
- ❌ Physical theft of device (PIN protection)
- ❌ Malware after successful authentication
- ❌ Compromised remote systems
- ❌ Social engineering attacks
- ❌ Side-channel attacks on device

### Best Practices

1. **Device Security**
   - Remove Ledger when not in use
   - Lock screen when away from computer
   - Use strong PIN (6-8 digits)
   - Keep firmware updated

2. **Key Management**
   - Secure 24-word recovery phrase (offline storage)
   - Test recovery process periodically
   - Consider backup Ledger device
   - Use unique keys per purpose

3. **Operational Security**
   - Verify operations before confirming on device
   - Audit signed commits regularly
   - Rotate secrets periodically
   - Monitor agent logs

---

## Troubleshooting

### Ledger Not Detected

1. Check USB connection
2. Unlock with PIN
3. Open SSH/GPG Agent app on device
4. Verify screen shows "ready"

### Agent Not Running

```bash
# Check process
pgrep -f ledger-gpg-agent

# View logs
tail -f ~/.local/share/ledger-gpg-agent.log

# Restart
killall ledger-gpg-agent
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
```

### Operation Fails

1. Ensure Ledger app is open
2. Check for confirmation prompt on device
3. Press button to confirm
4. Check agent logs for errors

See individual guides for specific troubleshooting.

---

## Configuration Reference

### Nix Profile

The hardware-security profile (`nix/profiles/hardware-security.nix`) provides:

```nix
{
  # Packages
  home.packages = [
    ledger-agent
    ledger-ssh-agent
  ];

  # GPG configuration
  programs.gpg.enable = true;
  services.gpg-agent.enable = true;

  # Git signing
  programs.git.signing = {
    key = "YOUR-GPG-KEY-ID";
    signByDefault = true;
  };

  # Launchd services (auto-start agents)
  launchd.agents = {
    ledger-gpg-agent = { ... };
    ledger-ssh-agent = { ... };
  };
}
```

### Environment Variables

```bash
# GPG home directory
export GNUPGHOME=~/.gnupg-ledger

# SSH agent socket
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# GPG TTY (for signing)
export GPG_TTY=$(tty)
```

---

## Related Documentation

### In This Section
- [Ledger Setup](./ledger-setup.md) - Complete setup guide
- [Ledger Overview](./ledger-overview.md) - Deep dive
- [GPG Signing](./gpg-signing.md) - Commit signing
- [SSH Authentication](./ssh-authentication.md) - SSH with Ledger

### Other Sections
- [SOPS Secrets](../secrets-management/sops.md) - Secrets encryption
- [Structure Guide](../../architecture/structure.md) - Config architecture
- [Troubleshooting](../../reference/troubleshooting.md) - Common issues

---

## External Resources

- [Ledger SSH/GPG Agent](https://github.com/LedgerHQ/app-ssh-agent) - Official app
- [trezor-agent](https://github.com/romanz/trezor-agent) - Agent software
- [Ledger Developer Docs](https://developers.ledger.com/) - Technical docs
- [Hardware Security Guide](https://www.ledger.com/academy/security) - Best practices

---

**Ready to get started?** Follow the [Ledger Setup Guide](./ledger-setup.md)!
