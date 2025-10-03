# SOPS Secret Management with Ledger

This guide explains how to use SOPS (Secrets OPerationS) for secure secret management in your Nix configuration, using your Ledger hardware wallet for encryption and decryption.

## Overview

**SOPS** is a tool for managing secrets in Git repositories. It encrypts files using GPG, age, or cloud KMS, allowing you to safely commit encrypted secrets to version control.

### Why SOPS?

- **Git-friendly**: Encrypted secrets can be safely committed to repositories
- **Hardware security**: Uses your Ledger GPG key for encryption/decryption
- **Declarative**: Integrates with Nix for reproducible secret deployment
- **Selective encryption**: Only encrypts values, not keys (readable structure)
- **Multi-format**: Supports YAML, JSON, ENV, INI, and binary files

### Security Model

In this configuration:
- **Encryption key**: Stored on Ledger hardware (never exposed to computer)
- **Physical confirmation**: Every decrypt operation requires Ledger button press
- **Git safety**: Only encrypted data is committed to repository
- **Backup**: Keys recoverable via Ledger's 24-word recovery phrase

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Your Workflow                        │
├─────────────────────────────────────────────────────────────┤
│  1. Edit secret: sops secrets.yaml                          │
│  2. SOPS decrypts using Ledger GPG key                      │
│  3. Opens in editor (plaintext in memory only)              │
│  4. You save changes                                        │
│  5. SOPS re-encrypts with Ledger GPG key                    │
│  6. Safe to commit encrypted file                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Encryption Flow                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Plain text secret                                          │
│         │                                                   │
│         ▼                                                   │
│    SOPS encrypts ──────> Ledger GPG signs                   │
│         │                     │                             │
│         │                     ▼                             │
│         │              [Confirm on device]                  │
│         │                     │                             │
│         ▼                     ▼                             │
│    Encrypted file (safe for Git)                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Setup (Already Configured)

Your Nix configuration includes:

### 1. Flake Inputs

```nix
inputs = {
  sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

### 2. Darwin Module

```nix
darwinConfigurations."wikigen-mac" = darwin.lib.darwinSystem {
  modules = [
    sops-nix.darwinModules.sops
    # ...
  ];
};
```

### 3. SOPS Configuration (nix/modules/secrets/sops.nix)

```nix
sops = {
  gnupg.home = "~/.gnupg-ledger";
  defaultSopsFile = ./nix/secrets/secrets.yaml;
};

environment.variables = {
  GNUPGHOME = "/Users/wikigen/.gnupg-ledger";
};
```

### 4. SOPS Rules (.sops.yaml)

```yaml
creation_rules:
  - path_regex: .*\.(yaml|json|env|ini)$
    pgp: >-
      D2A7EC63E350CC488197CB2ED369B07E00FB233E
```

## Directory Structure

```
Config/
├── .sops.yaml                          # SOPS configuration
├── nix/
│   └── secrets/
│       ├── README.md                   # Usage documentation
│       ├── secrets.yaml.example        # Template
│       ├── secrets.yaml                # Encrypted secrets (safe to commit)
│       └── test-secret.yaml            # Test file
└── docs/
    └── sops.md                         # This guide
```

## Usage

### Environment Setup

Before using SOPS, ensure your environment is configured:

```bash
# Set GPG home directory to Ledger keyring
export GNUPGHOME=/Users/wikigen/.gnupg-ledger

# Verify ledger-gpg-agent is running
pgrep -f ledger-gpg-agent

# If not running, start it:
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
```

**Pro tip**: Add to your `~/.zshrc`:
```bash
export GNUPGHOME=/Users/wikigen/.gnupg-ledger
```

### Creating a New Secret File

#### Method 1: From Example Template

```bash
# Copy the example
cp nix/secrets/secrets.yaml.example nix/secrets/my-secrets.yaml

# Edit and encrypt in one step
sops nix/secrets/my-secrets.yaml
```

#### Method 2: Create from Scratch

```bash
# SOPS will create an empty file, open editor, then encrypt
sops nix/secrets/my-secrets.yaml
```

**What happens:**
1. SOPS contacts your Ledger via `ledger-gpg-agent`
2. Ledger displays "Sign message"
3. Press button to confirm
4. Editor opens with decrypted content
5. Make your changes and save
6. SOPS re-encrypts on save

### Editing Encrypted Secrets

```bash
sops nix/secrets/secrets.yaml
```

SOPS will:
1. Decrypt the file (requires Ledger confirmation)
2. Open in your `$EDITOR` (defaults to `vim`)
3. Re-encrypt when you save and exit

### Viewing Secrets

```bash
# Decrypt and print to stdout
sops -d nix/secrets/secrets.yaml

# View specific key
sops -d --extract '["example"]["api_key"]' nix/secrets/secrets.yaml
```

### Different File Formats

```bash
# JSON
sops secrets.json

# Environment file
sops .env

# INI file
sops config.ini

# Binary file
sops --input-type binary --output-type binary secret.bin
```

### Encrypting an Existing File

```bash
# In-place encryption
sops --encrypt --in-place secrets.yaml

# Create encrypted copy
sops --encrypt secrets.yaml > secrets.enc.yaml
```

## Using Secrets in Nix

### Basic Secret Declaration

In your host configuration (e.g., `hosts/wikigen-mac.nix`):

```nix
{
  # Declare a secret
  sops.secrets."example/api_key" = {};

  # The secret will be available at:
  # /run/secrets/example/api_key
}
```

### Custom Secret Path

```nix
sops.secrets."example/api_key" = {
  path = "/run/secrets/my_api_key";
};
```

### Secret with Specific Owner/Mode

```nix
sops.secrets."database/password" = {
  owner = "wikigen";
  mode = "0400";  # Read-only for owner
};
```

### Using Secrets in Services

```nix
{
  # Declare the secret
  sops.secrets."app/jwt_secret" = {};

  # Reference in a launchd service
  launchd.user.agents.myapp = {
    config = {
      ProgramArguments = [
        "${pkgs.myapp}/bin/myapp"
        "--jwt-secret-file"
        config.sops.secrets."app/jwt_secret".path
      ];
    };
  };
}
```

### Using Secrets in Home Manager

In your user config (e.g., `home/users/wikigen.nix`):

```nix
{ config, ... }:
{
  # Create a config file with secret
  home.file.".config/myapp/config.json".text = builtins.toJSON {
    api_key_file = config.sops.secrets."example/api_key".path;
  };
}
```

### Environment Variables from Secrets

```nix
{
  sops.secrets."aws/credentials" = {};

  # Read secret content into environment
  environment.variables = {
    AWS_CREDENTIALS_FILE = config.sops.secrets."aws/credentials".path;
  };
}
```

## Secret File Format

SOPS supports nested YAML structures:

```yaml
# Development secrets
dev:
  database:
    host: localhost
    port: 5432
    password: dev_password_here
  api_key: dev_api_key_here

# Production secrets
prod:
  database:
    host: prod-db.example.com
    port: 5432
    password: prod_password_here
  api_key: prod_api_key_here

# AWS credentials
aws:
  access_key_id: AKIAIOSFODNN7EXAMPLE
  secret_access_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Application secrets
app:
  jwt_secret: super-secret-jwt-signing-key-32-bytes
  encryption_key: another-32-byte-encryption-key
```

**After encryption**, this becomes:

```yaml
dev:
    database:
        host: ENC[AES256_GCM,data:bG9jYWxob3N0,iv:...]
        port: ENC[AES256_GCM,data:NTQzMg==,iv:...]
        password: ENC[AES256_GCM,data:ZGV2X3Bhc3N3b3JkX2hlcmU=,iv:...]
    api_key: ENC[AES256_GCM,data:ZGV2X2FwaV9rZXlfaGVyZQ==,iv:...]
sops:
    pgp:
        - fp: D2A7EC63E350CC488197CB2ED369B07E00FB233E
    # ... metadata ...
```

Notice:
- **Structure is visible**: You can see keys and organization
- **Values are encrypted**: Actual secrets are protected
- **Git-diffable**: Changes show which values changed, not content

## Advanced Usage

### Multiple GPG Keys

To allow multiple people to decrypt secrets:

```yaml
# .sops.yaml
creation_rules:
  - path_regex: .*\.yaml$
    pgp: >-
      D2A7EC63E350CC488197CB2ED369B07E00FB233E,
      ANOTHERKEY1234567890ABCDEF1234567890ABCDEF
```

### Rotating Keys

If you need to change encryption keys:

```bash
# Update .sops.yaml with new key(s)
# Then rotate all secrets
sops updatekeys nix/secrets/secrets.yaml
```

This re-encrypts the file with the new key configuration.

### Different Keys for Different Files

```yaml
# .sops.yaml
creation_rules:
  # Development secrets
  - path_regex: secrets/dev/.*\.yaml$
    pgp: >-
      D2A7EC63E350CC488197CB2ED369B07E00FB233E

  # Production secrets (different key)
  - path_regex: secrets/prod/.*\.yaml$
    pgp: >-
      PRODUCTIONKEY1234567890ABCDEF1234567890AB
```

### Extracting Specific Keys

```bash
# Get a single value
sops -d --extract '["database"]["password"]' secrets.yaml

# Use in scripts
DB_PASSWORD=$(sops -d --extract '["database"]["password"]' secrets.yaml)
```

### Encrypting Specific Keys Only

```yaml
# .sops.yaml
creation_rules:
  - path_regex: config\.yaml$
    encrypted_regex: '^(password|api_key|secret)$'
```

Only keys matching the regex will be encrypted.

## Integration with Git

### What to Commit

✅ **DO commit:**
- `.sops.yaml` (configuration)
- Encrypted secret files (`secrets.yaml`)
- `nix/secrets/README.md`
- `nix/secrets/secrets.yaml.example`

❌ **DON'T commit:**
- Unencrypted secrets
- GPG private keys
- `secrets.yaml.example` with real secrets

### Git Configuration

Add to `.gitignore` if you have temporary unencrypted files:

```gitignore
# Temporary unencrypted secrets
*.dec.yaml
*.dec.json
*_decrypted.*
```

### Pre-commit Hook

To ensure secrets are always encrypted:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/getsops/sops
    rev: v3.8.1
    hooks:
      - id: sops-check
```

## Troubleshooting

### "No GPG key found"

**Problem**: SOPS can't find your Ledger GPG key.

**Solution**:
```bash
# Ensure GNUPGHOME points to Ledger keyring
export GNUPGHOME=/Users/wikigen/.gnupg-ledger

# Verify key is visible
gpg --list-keys

# Should show: D2A7EC63E350CC488197CB2ED369B07E00FB233E
```

### "Failed to get data key"

**Problem**: SOPS can't decrypt with your key.

**Solution**:
```bash
# Check .sops.yaml has correct key fingerprint
cat .sops.yaml

# Verify fingerprint matches your key
gpg --list-keys --fingerprint

# Ensure ledger-gpg-agent is running
pgrep -f ledger-gpg-agent || \
  ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
```

### "End of file" Error

**Problem**: Agent can't communicate with Ledger.

**Solution**:
1. Check Ledger is connected and unlocked
2. Open "SSH/GPG Agent" app on Ledger
3. Screen should show "SSH/GPG Agent is ready"
4. Restart agent:
   ```bash
   killall ledger-gpg-agent
   ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
   sleep 2
   ```

### "Could not decrypt"

**Problem**: File encrypted with different key.

**Solution**:
```bash
# Check which keys can decrypt the file
sops -d --verbose secrets.yaml

# Re-encrypt with your current key
sops updatekeys secrets.yaml
```

### Ledger Not Responding

**Checklist**:
- [ ] Ledger connected via USB
- [ ] Ledger unlocked (PIN entered)
- [ ] SSH/GPG Agent app is open on device
- [ ] Screen shows "SSH/GPG Agent is ready"
- [ ] `ledger-gpg-agent` process is running

**Test**:
```bash
# Try a simple GPG operation
echo "test" | gpg --clearsign
# Should prompt Ledger for confirmation
```

### SOPS Opens Wrong Editor

**Problem**: SOPS opens `vim` but you want a different editor.

**Solution**:
```bash
# Set editor in shell config (~/.zshrc)
export EDITOR="nano"  # or "code --wait", "emacs", etc.

# Or set for single command
EDITOR=nano sops secrets.yaml
```

## Best Practices

### Secret Organization

**Good structure**:
```yaml
# Group by environment and service
dev:
  database:
    password: xxx
  redis:
    password: xxx

prod:
  database:
    password: xxx
  redis:
    password: xxx
```

**Avoid**:
```yaml
# Flat, unclear structure
db_password: xxx
redis_pw: xxx
prod_db_password: xxx
```

### Secret Naming

- Use descriptive names: `database_password` not `dbpw`
- Include context: `prod/api_key` not just `key`
- Be consistent: `api_key` everywhere, not mixing with `apiKey`

### File Organization

```
nix/secrets/
├── common.yaml          # Shared across all environments
├── development.yaml     # Dev-only secrets
├── production.yaml      # Prod-only secrets
└── personal.yaml        # Your personal API keys
```

### Secret Rotation

1. Generate new secret value
2. Update in SOPS file: `sops secrets.yaml`
3. Rebuild system: `darwin-rebuild switch --flake .#wikigen-mac`
4. Verify new secret works
5. Revoke old secret in external system

### Backup Strategy

Your secrets are encrypted with your Ledger GPG key. To ensure access:

1. **Ledger backup**: Securely store your 24-word recovery phrase
2. **Alternative access**: Consider adding a second GPG key (different Ledger or software key)
3. **Test recovery**: Periodically verify you can recover keys from seed

## Security Notes

### Threat Model

**What SOPS protects against:**
- ✅ Secrets leaked in Git repository
- ✅ Secrets readable on disk
- ✅ Secrets accidentally committed to public repos

**What SOPS doesn't protect against:**
- ❌ Malware on your computer (can read decrypted secrets in memory)
- ❌ Physical access to running system (secrets in /run/secrets/)
- ❌ Compromise of Ledger device itself

### Hardware Security

- **Private key never leaves Ledger**: Only signs/decrypts on device
- **Physical confirmation required**: Must press button for every operation
- **No remote exploitation**: Can't decrypt without physical device
- **Recovery**: Keys derived from 24-word seed (keep secure!)

### Operational Security

1. **Lock your screen** when away from computer
2. **Remove Ledger** when not actively using SOPS
3. **Audit secret access** via Git history
4. **Rotate secrets** periodically
5. **Use unique secrets** per environment

## Quick Reference

### Common Commands

```bash
# Setup environment
export GNUPGHOME=/Users/wikigen/.gnupg-ledger

# Create/edit secret
sops secrets.yaml

# View secret
sops -d secrets.yaml

# Extract value
sops -d --extract '["key"]["subkey"]' secrets.yaml

# Encrypt existing file
sops --encrypt --in-place file.yaml

# Rotate keys
sops updatekeys secrets.yaml

# Check which keys can decrypt
sops -d --verbose secrets.yaml
```

### File Locations

- **Configuration**: `.sops.yaml`
- **Secrets directory**: `nix/secrets/`
- **GPG keyring**: `~/.gnupg-ledger/`
- **Agent logs**: `~/.local/share/ledger-gpg-agent.log`
- **Decrypted secrets**: `/run/secrets/` (runtime only)

### Key Information

- **Fingerprint**: `D2A7EC63E350CC488197CB2ED369B07E00FB233E`
- **Identity**: Luc Chartier <luc@distorted.media>
- **Algorithm**: ECDSA (NIST P-256)
- **Storage**: Ledger Nano S hardware wallet

## Related Documentation

- [Ledger Setup Guide](../hardware-security/ledger-setup.md) - Hardware wallet configuration
- [Ledger Deep Dive](../hardware-security/ledger-overview.md) - Comprehensive Ledger guide
- [GPG Signing](../hardware-security/gpg-signing.md) - GPG configuration and commit signing
- [Design Doc](../../architecture/design.md) - Overall Nix configuration architecture
- [Structure Guide](../../architecture/structure.md) - Modular configuration explained

## External References

- [SOPS GitHub](https://github.com/getsops/sops) - Official SOPS repository
- [sops-nix](https://github.com/Mic92/sops-nix) - NixOS integration
- [SOPS Guide](https://github.com/getsops/sops#usage) - Official usage guide
- [Mozilla SOPS](https://blog.mozilla.org/security/2015/08/11/managing-secrets-with-sops/) - Original announcement

## Next Steps

Now that SOPS is configured:

1. **Create your first real secret**:
   ```bash
   sops nix/secrets/secrets.yaml
   ```

2. **Use it in your config**:
   ```nix
   sops.secrets."my-app/api-key" = {};
   ```

3. **Rebuild your system**:
   ```bash
   darwin-rebuild switch --flake .#wikigen-mac
   ```

4. **Verify secret is available**:
   ```bash
   ls -l /run/secrets/
   ```

Happy secret managing! 🔐
