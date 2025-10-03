# SOPS Secrets Management with Ledger

This directory contains encrypted secrets managed by [SOPS](https://github.com/getsops/sops) using your Ledger hardware wallet.

## Overview

- **Encryption**: Secrets are encrypted using your Ledger GPG key
- **Hardware Security**: Decryption requires physical confirmation on your Ledger device
- **Git Safe**: Encrypted secrets can be safely committed to Git
- **Key**: `D2A7EC63E350CC488197CB2ED369B07E00FB233E`

## Quick Start

### 1. Update flake inputs

```bash
nix flake update
```

### 2. Rebuild your system

```bash
darwin-rebuild switch --flake .#wikigen-mac
```

### 3. Verify SOPS can find your GPG key

```bash
# Set GPG home to Ledger keyring
export GNUPGHOME=~/.gnupg-ledger

# Start ledger-gpg-agent if not running
pgrep -f ledger-gpg-agent || ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &

# List GPG keys
gpg --list-keys
```

You should see your Ledger GPG key listed.

## Usage

### Creating a New Secret File

```bash
# Copy the example
cp nix/secrets/secrets.yaml.example nix/secrets/secrets.yaml

# Edit with SOPS (will encrypt automatically)
sops nix/secrets/secrets.yaml
```

**Important**: Your Ledger device will display a signing request. Press the button to confirm.

### Editing Encrypted Secrets

```bash
# SOPS will decrypt, open editor, then re-encrypt
sops nix/secrets/secrets.yaml
```

The file is decrypted in-memory only. When you save and exit, SOPS re-encrypts it.

### Viewing Encrypted Secrets

```bash
# Decrypt and print to stdout
sops -d nix/secrets/secrets.yaml
```

### Rotating Keys

If you need to change the encryption key:

```bash
# Update .sops.yaml with new key fingerprint
# Then rotate all secrets
sops updatekeys nix/secrets/secrets.yaml
```

## Using Secrets in Nix

### In darwin-configuration.nix

```nix
{
  # Declare a secret
  sops.secrets."example/api_key" = {
    # Optional: custom path
    # path = "/run/secrets/api_key";
  };

  # Use in a service or environment
  environment.variables = {
    API_KEY = config.sops.secrets."example/api_key".path;
  };
}
```

The secret will be decrypted at activation time and placed in `/run/secrets/`.

### In home-manager

```nix
{
  # Reference a secret in home configuration
  home.file.".config/app/config".text = ''
    api_key = ${config.sops.secrets."example/api_key".path}
  '';
}
```

## Troubleshooting

### "No GPG key found"

Ensure `GNUPGHOME` points to your Ledger keyring:

```bash
export GNUPGHOME=~/.gnupg-ledger
gpg --list-keys
```

### "End of file" or agent errors

The `ledger-gpg-agent` might not be running:

```bash
# Check if running
pgrep -f ledger-gpg-agent

# Start if needed
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &

# Wait 2 seconds for it to initialize
sleep 2

# Try SOPS again
sops nix/secrets/secrets.yaml
```

### Ledger not responding

1. Ensure Ledger is connected and unlocked
2. Open the "SSH/GPG Agent" app on the Ledger device
3. The screen should show "SSH/GPG Agent is ready"
4. Try the operation again

### "Failed to get the data key"

This means SOPS can't decrypt with your key. Check:

```bash
# Verify the key fingerprint in .sops.yaml matches your key
cat .sops.yaml

# List your keys
gpg --homedir ~/.gnupg-ledger --list-keys

# The fingerprints must match exactly
```

## Security Notes

- **Never commit unencrypted secrets**: Only commit `.yaml` files that SOPS has encrypted
- **Hardware confirmation**: Every encryption/decryption requires Ledger button press
- **Key backup**: Your key can be recovered using your Ledger's 24-word recovery phrase
- **Git safety**: The `.sops.yaml` configuration ensures secrets are always encrypted

## Files

- `secrets.yaml.example` - Template with example structure (not encrypted)
- `secrets.yaml` - Your actual secrets (encrypted, safe to commit)
- `.sops.yaml` (in repo root) - SOPS configuration specifying encryption keys

## References

- [SOPS Documentation](https://github.com/getsops/sops)
- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [Your Ledger Setup Guide](../../docs/ledger_setup_guide.md)
