# Ledger Nano S Setup Guide

**Goal:** Secure SSH authentication, GPG signing, and SOPS secret management using your Ledger Nano S, all integrated with your Nix flake.

**Stack:**
- Hardware: Ledger Nano S
- SSH/GPG: `ledger-agent` (from trezor-agent package)
- Secrets: SOPS + GPG
- Platform: macOS with Nix/nix-darwin

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Install Software via Nix](#step-1-install-software-via-nix)
- [Step 2: Initialize Your Ledger Device](#step-2-initialize-your-ledger-device)
- [Step 3: Install SSH/GPG App on Ledger](#step-3-install-sshgpg-app-on-ledger)
- [Step 4: Configure GPG with Ledger](#step-4-configure-gpg-with-ledger)
- [Step 5: Configure SSH with Ledger](#step-5-configure-ssh-with-ledger)
- [Step 6: Configure SOPS with Ledger GPG](#step-6-configure-sops-with-ledger-gpg)
- [Quick Reference](#quick-reference)
- [Troubleshooting](#troubleshooting)
- [Security Notes](#security-notes)
- [Next Steps](#next-steps)

---

## Prerequisites

- [ ] Ledger Nano S device
- [ ] USB cable
- [ ] macOS system with Nix installed
- [ ] This Nix configuration cloned locally

---

## Step 1: Install Software via Nix

The hardware security profile includes all required software. It's already configured in your setup via the `hardware-security.nix` profile.

### What's Included

**Nix packages** (from `nix/profiles/hardware-security.nix`):
- `ledger-agent` - Ledger SSH/GPG agent from trezor-agent
- `ledger-ssh-agent` - Standalone SSH agent for Ledger
- `gnupg` - GPG for encryption/signing
- `sops` - Secrets management (from `nix/modules/secrets/sops.nix`)

**Homebrew casks** (from `nix/modules/darwin/homebrew.nix`):
- `ledger-live` - GUI app for Ledger device management

### Apply Configuration

If not already activated, apply your Nix configuration:

```bash
cd /Users/wikigen/Config
darwin-rebuild switch --flake .#wikigen-mac
```

### Verify Installation

```bash
# CLI tools (from Nix)
which ledger-agent
which ledger-gpg-agent
which sops

# GUI app (from Homebrew)
open -a "Ledger Live"
```

**Status:** ✅ Already configured in your Nix flake

---

## Step 2: Initialize Your Ledger Device

### Launch Ledger Live

```bash
open -a "Ledger Live"
```

### Connect and Initialize

1. **Connect your Ledger Nano S** via USB
2. **Follow the on-screen setup:**
   - Choose "Set up as new device"
   - **CRITICAL:** Write down your 24-word recovery phrase on paper
   - Store it in a safe place (NOT on your computer)
   - Set a PIN code (6-8 digits recommended)
   - Confirm your recovery phrase by entering words when prompted

### Update Firmware

Ledger Live will check for firmware updates. Install any available updates to ensure compatibility with latest apps.

**Status:** ✅ Complete when device is initialized

---

## Step 3: Install SSH/GPG App on Ledger

The SSH/PGP Agent app enables your Ledger to handle SSH authentication and GPG operations.

### Enable Developer Mode

1. Open **Ledger Live**
2. Click the gear icon (⚙️) in the top right for **Settings**
3. Navigate to **"Experimental features"** tab
4. Toggle **"Developer mode"** to ON

This reveals developer apps including SSH/PGP Agent.

### Install SSH/PGP Agent

1. Navigate to **"Manager"** (left sidebar)
2. Connect and unlock your Ledger device (enter PIN)
3. Search for **"SSH/PGP Agent"**
4. Click **"Install"** button
5. Confirm on your Ledger device (press both buttons)
6. Wait for installation to complete

### Verify Installation

On your Ledger device:
1. Scroll through apps
2. You should see "SSH/PGP Agent"
3. Open it (press both buttons)
4. Screen should show "SSH/PGP Agent is ready"

**Status:** ✅ Complete when app is installed

---

## Step 4: Configure GPG with Ledger

Your Nix configuration automatically sets up GPG to use your Ledger for signing and encryption.

### Initialize Ledger GPG Agent

The hardware-security profile includes a launchd service that automatically starts `ledger-gpg-agent` on login. To start it manually:

```bash
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
```

### Generate/Import GPG Key on Ledger

The Ledger SSH/PGP Agent app generates keys based on your device's seed (24-word phrase). To get your GPG public key:

```bash
# Set GPG home directory
export GNUPGHOME=~/.gnupg-ledger

# Start agent if not running
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
sleep 2

# Get your public key
ledger-gpg-agent --homedir ~/.gnupg-ledger -v
```

The output will show your GPG key fingerprint. In this configuration, it's:
```
D2A7EC63E350CC488197CB2ED369B07E00FB233E
```

### Import Public Key to System

```bash
# Export public key
gpg --homedir ~/.gnupg-ledger --export --armor > ~/ledger-gpg-public.asc

# Import to system keyring (optional, for verification)
gpg --import ~/ledger-gpg-public.asc
```

### Test GPG Signing

```bash
# Ensure Ledger is unlocked and SSH/GPG Agent app is open
echo "test" | gpg --homedir ~/.gnupg-ledger --clearsign
```

The Ledger will display "Sign message" - press the button to confirm.

**Status:** ✅ Configured via `nix/profiles/hardware-security.nix`

---

## Step 5: Configure SSH with Ledger

Your Nix configuration includes two SSH agent options:

### Option 1: GPG Agent for SSH (Recommended)

Uses `gpg-agent` with SSH support (already configured):

```bash
# The hardware-security profile sets this automatically:
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
```

Get your SSH public key:

```bash
ssh-add -L
```

### Option 2: Ledger SSH Agent (Alternative)

Uses `ledger-agent` directly:

```bash
# The launchd service starts this automatically
# Or run manually:
ledger-agent -d ssh://ledger@localhost
```

Get your SSH public key:

```bash
ssh-add -L
```

### Add to GitHub/Servers

1. Copy your SSH public key: `ssh-add -L | pbcopy`
2. **GitHub:** Settings → SSH Keys → New SSH key
3. **Servers:** Add to `~/.ssh/authorized_keys`

### Test SSH Authentication

```bash
# Test GitHub
ssh -T git@github.com

# The Ledger will prompt for confirmation - press button
```

**Status:** ✅ Configured via `nix/profiles/hardware-security.nix`

---

## Step 6: Configure SOPS with Ledger GPG

SOPS (Secrets OPerationS) uses your Ledger GPG key for encrypting/decrypting secrets.

### SOPS Configuration

Your configuration includes (from `nix/modules/secrets/sops.nix`):

```nix
sops = {
  gnupg.home = "~/.gnupg-ledger";
  defaultSopsFile = ./nix/secrets/secrets.yaml;
};

environment.variables = {
  GNUPGHOME = "/Users/wikigen/.gnupg-ledger";
};
```

### SOPS Rules

The `.sops.yaml` file specifies your GPG key for encryption:

```yaml
creation_rules:
  - path_regex: .*\.(yaml|json|env|ini)$
    pgp: >-
      D2A7EC63E350CC488197CB2ED369B07E00FB233E
```

### Create Your First Secret

```bash
# Set GPG home
export GNUPGHOME=~/.gnupg-ledger

# Ensure ledger-gpg-agent is running
pgrep -f ledger-gpg-agent || \
  ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &

# Create/edit encrypted secret
sops nix/secrets/secrets.yaml
```

**What happens:**
1. SOPS contacts Ledger via `ledger-gpg-agent`
2. Ledger displays "Sign message"
3. Press button to confirm
4. Editor opens with decrypted content
5. Make changes and save
6. SOPS re-encrypts on save

### Use Secret in Nix

In your host configuration:

```nix
{
  # Declare a secret
  sops.secrets."example/api_key" = {};

  # Secret available at runtime:
  # /run/secrets/example/api_key
}
```

Rebuild your system:

```bash
darwin-rebuild switch --flake .#wikigen-mac
```

**Status:** ✅ Configured via `nix/modules/secrets/sops.nix`

---

## Quick Reference

### Environment Setup

```bash
# Add to ~/.zshrc for persistent config
export GNUPGHOME=~/.gnupg-ledger
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
export GPG_TTY=$(tty)
```

### Common Commands

```bash
# GPG
echo "test" | gpg --clearsign                    # Test GPG signing
gpg --list-keys                                  # List GPG keys

# SSH
ssh-add -L                                       # Show SSH public key
ssh -T git@github.com                            # Test GitHub SSH

# SOPS
sops nix/secrets/secrets.yaml                    # Edit secrets
sops -d nix/secrets/secrets.yaml                 # View secrets
sops -d --extract '["key"]' secrets.yaml         # Extract specific value

# Agents
pgrep -f ledger-gpg-agent                        # Check GPG agent
pgrep -f ledger-agent                            # Check SSH agent
ledger-gpg-agent --homedir ~/.gnupg-ledger -v    # Get GPG fingerprint
```

### File Locations

- **GPG keyring:** `~/.gnupg-ledger/`
- **GPG agent log:** `~/.local/share/ledger-gpg-agent.log`
- **SSH agent log:** `~/.local/share/ledger-ssh-agent.log`
- **SOPS config:** `.sops.yaml`
- **Secrets:** `nix/secrets/`
- **Decrypted secrets (runtime):** `/run/secrets/`

### Key Information

- **GPG Fingerprint:** `D2A7EC63E350CC488197CB2ED369B07E00FB233E`
- **Identity:** Luc Chartier <luc@distorted.media>
- **Algorithm:** ECDSA (NIST P-256)
- **Storage:** Ledger Nano S hardware wallet

---

## Troubleshooting

### Ledger Not Responding

**Checklist:**
- [ ] Ledger connected via USB
- [ ] Ledger unlocked (PIN entered)
- [ ] SSH/GPG Agent app is open on device
- [ ] Screen shows "SSH/GPG Agent is ready"
- [ ] Agent process is running

**Test:**
```bash
# Check agent is running
pgrep -f ledger-gpg-agent

# If not, start it
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
sleep 2

# Test GPG operation
echo "test" | gpg --homedir ~/.gnupg-ledger --clearsign
```

### "No GPG key found"

**Solution:**
```bash
# Ensure GNUPGHOME is set
export GNUPGHOME=~/.gnupg-ledger

# Verify key is visible
gpg --list-keys

# Should show: D2A7EC63E350CC488197CB2ED369B07E00FB233E
```

### "Failed to get data key" (SOPS)

**Solution:**
```bash
# Check .sops.yaml has correct fingerprint
cat .sops.yaml

# Verify fingerprint matches
gpg --list-keys --fingerprint

# Ensure agent is running
pgrep -f ledger-gpg-agent || \
  ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
```

### SSH Authentication Fails

**Solution:**
```bash
# Check SSH agent socket
echo $SSH_AUTH_SOCK

# Should be: /Users/wikigen/.gnupg-ledger/S.gpg-agent.ssh
# Or set it manually:
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# Verify key is loaded
ssh-add -L

# Test with verbose output
ssh -vT git@github.com
```

### Agent Crashes on Operation

**Solution:**
```bash
# Kill existing agents
killall ledger-gpg-agent
killall ledger-agent

# Check Ledger is ready
# 1. Ledger unlocked
# 2. SSH/GPG Agent app open
# 3. Screen shows "ready"

# Restart agent
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
sleep 2

# Check logs
tail -f ~/.local/share/ledger-gpg-agent.error.log
```

### SOPS Opens Wrong Editor

**Solution:**
```bash
# Set editor in ~/.zshrc
export EDITOR="nano"  # or "code --wait", "vim", etc.

# Or for single command
EDITOR=nano sops secrets.yaml
```

---

## Security Notes

### Hardware Security

- **Private keys never leave Ledger:** Only signs/decrypts on device
- **Physical confirmation required:** Must press button for every operation
- **No remote exploitation:** Can't decrypt without physical device
- **Recovery:** Keys derived from 24-word seed (keep secure!)

### Threat Model

**What Ledger protects against:**
- ✅ Key extraction from computer
- ✅ Malware stealing keys from disk
- ✅ Remote attacks on SSH/GPG keys
- ✅ Unauthorized signing/decryption

**What Ledger doesn't protect against:**
- ❌ Malware intercepting decrypted data in memory
- ❌ Physical theft of device (PIN provides basic protection)
- ❌ Compromise of device if seed phrase is leaked
- ❌ Side-channel attacks on device itself

### Operational Security

1. **Lock screen** when away from computer
2. **Remove Ledger** when not actively using it
3. **Never share** your 24-word recovery phrase
4. **Store seed phrase** in secure physical location
5. **Use unique PIN** - not shared with other devices
6. **Audit operations** via Git history (SOPS commits)
7. **Rotate secrets** if device is lost or compromised

### Backup Strategy

Your keys are derived from your 24-word recovery phrase:

1. **Primary backup:** Recovery phrase written on paper, stored securely
2. **Alternative access:** Consider a second Ledger restored from same seed
3. **Test recovery:** Periodically verify you can restore from seed
4. **SOPS multi-key:** Add additional GPG keys to `.sops.yaml` for team access

---

## Next Steps

Now that your Ledger is configured:

### SSH Authentication
- [ ] Add SSH public key to GitHub
- [ ] Add SSH public key to servers
- [ ] Test authentication: `ssh -T git@github.com`

### GPG Signing
- [ ] Configure git signing (already done in `hardware-security.nix`)
- [ ] Make a test commit to verify signing
- [ ] Add GPG public key to GitHub for verified commits

### SOPS Secrets
- [ ] Create first secret: `sops nix/secrets/secrets.yaml`
- [ ] Use secret in config: `sops.secrets."my-app/api-key" = {};`
- [ ] Rebuild system: `darwin-rebuild switch --flake .#wikigen-mac`
- [ ] Verify secret: `ls -l /run/secrets/`

### Advanced Usage
- [ ] Set up multi-user SOPS access
- [ ] Configure secret rotation procedures
- [ ] Add secrets for cloud deployments
- [ ] Integrate with CI/CD pipelines

---

## Related Documentation

- [Ledger Deep Dive](./ledger-overview.md) - Comprehensive hardware security guide
- [GPG Signing](./gpg-signing.md) - GPG configuration and commit signing
- [SSH Authentication](./ssh-authentication.md) - SSH with hardware wallet
- [SOPS Guide](../secrets-management/sops.md) - Complete SOPS documentation
- [Design Doc](../../architecture/design.md) - Overall Nix configuration architecture

---

## External References

- [Ledger SSH/GPG Agent](https://github.com/LedgerHQ/app-ssh-agent) - Official Ledger app
- [Trezor Agent](https://github.com/romanz/trezor-agent) - Agent software (supports Ledger)
- [SOPS](https://github.com/getsops/sops) - Secrets management
- [GPG Documentation](https://gnupg.org/documentation/) - GPG reference

---

Happy hardware security! 🔐
