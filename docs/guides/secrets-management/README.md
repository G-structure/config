# Secrets Management

Secure secrets management with SOPS and hardware wallet encryption.

---

## Overview

This section covers secure secrets management using:
- **SOPS** (Secrets OPerationS) - Encrypted secrets in Git
- **Ledger GPG** - Hardware-backed encryption keys
- **Nix integration** - Declarative secrets deployment

All secrets are encrypted with your Ledger hardware wallet, ensuring keys never touch your computer.

---

## Documentation in This Section

### [SOPS Guide](./sops.md) ⭐
**Complete guide** to secrets management with SOPS and Ledger.

**Covers:**
- SOPS architecture and security model
- Setting up SOPS with Ledger GPG
- Creating and editing encrypted secrets
- Using secrets in Nix configurations
- Troubleshooting and best practices
- Advanced features (multi-key, rotation)

**Status:** ✅ Comprehensive guide

---

## Quick Start

### Prerequisites

- Ledger Nano S with GPG configured
- SOPS installed (included in config)
- GPG key initialized on Ledger

See [Ledger Setup](../hardware-security/ledger-setup.md) first.

### Create Your First Secret (2 minutes)

```bash
# 1. Set GPG home
export GNUPGHOME=~/.gnupg-ledger

# 2. Ensure agent running
pgrep -f ledger-gpg-agent || \
  ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &

# 3. Create encrypted secret
sops nix/secrets/secrets.yaml
```

SOPS will:
1. Decrypt using Ledger (button press required)
2. Open in your editor
3. Re-encrypt when you save

### Use Secret in Nix

```nix
# In your host config
{
  sops.secrets."myapp/api-key" = {};

  # Secret available at runtime:
  # /run/secrets/myapp/api-key
}
```

---

## Why SOPS?

### Benefits

✅ **Git-friendly** - Encrypted secrets safely committed
✅ **Hardware security** - Ledger GPG for encryption
✅ **Declarative** - Nix integration for deployment
✅ **Selective encryption** - Only values encrypted, keys readable
✅ **Multi-format** - YAML, JSON, ENV, INI, binary

### Security Model

```
┌─────────────────────────────────────────────────────────────┐
│                      SOPS Workflow                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Edit: sops secrets.yaml                                 │
│     ↓                                                       │
│  2. Decrypt with Ledger GPG                                 │
│     ↓                                                       │
│  3. Edit in memory (plaintext)                              │
│     ↓                                                       │
│  4. Save changes                                            │
│     ↓                                                       │
│  5. Re-encrypt with Ledger GPG                              │
│     ↓                                                       │
│  6. Safe to commit!                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Key Points:**
- Private key on Ledger (never on disk)
- Physical confirmation for every encrypt/decrypt
- Only encrypted data in Git
- Keys recoverable from Ledger seed phrase

---

## Architecture

### SOPS Configuration

**Flake input** (`flake.nix`):
```nix
inputs.sops-nix = {
  url = "github:Mic92/sops-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

**Module** (`nix/modules/secrets/sops.nix`):
```nix
{
  sops = {
    gnupg.home = "~/.gnupg-ledger";
    defaultSopsFile = ./nix/secrets/secrets.yaml;
  };

  environment.variables = {
    GNUPGHOME = "/Users/wikigen/.gnupg-ledger";
  };
}
```

**Rules** (`.sops.yaml`):
```yaml
creation_rules:
  - path_regex: .*\.(yaml|json|env|ini)$
    pgp: >-
      D2A7EC63E350CC488197CB2ED369B07E00FB233E
```

### File Structure

```
Config/
├── .sops.yaml                    # SOPS configuration
├── nix/
│   ├── modules/secrets/
│   │   └── sops.nix              # SOPS Nix module
│   └── secrets/
│       ├── README.md             # Usage docs
│       ├── secrets.yaml          # Encrypted secrets (safe for Git)
│       └── secrets.yaml.example  # Template
```

---

## Common Tasks

### Create Secret

```bash
# New secret file
sops nix/secrets/my-app.yaml
```

### Edit Secret

```bash
# Existing secret
sops nix/secrets/secrets.yaml
```

### View Secret

```bash
# Decrypt to stdout
sops -d nix/secrets/secrets.yaml

# Extract specific key
sops -d --extract '["api"]["key"]' nix/secrets/secrets.yaml
```

### Use in Nix

```nix
{
  # Declare secret
  sops.secrets."database/password" = {
    owner = "wikigen";
    mode = "0400";
  };

  # Use in service
  environment.variables = {
    DB_PASSWORD_FILE = config.sops.secrets."database/password".path;
  };
}
```

---

## Secret Formats

### YAML (Recommended)

```yaml
# Nested structure
database:
  host: localhost
  password: secret123

api:
  key: api-key-here
  endpoint: https://api.example.com
```

### JSON

```json
{
  "database": {
    "password": "secret123"
  },
  "api": {
    "key": "api-key-here"
  }
}
```

### ENV File

```bash
DATABASE_PASSWORD=secret123
API_KEY=api-key-here
```

### After Encryption

```yaml
database:
    host: ENC[AES256_GCM,data:bG9jYWxob3N0,iv:...]
    password: ENC[AES256_GCM,data:c2VjcmV0MTIz,iv:...]
sops:
    pgp:
        - fp: D2A7EC63E350CC488197CB2ED369B07E00FB233E
```

Note: Structure visible, values encrypted.

---

## Advanced Features

### Multiple GPG Keys

```yaml
# .sops.yaml
creation_rules:
  - path_regex: .*\.yaml$
    pgp: >-
      YOUR-KEY-HERE,
      TEAMMATE-KEY-HERE,
      CI-KEY-HERE
```

### Key Rotation

```bash
# Update .sops.yaml with new keys
# Then rotate all secrets
sops updatekeys nix/secrets/secrets.yaml
```

### Environment-Specific Secrets

```yaml
# .sops.yaml
creation_rules:
  # Development
  - path_regex: secrets/dev/.*\.yaml$
    pgp: DEV-KEY

  # Production
  - path_regex: secrets/prod/.*\.yaml$
    pgp: PROD-KEY
```

---

## Integration Examples

### Application Config

```nix
{
  # Declare secrets
  sops.secrets."myapp/config" = {};

  # Create config file referencing secret
  environment.etc."myapp/config.json".text = builtins.toJSON {
    api_key_file = config.sops.secrets."myapp/config".path;
  };
}
```

### Launchd Service

```nix
{
  sops.secrets."service/token" = {};

  launchd.user.agents.myservice = {
    config = {
      ProgramArguments = [
        "${pkgs.myapp}/bin/myapp"
        "--token-file"
        config.sops.secrets."service/token".path
      ];
    };
  };
}
```

### Environment Variables

```nix
{
  sops.secrets."aws/credentials" = {};

  home.sessionVariables = {
    AWS_CREDENTIALS_FILE = config.sops.secrets."aws/credentials".path;
  };
}
```

---

## Troubleshooting

### "No GPG key found"

```bash
# Set GPG home
export GNUPGHOME=~/.gnupg-ledger

# Verify key
gpg --list-keys

# Should show your key fingerprint
```

### "Failed to get data key"

```bash
# Check .sops.yaml has correct key
cat .sops.yaml

# Ensure agent running
pgrep -f ledger-gpg-agent || \
  ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &
```

### Ledger Not Responding

1. Unlock Ledger (enter PIN)
2. Open SSH/GPG Agent app
3. Verify screen shows "ready"
4. Restart agent if needed

See [SOPS Guide](./sops.md#troubleshooting) for details.

---

## Best Practices

### Secret Organization

```yaml
# Good: Clear hierarchy
environments:
  dev:
    database:
      password: xxx
    api:
      key: xxx
  prod:
    database:
      password: xxx
    api:
      key: xxx

# Avoid: Flat structure
dev_db_pw: xxx
prod_api_key: xxx
```

### Secret Rotation

1. Generate new secret value
2. Update in SOPS: `sops secrets.yaml`
3. Rebuild: `darwin-rebuild switch`
4. Verify new secret works
5. Revoke old secret in external system

### Backup Strategy

1. **Ledger seed** - 24-word phrase (offline storage)
2. **Alternative GPG key** - For team access
3. **Test recovery** - Periodically verify

---

## Related Documentation

### In This Section
- [SOPS Guide](./sops.md) - Complete SOPS documentation

### Other Sections
- [Ledger Setup](../hardware-security/ledger-setup.md) - Hardware wallet setup
- [GPG Signing](../hardware-security/gpg-signing.md) - GPG configuration
- [Structure Guide](../../architecture/structure.md) - Config architecture

---

## External Resources

- [SOPS GitHub](https://github.com/getsops/sops) - Official repository
- [sops-nix](https://github.com/Mic92/sops-nix) - NixOS integration
- [SOPS Usage Guide](https://github.com/getsops/sops#usage) - Official docs
- [Mozilla SOPS Blog](https://blog.mozilla.org/security/2015/08/11/managing-secrets-with-sops/) - Original announcement

---

**Ready to manage secrets?** Start with the [SOPS Guide](./sops.md)!
