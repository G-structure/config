# Git Commit Signing with Ledger

This document describes how to sign git commits using your Ledger hardware wallet.

## Overview

Git commits in this configuration are automatically signed using GPG keys stored on your Ledger hardware wallet. This provides cryptographic proof that commits were created by you and haven't been tampered with.

## How It Works

1. **Hardware Key Storage**: Your GPG private key is stored on the Ledger device and never exposed to your computer
2. **Automatic Agent**: The `ledger-gpg-agent` is automatically started when you make a commit
3. **Device Confirmation**: Each commit requires physical confirmation on your Ledger device
4. **Signature Verification**: GitHub, GitLab, and other platforms can verify your signatures

## Setup (Already Configured)

The configuration in this repo has already set up:

- ✅ GPG key initialized on Ledger
- ✅ Git configured to sign commits automatically
- ✅ Wrapper script to manage the ledger-gpg-agent
- ✅ Both `gpg.program` and `gpg.openpgp.program` configured correctly

### Your GPG Key

- **Key ID**: `D2A7EC63E350CC488197CB2ED369B07E00FB233E`
- **Identity**: Luc Chartier <luc@distorted.media>
- **Key Type**: ECDSA (NIST P-256 curve)
- **Location**: `~/.gnupg-ledger/`

## Usage

### Making Signed Commits

Commits are signed automatically:

```bash
git add .
git commit -m "your commit message"
```

Your Ledger will display a signing request that you must approve by pressing the button on the device.

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

Show only the signature status:

```bash
git log --pretty=format:"%h %G? %s"
```

Legend:
- `G` = Good signature
- `B` = Bad signature
- `U` = Good signature, unknown validity
- `N` = No signature

## GitHub/GitLab Integration

### Adding Your Public Key

1. Export your public key:
   ```bash
   gpg --homedir ~/.gnupg-ledger --armor --export luc@distorted.media | pbcopy
   ```

2. Add to GitHub:
   - Go to Settings → SSH and GPG keys
   - Click "New GPG key"
   - Paste your public key
   - Click "Add GPG key"

3. Verify on GitHub:
   - Your commits will show a "Verified" badge
   - Click the badge to see signature details

### Signature Status on GitHub

- ✅ **Verified**: Signature valid, key trusted by GitHub
- ❓ **Unverified**: Signature valid but key not added to GitHub
- ❌ **Invalid**: Signature verification failed

## Troubleshooting

### Agent Not Running

If commits fail with "No secret key":

```bash
# Check if agent is running
pgrep -f ledger-gpg-agent

# Manually start agent if needed
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
```

The git wrapper should auto-start the agent, but you can start it manually if needed.

### Ledger Not Responding

1. Ensure the SSH/GPG Agent app is open on your Ledger
2. Unlock the Ledger with your PIN
3. The device screen should show "SSH/GPG Agent" when ready

### "End of file" Error

This means the agent can't communicate with the Ledger:

```bash
# Kill all agents and restart
killall ledger-gpg-agent gpg-agent
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
```

### Git Using Wrong GPG

If git isn't using the Ledger, check the configuration:

```bash
# Should show wrapper script path
git config --get gpg.program

# Should also show wrapper for openpgp
git config --get gpg.openpgp.program
```

Both should point to the `gpg-ledger` wrapper script, not directly to `/nix/store/.../gnupg-2.4.8/bin/gpg`.

## Configuration Details

### Git Configuration (in home.nix)

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

### The GPG Wrapper

The wrapper script:
1. Checks if `ledger-gpg-agent` is running
2. Starts the agent in `--server` mode if not running
3. Calls GPG with `--homedir ~/.gnupg-ledger` flag
4. Passes all arguments through to GPG

### Why Both `gpg.program` and `gpg.openpgp.program`?

Git checks `gpg.openpgp.program` first when `gpg.format=openpgp`, which Home Manager sets by default. We must override **both** to ensure our wrapper is always used.

## Security Benefits

1. **Hardware Protection**: Private key never leaves the Ledger device
2. **Physical Confirmation**: Every signature requires button press on device
3. **Non-Exportable**: Keys cannot be copied or stolen from the computer
4. **Recoverable**: Keys can be regenerated from your 24-word recovery seed
5. **Tamper-Proof**: Signatures prove commit authenticity and integrity

## Manual Signing

To sign a single commit without auto-signing:

```bash
# Disable auto-signing for this repo
git config commit.gpgsign false

# Sign a specific commit manually
git commit -S -m "manually signed commit"

# Or sign the last commit
git commit --amend -S --no-edit
```

## Key Management

### List Keys

```bash
gpg --homedir ~/.gnupg-ledger --list-keys
gpg --homedir ~/.gnupg-ledger --list-secret-keys
```

### Export Public Key

```bash
# To file
gpg --homedir ~/.gnupg-ledger --armor --export luc@distorted.media > public-key.asc

# To clipboard
gpg --homedir ~/.gnupg-ledger --armor --export luc@distorted.media | pbcopy
```

### Regenerate Key

If you need to regenerate the exact same key (using recovery seed):

```bash
ledger-gpg init "Luc Chartier <luc@distorted.media>" --time=0 --homedir ~/.gnupg-ledger
```

The `--time=0` flag ensures the timestamp is deterministic.

## Related Documentation

- [GPG Setup](./gpg.md) - General GPG configuration and usage
- [SSH Setup](./ssh.md) - SSH authentication with Ledger

## References

- [Git Commit Signing](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)
- [GitHub GPG Verification](https://docs.github.com/en/authentication/managing-commit-signature-verification)
- [trezor-agent Documentation](https://github.com/romanz/trezor-agent)
