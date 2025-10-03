# SSH Authentication with Ledger

Use your Ledger hardware wallet for secure SSH authentication.

---

## Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Using SSH with Ledger](#using-ssh-with-ledger)
- [GitHub/Server Configuration](#githubserver-configuration)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)
- [Security Considerations](#security-considerations)
- [Related Documentation](#related-documentation)

---

## Overview

SSH authentication with Ledger provides hardware-backed security for SSH connections:

- **Private key on device** - Key never leaves Ledger
- **Physical confirmation** - Button press required for each auth
- **Multiple agents** - Two options: GPG agent or ledger-agent
- **Platform support** - Works with GitHub, GitLab, servers

---

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   SSH Authentication Flow                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ssh github.com                                             │
│      │                                                      │
│      ▼                                                      │
│  SSH Client (looks for key)                                 │
│      │                                                      │
│      ▼                                                      │
│  SSH Agent (ledger-agent or gpg-agent)                      │
│      │                                                      │
│      ▼                                                      │
│  Ledger Device                                              │
│      │                                                      │
│      ▼                                                      │
│  [User presses button to confirm]                           │
│      │                                                      │
│      ▼                                                      │
│  Signature returned → SSH connection established            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Key Types

Ledger supports:
- **ECDSA** (NIST P-256) - Default, widely supported
- **Ed25519** - Modern, faster (via ledger-agent)
- **NIST P-256 with SSH** - Via GPG agent

---

## Prerequisites

- [ ] Ledger Nano S device
- [ ] SSH/GPG Agent app installed on Ledger
- [ ] `ledger-agent` package installed (included in hardware-security profile)
- [ ] Device initialized and unlocked

See [Ledger Setup Guide](./ledger-setup.md) for initial setup.

---

## Setup

### Option 1: GPG Agent for SSH (Recommended)

Your configuration uses GPG agent with SSH support enabled:

**Already configured in `nix/profiles/hardware-security.nix`:**

```nix
services.gpg-agent = {
  enable = true;
  enableSshSupport = true;
  pinentry.package = pkgs.pinentry_mac;
};

home.sessionVariables = {
  SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
};
```

**Verify it's working:**

```bash
# Check SSH_AUTH_SOCK is set
echo $SSH_AUTH_SOCK
# Should show: /Users/you/.gnupg-ledger/S.gpg-agent.ssh

# List SSH keys from agent
ssh-add -L
```

### Option 2: Standalone Ledger SSH Agent

Alternative method using `ledger-agent` directly:

**Start the agent:**

```bash
# Start in background
ledger-agent -d ssh://ledger@localhost &

# Set SSH auth socket
export SSH_AUTH_SOCK="${HOME}/.ledger-agent/ssh-agent.sock"
```

**Or use launchd service (already configured):**

The hardware-security profile includes:

```nix
launchd.agents.ledger-ssh-agent = {
  enable = true;
  config = {
    ProgramArguments = [
      "${pkgs.ledger-agent}/bin/ledger-agent"
      "-d"
      "ssh://ledger@localhost"
    ];
    RunAtLoad = true;
  };
};
```

---

## Using SSH with Ledger

### Get Your SSH Public Key

```bash
# Using GPG agent (Option 1)
ssh-add -L

# Using ledger-agent (Option 2)
ledger-agent ssh://ledger@localhost &
ssh-add -L
```

Output example:
```
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTY... ledger
```

### Copy Public Key

```bash
# Copy to clipboard (macOS)
ssh-add -L | pbcopy

# Save to file
ssh-add -L > ~/.ssh/ledger_ssh.pub
```

### Test SSH Authentication

```bash
# Test GitHub
ssh -T git@github.com

# Ledger will display "SSH Auth" - press button to confirm

# Expected output:
# Hi username! You've successfully authenticated...
```

### SSH to Server

```bash
# Connect to server
ssh user@server.com

# Ledger prompts for confirmation
# Press button to authenticate
```

---

## GitHub/Server Configuration

### Add to GitHub

1. **Copy your public key:**
   ```bash
   ssh-add -L | pbcopy
   ```

2. **Add to GitHub:**
   - Go to **Settings → SSH and GPG keys**
   - Click **"New SSH key"**
   - Title: `Ledger SSH Key`
   - Key: Paste your public key
   - Click **"Add SSH key"**

3. **Verify:**
   ```bash
   ssh -T git@github.com
   ```

### Add to GitLab

1. Copy public key (same as above)
2. Go to **Preferences → SSH Keys**
3. Paste key and save

### Add to Server

```bash
# Copy public key to server
ssh-copy-id -i <(ssh-add -L) user@server.com

# Or manually append to authorized_keys
ssh-add -L | ssh user@server.com 'cat >> ~/.ssh/authorized_keys'
```

### Test Connection

```bash
# SSH with verbose output
ssh -v user@server.com

# Look for:
# debug1: Offering public key: ecdsa-sha2-nistp256 ... ledger
# debug1: Server accepts key: ...
# [Ledger prompts for confirmation]
```

---

## Troubleshooting

### SSH_AUTH_SOCK Not Set

**Problem:** `ssh-add -L` shows "Could not open a connection to your authentication agent"

**Solution:**

```bash
# For GPG agent
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# For ledger-agent
export SSH_AUTH_SOCK="${HOME}/.ledger-agent/ssh-agent.sock"

# Add to ~/.zshrc to persist
echo 'export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)' >> ~/.zshrc
```

### No Keys Listed

**Problem:** `ssh-add -L` shows "The agent has no identities"

**Solution:**

```bash
# Ensure Ledger is:
# 1. Connected via USB
# 2. Unlocked (PIN entered)
# 3. SSH/GPG Agent app is open
# 4. Screen shows "ready"

# Restart agent
killall gpg-agent ledger-agent
gpgconf --launch gpg-agent

# Or start ledger-agent
ledger-agent -d ssh://ledger@localhost &

# Check again
ssh-add -L
```

### Ledger Not Responding

**Problem:** SSH hangs waiting for Ledger

**Checklist:**
- [ ] Ledger connected and unlocked
- [ ] SSH/GPG Agent app is open on device
- [ ] Device screen shows "SSH/GPG Agent is ready"
- [ ] Agent process running: `pgrep -f ledger`

**Test:**
```bash
# Check agent status
pgrep -f "ledger-agent\|gpg-agent"

# Check logs
tail -f ~/.local/share/ledger-ssh-agent.log
tail -f ~/.local/share/gpg-agent.log
```

### Permission Denied (publickey)

**Problem:** Server rejects Ledger key

**Solution:**

1. **Verify key is on server:**
   ```bash
   ssh user@server.com 'cat ~/.ssh/authorized_keys' | grep "$(ssh-add -L | cut -d' ' -f2)"
   ```

2. **Check server logs:**
   ```bash
   ssh user@server.com 'sudo tail /var/log/auth.log'
   ```

3. **Try with verbose output:**
   ```bash
   ssh -vvv user@server.com
   ```

### Agent Conflicts

**Problem:** Multiple SSH agents interfering

**Solution:**

```bash
# Kill all agents
killall ssh-agent gpg-agent ledger-agent

# Start only one
gpgconf --launch gpg-agent

# Verify
echo $SSH_AUTH_SOCK
ssh-add -L
```

---

## Advanced Usage

### Multiple Keys

List all available SSH keys:

```bash
# From agent
ssh-add -L

# Specify key explicitly
ssh -i <(ssh-add -L | head -1 | awk '{print $1" "$2}') user@server.com
```

### SSH Config

Configure per-host settings in `~/.ssh/config`:

```ssh
# Use Ledger for GitHub
Host github.com
  IdentityAgent /Users/you/.gnupg-ledger/S.gpg-agent.ssh
  IdentitiesOnly yes

# Use Ledger for work servers
Host *.company.com
  IdentityAgent /Users/you/.gnupg-ledger/S.gpg-agent.ssh
  User your-username
```

### Key Derivation Paths

ledger-agent supports different derivation paths:

```bash
# Default path
ledger-agent ssh://ledger@localhost

# Custom path
ledger-agent ssh://ledger@localhost/0h/1h/2h

# Ed25519 (if supported)
ledger-agent ssh://ledger@localhost --curve ed25519
```

### Forwarding SSH Agent

Forward Ledger agent to remote machine:

```bash
# Enable agent forwarding
ssh -A user@server.com

# On remote machine, SSH will use your Ledger
ssh git@github.com
```

**Security Note:** Only forward to trusted machines.

### Using with Git

Configure Git to always use SSH:

```bash
# Set SSH for Git globally
git config --global url."ssh://git@github.com/".insteadOf "https://github.com/"

# Clone repos using SSH
git clone git@github.com:user/repo.git
```

---

## Security Considerations

### Threat Model

**What Ledger SSH protects against:**
- ✅ Key theft from computer
- ✅ Malware extracting SSH keys
- ✅ Unauthorized SSH access
- ✅ Key exfiltration via network

**What it doesn't protect against:**
- ❌ Malware intercepting SSH session after auth
- ❌ Compromised remote server
- ❌ Physical theft of Ledger (PIN protects)
- ❌ Social engineering attacks

### Best Practices

1. **Physical Security**
   - Remove Ledger when not in use
   - Lock screen when away

2. **Key Management**
   - Use separate keys for different purposes
   - Rotate keys periodically
   - Remove old keys from servers

3. **Agent Security**
   - Don't forward agent to untrusted machines
   - Use `IdentitiesOnly yes` in SSH config
   - Monitor agent logs for unusual activity

4. **Backup**
   - Keep 24-word recovery phrase secure
   - Test recovery process periodically
   - Consider backup Ledger device

### Recovery

If Ledger is lost or damaged:

1. **Restore from seed:**
   ```bash
   # On new Ledger with same seed
   ledger-agent ssh://ledger@localhost
   ssh-add -L  # Same key will be generated
   ```

2. **Or use backup key:**
   - Keep traditional SSH key as backup
   - Store securely (encrypted)
   - Only use when Ledger unavailable

---

## Related Documentation

- [Ledger Setup Guide](./ledger-setup.md) - Initial Ledger configuration
- [Ledger Deep Dive](./ledger-overview.md) - Comprehensive hardware security
- [GPG Signing](./gpg-signing.md) - Git commit signing with Ledger
- [SOPS Guide](../secrets-management/sops.md) - Secrets management

---

## External References

- [Ledger SSH/GPG Agent](https://github.com/LedgerHQ/app-ssh-agent) - Official app
- [trezor-agent SSH](https://github.com/romanz/trezor-agent/blob/master/doc/README-SSH.md) - Agent docs
- [SSH Public Key Auth](https://www.ssh.com/academy/ssh/public-key-authentication) - SSH documentation
- [GitHub SSH Keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) - GitHub docs

---

## Quick Reference

### Essential Commands

```bash
# Get SSH public key
ssh-add -L

# Test GitHub
ssh -T git@github.com

# Test server
ssh user@server.com

# Check agent
echo $SSH_AUTH_SOCK

# Restart agent (GPG)
killall gpg-agent && gpgconf --launch gpg-agent

# Start ledger-agent
ledger-agent -d ssh://ledger@localhost &

# View logs
tail -f ~/.local/share/ledger-ssh-agent.log
```

### Environment Setup

```bash
# Add to ~/.zshrc

# For GPG agent
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# For ledger-agent
export SSH_AUTH_SOCK="${HOME}/.ledger-agent/ssh-agent.sock"
```

---

**Happy secure SSH! 🔐**

See [GPG Signing](./gpg-signing.md) for commit signing with Ledger.
