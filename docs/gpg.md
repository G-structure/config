# Ledger GPG Setup

This document describes how to use your Ledger hardware wallet for GPG signing.

## Overview

The Ledger device can be used for:
- GPG key generation and storage (keys never leave the device)
- Signing git commits
- Encrypting/decrypting messages
- SSH authentication (see [ssh.md](./ssh.md))

## Prerequisites

1. Ledger device with SSH/GPG Agent app installed (via Ledger Live)
2. `ledger-agent` package installed (included in this config)

## Setup

### 1. Initialize GPG Identity

Create your GPG key on the Ledger:

```bash
ledger-gpg init "Your Name <your.email@example.com>" --homedir ~/.gnupg-ledger
```

**Important Notes:**
- Use `--time=0` flag if you want to regenerate the exact same key later
- The keys are stored on the Ledger device and never exposed to your computer
- You can recover keys using your Ledger recovery seed

### 2. Export Public Key

```bash
gpg --homedir ~/.gnupg-ledger --armor --export your.email@example.com > ~/.gnupg-ledger/public.asc
```

### 3. Add to GitHub/GitLab

Copy your public key and add it to your Git hosting service:

```bash
cat ~/.gnupg-ledger/public.asc | pbcopy
```

Then add to:
- **GitHub**: Settings → SSH and GPG keys → New GPG key
- **GitLab**: Preferences → GPG Keys → Add new key

## Usage

### Starting the Agent

**IMPORTANT**: The `ledger-gpg-agent` must be running for signing to work:

```bash
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
```

The git configuration in this repo automatically starts the agent when needed, but you can manually start it as shown above.

### Manual Signing

Sign a message:

```bash
echo "test message" | gpg --homedir ~/.gnupg-ledger --clearsign
```

Sign a file:

```bash
gpg --homedir ~/.gnupg-ledger --sign file.txt
```

### Git Commit Signing

Git commit signing is configured automatically in `home.nix`:

```bash
# Commits are automatically signed
git commit -m "your message"

# Verify signature
git log --show-signature -1
```

Your Ledger will prompt you to confirm each signature on the device screen.

## Troubleshooting

### "No secret key" Error

If you see `gpg: skipped "KEYID": No secret key`, the agent isn't running:

1. Check if agent is running:
   ```bash
   pgrep -f "ledger-gpg-agent"
   ```

2. Start the agent manually:
   ```bash
   ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
   ```

3. Test signing:
   ```bash
   echo "test" | gpg --homedir ~/.gnupg-ledger -u KEYID --clearsign
   ```

### "End of file" Error

This means the agent started but can't communicate properly:

1. Kill all agents:
   ```bash
   killall ledger-gpg-agent gpg-agent
   ```

2. Ensure Ledger device has SSH/GPG Agent app open

3. Restart agent:
   ```bash
   ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
   ```

### Agent Not Daemonizing

The `--daemon` mode for `ledger-gpg-agent` has issues. Use `--server` mode instead and run in background with `&`.

## Key Management

### List Keys

```bash
gpg --homedir ~/.gnupg-ledger --list-keys
gpg --homedir ~/.gnupg-ledger --list-secret-keys
```

### Export Public Key

```bash
gpg --homedir ~/.gnupg-ledger --armor --export KEYID
```

### Key Location

- **Public keys**: `~/.gnupg-ledger/pubring.kbx`
- **Private keys**: Stored on Ledger device (never on computer)
- **Trust database**: `~/.gnupg-ledger/trustdb.gpg`

## Security Notes

1. **Hardware Protection**: Private keys never leave the Ledger device
2. **Recovery**: Keys can be recovered using your 24-word recovery seed
3. **Confirmation**: Every signing operation requires physical confirmation on the Ledger
4. **Separate Keyring**: Uses `~/.gnupg-ledger` to avoid conflicts with system GPG

## References

- [trezor-agent GPG Documentation](https://github.com/romanz/trezor-agent/blob/master/doc/README-GPG.md)
- [Ledger SSH/GPG Agent App](https://github.com/LedgerHQ/app-ssh-agent)
