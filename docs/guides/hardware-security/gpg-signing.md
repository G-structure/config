# GPG Signing with Ledger Hardware Wallet

This document describes how to use your Ledger hardware wallet for GPG signing, including git commit signatures, message signing, and file encryption.

---

## Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Your GPG Key](#your-gpg-key)
- [Git Commit Signing](#git-commit-signing)
- [Manual GPG Operations](#manual-gpg-operations)
- [GitHub/GitLab Integration](#githubgitlab-integration)
- [Agent Management](#agent-management)
- [Troubleshooting](#troubleshooting)
- [Key Management](#key-management)
- [Configuration Details](#configuration-details)
- [Security Benefits](#security-benefits)
- [Related Documentation](#related-documentation)

---

## Overview

The Ledger hardware wallet can be used for GPG operations:

- **GPG key generation and storage** - Keys never leave the device
- **Git commit signing** - Cryptographic proof of authorship
- **Message signing** - Sign any text or file
- **Encryption/decryption** - Secure message handling
- **SSH authentication** - See [SSH Authentication](./ssh-authentication.md)

All operations require **physical confirmation** on your Ledger device, providing hardware-level security.

---

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Commit Signing Flow                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  git commit                                                 │
│      │                                                      │
│      ▼                                                      │
│  gpg-ledger wrapper script                                  │
│      │                                                      │
│      ├─> Check if ledger-gpg-agent running                  │
│      │   If not: start agent                                │
│      │                                                      │
│      ▼                                                      │
│  gpg --homedir ~/.gnupg-ledger                              │
│      │                                                      │
│      ▼                                                      │
│  ledger-gpg-agent                                           │
│      │                                                      │
│      ▼                                                      │
│  Ledger device (sign with hardware key)                     │
│      │                                                      │
│      ▼                                                      │
│  User confirms on device                                    │
│      │                                                      │
│      ▼                                                      │
│  Signed commit                                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

1. **Ledger device** - Stores private key, performs signing operations
2. **ledger-gpg-agent** - Bridges GPG and Ledger device
3. **gpg-ledger wrapper** - Auto-manages agent lifecycle
4. **Git configuration** - Uses wrapper for all GPG operations

---

## Prerequisites

- [ ] Ledger Nano S device
- [ ] SSH/GPG Agent app installed on Ledger (via Ledger Live)
- [ ] `ledger-agent` package (included in this config)
- [ ] GPG key initialized on Ledger

If you haven't completed setup, see [Ledger Setup Guide](./ledger-setup.md).

---

## Your GPG Key

This configuration uses a GPG key stored on your Ledger:

- **Key ID**: `D2A7EC63E350CC488197CB2ED369B07E00FB233E`
- **Identity**: Luc Chartier <luc@distorted.media>
- **Algorithm**: ECDSA (NIST P-256 curve)
- **Key Location**: Ledger hardware wallet
- **Keyring**: `~/.gnupg-ledger/`

### Initialize GPG Identity (First Time)

If you need to initialize your GPG key on the Ledger:

```bash
ledger-gpg init "Your Name <your.email@example.com>" --homedir ~/.gnupg-ledger
```

**Important:**
- Use `--time=0` flag to regenerate the same key deterministically
- Keys are stored on Ledger and never exposed to computer
- Recoverable using your Ledger's 24-word recovery seed

### Export Public Key

```bash
# To file
gpg --homedir ~/.gnupg-ledger --armor --export luc@distorted.media > public-key.asc

# To clipboard (macOS)
gpg --homedir ~/.gnupg-ledger --armor --export luc@distorted.media | pbcopy
```

---

## Git Commit Signing

### Configuration (Already Set Up)

Your configuration automatically signs all commits:

✅ GPG key configured: `D2A7EC63E350CC488197CB2ED369B07E00FB233E`
✅ Sign by default: `true`
✅ Wrapper script: Auto-manages `ledger-gpg-agent`
✅ Both `gpg.program` and `gpg.openpgp.program` configured

Configuration in `nix/profiles/hardware-security.nix`:

```nix
programs.git = {
  signing = {
    key = "D2A7EC63E350CC488197CB2ED369B07E00FB233E";
    signByDefault = true;
  };

  extraConfig = {
    gpg = {
      program = "...gpg-ledger wrapper...";
      openpgp.program = "...gpg-ledger wrapper...";
    };
  };
};
```

### Making Signed Commits

Commits are **automatically signed**:

```bash
git add .
git commit -m "your commit message"
```

Your Ledger will:
1. Display "Sign message" on the screen
2. Wait for you to press the button to confirm
3. Complete the signature and return to git

### Verifying Signatures

Check the signature on the last commit:

```bash
git log --show-signature -1
```

Expected output:
```
gpg: Signature made Fri Oct  3 06:24:44 2025 PDT
gpg:                using ECDSA key D2A7EC63E350CC488197CB2ED369B07E00FB233E
gpg: Good signature from "Luc Chartier <luc@distorted.media>"
```

### Viewing Signed Commits

Show commits with signature info:

```bash
git log --show-signature
```

Show compact signature status:

```bash
git log --pretty=format:"%h %G? %s"
```

**Legend:**
- `G` = Good signature
- `B` = Bad signature
- `U` = Good signature, unknown validity
- `N` = No signature

### Manual Signing

To sign a specific commit without auto-signing:

```bash
# Disable auto-signing for this repo
git config commit.gpgsign false

# Sign a specific commit manually
git commit -S -m "manually signed commit"

# Or sign the last commit
git commit --amend -S --no-edit
```

---

## Manual GPG Operations

### Sign a Message

```bash
echo "test message" | gpg --homedir ~/.gnupg-ledger --clearsign
```

Output:
```
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA256

test message
-----BEGIN PGP SIGNATURE-----
...signature...
-----END PGP SIGNATURE-----
```

### Sign a File

```bash
gpg --homedir ~/.gnupg-ledger --sign file.txt
```

Creates `file.txt.gpg` (binary signature).

### Detached Signature

```bash
gpg --homedir ~/.gnupg-ledger --detach-sign file.txt
```

Creates `file.txt.sig` (separate signature file).

### Verify Signature

```bash
gpg --homedir ~/.gnupg-ledger --verify file.txt.sig file.txt
```

### Encrypt Message

```bash
echo "secret message" | gpg --homedir ~/.gnupg-ledger --encrypt --recipient luc@distorted.media
```

### Decrypt Message

```bash
gpg --homedir ~/.gnupg-ledger --decrypt encrypted.gpg
```

---

## GitHub/GitLab Integration

### Adding Your Public Key to GitHub

1. **Export your public key:**
   ```bash
   gpg --homedir ~/.gnupg-ledger --armor --export luc@distorted.media | pbcopy
   ```

2. **Add to GitHub:**
   - Go to **Settings → SSH and GPG keys**
   - Click **"New GPG key"**
   - Paste your public key
   - Click **"Add GPG key"**

3. **Verify on GitHub:**
   - Your commits will show a **"Verified"** badge
   - Click the badge to see signature details

### Adding to GitLab

1. Export public key (same as above)
2. Go to **Preferences → GPG Keys**
3. Click **"Add new key"**
4. Paste and save

### Signature Status

- ✅ **Verified**: Signature valid, key trusted by platform
- ❓ **Unverified**: Signature valid but key not added to platform
- ❌ **Invalid**: Signature verification failed

---

## Agent Management

### Starting the Agent

The git wrapper automatically starts the agent, but you can start it manually:

```bash
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
```

**Note:** Use `--server` mode (not `--daemon`). The `--daemon` mode has issues.

### Checking Agent Status

```bash
# Check if agent is running
pgrep -f ledger-gpg-agent

# View agent logs
tail -f ~/.local/share/ledger-gpg-agent.log
tail -f ~/.local/share/ledger-gpg-agent.error.log
```

### Stopping the Agent

```bash
# Kill all GPG agents
killall ledger-gpg-agent gpg-agent

# Or kill specific process
pkill -f "ledger-gpg-agent.*--homedir.*\.gnupg-ledger"
```

### Auto-Start on Login

The configuration includes a launchd service (macOS) that automatically starts `ledger-gpg-agent` on login:

```nix
# From nix/profiles/hardware-security.nix
launchd.agents.ledger-gpg-agent = {
  enable = true;
  config = {
    ProgramArguments = [ "...ledger-gpg-agent wrapper..." ];
    RunAtLoad = true;
  };
};
```

---

## Troubleshooting

### "No secret key" Error

**Problem:** Git commit fails with `gpg: skipped "KEYID": No secret key`

**Solution:**

1. Check if agent is running:
   ```bash
   pgrep -f ledger-gpg-agent
   ```

2. Start the agent manually:
   ```bash
   ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
   ```

3. Test signing:
   ```bash
   echo "test" | gpg --homedir ~/.gnupg-ledger --clearsign
   ```

### "End of file" Error

**Problem:** Agent starts but can't communicate with Ledger

**Solution:**

1. **Ensure Ledger is ready:**
   - Ledger unlocked (PIN entered)
   - SSH/GPG Agent app is open
   - Screen shows "SSH/GPG Agent is ready"

2. **Kill and restart agents:**
   ```bash
   killall ledger-gpg-agent gpg-agent
   ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
   ```

3. **Check logs:**
   ```bash
   tail -f ~/.local/share/ledger-gpg-agent.error.log
   ```

### Git Using Wrong GPG

**Problem:** Git isn't using the Ledger wrapper

**Solution:**

Check configuration:

```bash
# Should show wrapper script path, not direct gnupg path
git config --get gpg.program
git config --get gpg.openpgp.program
```

If wrong, rebuild your configuration:

```bash
darwin-rebuild switch --flake .#wikigen-mac
```

### Ledger Not Responding

**Checklist:**
- [ ] Ledger connected via USB
- [ ] Ledger unlocked (PIN entered)
- [ ] SSH/GPG Agent app is open on device
- [ ] Screen shows "SSH/GPG Agent is ready"
- [ ] Agent process is running (`pgrep -f ledger-gpg-agent`)

**Test:**
```bash
echo "test" | gpg --homedir ~/.gnupg-ledger --clearsign
```

### Agent Not Daemonizing

**Problem:** Agent doesn't stay in background

**Note:** The `--daemon` mode for `ledger-gpg-agent` has issues. Always use `--server` mode with `&`:

```bash
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
```

---

## Key Management

### List Keys

```bash
# List public keys
gpg --homedir ~/.gnupg-ledger --list-keys

# List secret keys (will show Ledger keys)
gpg --homedir ~/.gnupg-ledger --list-secret-keys

# Show key fingerprint
gpg --homedir ~/.gnupg-ledger --list-keys --fingerprint
```

### Export Public Key

```bash
# ASCII armored format
gpg --homedir ~/.gnupg-ledger --armor --export luc@distorted.media

# To file
gpg --homedir ~/.gnupg-ledger --armor --export luc@distorted.media > public-key.asc

# Specific key by ID
gpg --homedir ~/.gnupg-ledger --armor --export D2A7EC63E350CC488197CB2ED369B07E00FB233E
```

### Regenerate Key

If you need to regenerate the exact same key (using recovery seed):

```bash
ledger-gpg init "Luc Chartier <luc@distorted.media>" --time=0 --homedir ~/.gnupg-ledger
```

The `--time=0` flag ensures the timestamp is deterministic, producing the same key.

### Key Locations

- **Public keys**: `~/.gnupg-ledger/pubring.kbx`
- **Private keys**: Stored on Ledger device (never on computer)
- **Trust database**: `~/.gnupg-ledger/trustdb.gpg`
- **Agent socket**: `~/.gnupg-ledger/S.gpg-agent`

---

## Configuration Details

### The GPG Wrapper Script

Located in `nix/profiles/hardware-security.nix`, the wrapper:

1. Checks if `ledger-gpg-agent` is running
2. Starts the agent in `--server` mode if not running
3. Waits 2 seconds for agent to initialize
4. Calls GPG with `--homedir ~/.gnupg-ledger` flag
5. Passes all arguments through to GPG

```nix
pkgs.writeShellScript "gpg-ledger" ''
  # Ensure ledger-gpg-agent is running
  if ! pgrep -f "ledger-gpg-agent.*--homedir.*\.gnupg-ledger" > /dev/null; then
    PATH="${pkgs.gnupg}/bin:$PATH" ${pkgs.ledger-agent}/bin/ledger-gpg-agent \
      --homedir $HOME/.gnupg-ledger --server --verbose &
    sleep 2
  fi

  # Use --homedir flag instead of GNUPGHOME
  exec ${pkgs.gnupg}/bin/gpg --homedir $HOME/.gnupg-ledger "$@"
''
```

### Why Both gpg.program and gpg.openpgp.program?

Git checks `gpg.openpgp.program` first when `gpg.format=openpgp` (Home Manager default). We override **both** to ensure our wrapper is always used.

### Environment Variables

Set in `nix/profiles/hardware-security.nix`:

```nix
home.sessionVariables = {
  GPG_TTY = "$(tty)";
  SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
};
```

Also set system-wide (for SOPS) in `nix/modules/secrets/sops.nix`:

```nix
environment.variables = {
  GNUPGHOME = "/Users/wikigen/.gnupg-ledger";
};
```

---

## Security Benefits

### Hardware Protection

1. **Private key never leaves device** - Signing happens on Ledger
2. **Physical confirmation required** - Button press for every operation
3. **Non-exportable** - Keys cannot be copied or stolen from computer
4. **Tamper-proof** - Signatures prove commit authenticity and integrity

### Recovery

5. **Recoverable from seed** - Keys regenerated from 24-word recovery phrase
6. **Deterministic generation** - Same seed = same key (with `--time=0`)

### Operational Security

7. **Separate keyring** - Uses `~/.gnupg-ledger` to avoid conflicts
8. **Audit trail** - All signed commits visible in Git history
9. **Platform verification** - GitHub/GitLab verify signatures

### Threat Model

**What Ledger protects against:**
- ✅ Key extraction from computer
- ✅ Malware stealing keys from disk
- ✅ Unauthorized signing/commits
- ✅ Key theft via remote attacks

**What Ledger doesn't protect against:**
- ❌ Physical theft of device (PIN provides basic protection)
- ❌ Compromise if seed phrase is leaked
- ❌ Social engineering (tricking user to sign malicious commits)
- ❌ Side-channel attacks on device itself

---

## Related Documentation

- [Ledger Setup Guide](./ledger-setup.md) - Complete hardware wallet setup
- [Ledger Deep Dive](./ledger-overview.md) - Comprehensive hardware security guide
- [SSH Authentication](./ssh-authentication.md) - SSH with hardware wallet
- [SOPS Guide](../secrets-management/sops.md) - Secrets management with Ledger GPG
- [Architecture Overview](../../architecture/structure.md) - Configuration structure

---

## External References

- [Git Commit Signing](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work) - Official Git documentation
- [GitHub GPG Verification](https://docs.github.com/en/authentication/managing-commit-signature-verification) - GitHub docs
- [GitLab GPG Signatures](https://docs.gitlab.com/ee/user/project/repository/gpg_signed_commits/) - GitLab docs
- [trezor-agent GPG Documentation](https://github.com/romanz/trezor-agent/blob/master/doc/README-GPG.md) - Agent documentation
- [Ledger SSH/GPG Agent App](https://github.com/LedgerHQ/app-ssh-agent) - Ledger app source

---

## Quick Reference

### Common Commands

```bash
# Start agent
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &

# Check agent status
pgrep -f ledger-gpg-agent

# Make signed commit (automatic)
git commit -m "message"

# View signature
git log --show-signature -1

# Export public key
gpg --homedir ~/.gnupg-ledger --armor --export luc@distorted.media

# Test signing
echo "test" | gpg --homedir ~/.gnupg-ledger --clearsign

# List keys
gpg --homedir ~/.gnupg-ledger --list-keys

# Kill agents
killall ledger-gpg-agent gpg-agent
```

Happy signing! 🔐
