---
title: "Hardware-backed PGP, SOPS, and SSH: Complete Guide"
---


A comprehensive guide to using hardware security keys (YubiKey, Nitrokey, Ledger, Trezor) for PGP signing/encryption, SSH authentication, and SOPS secret management — with a focus on Nix/NixOS integration and GitOps workflows.

---

## Contents

* [TL;DR Recommendations](#tldr-recommendations)
* [Threat Model & Security Roles](#threat-model--security-roles)
* [Part A: PGP for Humans](#part-a-pgp-for-humans)
* [Part B: SSH Authentication](#part-b-ssh-authentication)
* [Part C: SOPS + Age/KMS Secrets](#part-c-sops--agekms-secrets)
* [Part D: Hardware Key Selection Guide](#part-d-hardware-key-selection-guide)
* [Part E: Concrete Recipes](#part-e-concrete-recipes)
* [Backup, Rotation, and Recovery](#backup-rotation-and-recovery)
* [Decision Guide: Which Hardware Key](#decision-guide-which-hardware-key)
* [Trezor Agent vs Ledger SSH/PGP Agent](#trezor-agent-vs-ledger-sshpgp-agent)
* [Appendix: Additional References](#appendix-additional-references)

---

## TL;DR Recommendations

**SOPS/Secrets Management**
- Use `age` (not PGP) for SOPS by default
- Enroll hardware with `age-plugin-yubikey` for operator-held secrets
- Use cloud KMS (AWS/GCP) for machines/CI
- Keep GPG for human code signing and legacy mail
- References: [SOPS README](https://github.com/getsops/sops), [age-plugin-yubikey](https://github.com/str4d/age-plugin-yubikey), [Flux + SOPS](https://fluxcd.io/flux/guides/mozilla-sops/)

**SSH Authentication**
- Prefer OpenSSH FIDO2 resident keys on security keys (ed25519-sk + PIN + touch)
- Use OpenPGP or PIV only if you need smart-card semantics across toolchains
- References: [Yubico SSH + FIDO2](https://developers.yubico.com/SSH/Securing_SSH_with_FIDO2.html), [ssh-keygen manpage](https://man7.org/linux/man-pages/man1/ssh-keygen.1.html)

**Hardware Key Choice**
- **YubiKey 5/NFC**: best all-rounder (FIDO2, OpenPGP, PIV, broad docs); primary pick
  - [Yubico PGP Walk-Through](https://developers.yubico.com/PGP/PGP_Walk-Through.html)
  - [Yubico SSH + FIDO2](https://developers.yubico.com/SSH/Securing_SSH_with_FIDO2.html)
- **Open hardware**: Gnuk/FST-01 or Nitrokey (Start/Pro/3) if openness is non-negotiable
  - Slower ECC, fewer enterprise features, but OpenPGP works
  - [Gnuk docs](https://www.fsij.org/doc-gnuk/intro.html)
  - [Debian wiki: Gnuk](https://wiki.debian.org/GNUK)
  - [Nitrokey OpenPGP](https://docs.nitrokey.com/nitrokeys/features/openpgp-card/)
- **Ledger Nano**: has SSH/PGP agent app; workable but crypto-wallet-oriented
  - Prefer YubiKey for mainstream SSH/PGP
  - [Ledger Support](https://support.ledger.com/article/115005200649-zd)
  - [Ledger SSH blog](https://dud225.github.io/LedgerHQ.github.io/ssh-with-openpgp-card-app/)

---

## Threat Model & Security Roles

The fundamental security principle is to **separate concerns**:

- **Human keys**: PGP signing for code commits and email encryption
- **Machine/CI secrets**: SOPS decryption for automated systems
- **Access keys**: SSH authentication for server and Git access

Hardware tokens protect long-lived private keys by keeping them off disk and requiring physical presence. Cloud KMS protects machine-side decryption at scale, allowing automated systems to decrypt secrets under IAM/Service Account policies.

This separation ensures that:
- Stolen laptops cannot reveal signing keys
- Compromised CI systems cannot access human signing capabilities
- Machine credentials can be rotated without re-issuing developer keys

References: [SOPS README](https://github.com/getsops/sops), [Flux + SOPS](https://fluxcd.io/flux/guides/mozilla-sops/)

---

## Part A: PGP for Humans

### Key Architecture (Recommended)

The recommended PGP architecture separates certification from operational keys:

1. Create an offline **primary** PGP certificate for certification only
2. Generate three subkeys with specific roles:
   - **Sign (S)**: Code and document signing
   - **Encrypt (E)**: Email encryption
   - **Auth (A)**: SSH authentication (optional)
3. Load subkeys (S/E/A) onto a hardware card (YubiKey/Nitrokey/Gnuk)
4. Keep the primary offline/backup for revocation and key rotation

This design limits the blast radius if a hardware token is lost — you can revoke subkeys without invalidating your identity.

References: [Yubico PGP Walk-Through](https://developers.yubico.com/PGP/PGP_Walk-Through.html), [Nitrokey OpenPGP](https://docs.nitrokey.com/nitrokeys/features/openpgp-card/)

### Device Choice Notes

**YubiKey**
- Mature OpenPGP applet with touch policy support
- PIN/PUK protection with retry counters
- Full ECC and RSA support (RSA 2048/4096, Ed25519, NIST P-256/384)
- Integrates seamlessly with gpg-agent and SSH
- Reference: [Yubico PGP Walk-Through](https://developers.yubico.com/PGP/PGP_Walk-Through.html)

**Nitrokey/Gnuk**
- Open firmware, auditable security
- Supports standard OpenPGP card protocol
- Ideal for "free as in freedom" setups (Gnuk on FST-01/Start)
- Slower than proprietary solutions but transparent
- References: [Gnuk docs](https://www.fsij.org/doc-gnuk/intro.html), [Debian wiki: Gnuk](https://wiki.debian.org/GNUK)

**Ledger**
- OpenPGP/SSH agent app exists but not typical devops workflow
- Wallet-centric tooling with fewer SSH-specific docs
- Works but requires more manual configuration
- References: [Ledger Support](https://support.ledger.com/article/115005200649-zd), [Ledger SSH blog](https://dud225.github.io/LedgerHQ.github.io/ssh-with-openpgp-card-app/)

### On-device vs Off-device Generation

**Off-device generation (recommended for most users)**
- Generate subkeys on a secure computer
- Allows encrypted backups of key material
- Can restore to a second token if primary is lost
- More flexible for key rotation

**On-device generation**
- Private key never exists in plaintext outside the token
- Maximum security but no recovery without second token
- Must have backup token initialized identically
- Accept that losing both tokens means losing keys

Nitrokey documentation covers both flows comprehensively.

References: [Using Your YubiKey with OpenPGP](https://support.yubico.com/hc/en-us/articles/360013790259-Using-Your-YubiKey-with-OpenPGP), [Nitrokey on-device keygen](https://docs.nitrokey.com/nitrokeys/features/openpgp-card/openpgp-keygen-on-device)

### Minimal Commands (Sketch)

```bash
# Create primary + subkeys (sign/encrypt/auth), then move subkeys to card
gpg --full-generate-key
gpg --edit-key <KEYID> addkey   # Create S/E/A subkeys
gpg --edit-key <KEYID> key 1    # Select first subkey
gpg --edit-key <KEYID> keytocard # Move to OpenPGP card slot
# Repeat for keys 2 and 3

# Verify card status
gpg --card-status
```

Reference: [Yubico PGP Walk-Through](https://developers.yubico.com/PGP/PGP_Walk-Through.html)

---

## Part B: SSH Authentication

### FIDO2 Resident SSH Keys (Recommended)

Modern SSH authentication should use **FIDO2 resident keys** as the primary method:

**Why FIDO2?**
- Keys are generated **on** the security key hardware
- Require physical presence (touch) for each authentication
- Optional PIN for additional protection
- "Resident" mode stores private handle on token for portability
- Native OpenSSH support (no middleware required)
- Phishing-resistant by design

```bash
# Create resident FIDO2 SSH key with PIN+touch and store on the token
ssh-keygen -t ed25519-sk -O resident -O verify-required -C "me@host"

# macOS: Store handle in Keychain
ssh-add -K ~/.ssh/id_ed25519_sk

# Or use ssh-add -K -e as needed for key management
```

References: [Yubico SSH + FIDO2](https://developers.yubico.com/SSH/Securing_SSH_with_FIDO2.html), [ssh-keygen manpage](https://man7.org/linux/man-pages/man1/ssh-keygen.1.html)

### Alternatives (When FIDO2 Isn't Possible)

**OpenPGP auth subkey via gpg-agent**
- Classic approach using `gpg-agent --enable-ssh-support`
- Requires middleware between SSH client and hardware
- More brittle than native FIDO2
- Useful for cross-toolchain smart-card compatibility

**PIV via PKCS#11**
- Enterprise smart-card standard
- Broader compatibility with legacy systems
- More complex setup than FIDO2

Both alternatives work but add middleware complexity. Use FIDO2 unless you have specific compatibility requirements.

Reference: [Yubico PGP Walk-Through](https://developers.yubico.com/PGP/PGP_Walk-Through.html)

---

## Part C: SOPS + Age/KMS Secrets

### Why Age Over PGP for SOPS

SOPS (Secrets OPerationS) supports multiple encryption backends. The recommended approach uses **age** instead of PGP:

**Advantages of age**
- Simple recipient model (no keyring required)
- Native support in sops-nix
- Better performance than PGP
- Designed specifically for file encryption
- Easy to mix with cloud KMS for hybrid setups

**Recommended architecture**
- Human operators: age + hardware (YubiKey)
- Machines/CI: cloud KMS (AWS KMS or GCP Cloud KMS)
- Dev/staging: mix of both with appropriate access controls

References: [SOPS README](https://github.com/getsops/sops), [sops-nix README](https://github.com/Mic92/sops-nix), [Flux + SOPS](https://fluxcd.io/flux/guides/mozilla-sops/)

### Hardware-bound Age Recipients

The `age-plugin-yubikey` creates YubiKey-resident age identities, ensuring decryption requires the physical token:

```bash
# Install plugin and enroll a hardware identity
age-plugin-yubikey --generate | tee ~/.config/age/keys.txt

# Use the printed "age1yubikey..." recipient in .sops.yaml or via SOPS_AGE_RECIPIENTS
sops --encrypt --age <age1yubikey...> secrets.yaml > secrets.enc.yaml
```

This approach combines the convenience of age with the security of hardware-backed keys. Ideal for root secrets and bootstrap credentials.

Reference: [age-plugin-yubikey](https://github.com/str4d/age-plugin-yubikey)

### Deriving Age Recipients from SSH Keys

For convenience during initial setup, you can convert an existing Ed25519 SSH key to age format:

```bash
# Convert SSH key to age recipient
ssh-to-age < ~/.ssh/id_ed25519.pub

# Use in SOPS encryption
sops --encrypt --age $(ssh-to-age < ~/.ssh/id_ed25519.pub) secret.yaml > secret.enc.yaml
```

This is useful for bootstrap but consider migrating to hardware-backed keys for production secrets.

Reference: [sops-nix README](https://github.com/Mic92/sops-nix)

### Mixing KMS for Servers/CI

The real power comes from **hybrid encryption** — human operators use hardware tokens, machines use cloud KMS:

**Benefits**
- Developers can decrypt locally (with hardware token)
- CI/CD can decrypt autonomously (with IAM/Service Account)
- Flux/ArgoCD decrypt at apply time using pod identity
- Clear separation between human and machine access

**Example workflow**
1. Developer encrypts secret with both age (YubiKey) and AWS/GCP KMS
2. Developer can decrypt locally for debugging
3. CI pipeline can decrypt using machine credentials
4. GitOps operator decrypts in-cluster using KMS permissions

References: [Flux + SOPS](https://fluxcd.io/flux/guides/mozilla-sops/), [SOPS README](https://github.com/getsops/sops)

### Minimal sops-nix Module (NixOS)

```nix
{ config, lib, pkgs, ... }:
{
  imports = [ (builtins.fetchGit "https://github.com/Mic92/sops-nix")/modules/sops ];
  
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  
  # If using age hardware identities:
  sops.age.keyFile = "/var/lib/sops-nix/age-keys.txt";  # contains 'AGE-PLUGIN-YUBIKEY-...'
  
  # Example secret rendered at runtime:
  sops.secrets."app/env".path = "/run/secrets/app.env";
}
```

Reference: [sops-nix README](https://github.com/Mic92/sops-nix)

### Policy File for SOPS (Mix Hardware + KMS)

```yaml
# .sops.yaml
creation_rules:
  - path_regex: secrets/.*\.yaml
    encrypted_regex: '^(data|stringData)$'
    age: 
      - "age1yubikeyXXXXXXXX"        # Your YubiKey
      - "age1...coworker"             # Coworker's key
    kms:
      - "aws:arn:aws:kms:us-west-2:1234:key/abcd-..."
      - "gcp:projects/p/locations/l/keyRings/r/cryptoKeys/k"
```

This configuration enables:
- Multiple human operators with their own hardware keys
- AWS KMS for EC2/ECS/Lambda decryption
- GCP Cloud KMS for GCE/GKE/Cloud Run decryption
- Easy key rotation without re-encrypting everything

References: [Flux + SOPS](https://fluxcd.io/flux/guides/mozilla-sops/), [SOPS README](https://github.com/getsops/sops)

---

## Part D: Hardware Key Selection Guide

### YubiKey 5/NFC (Pragmatic Default)

**Pros**
- Best documentation and community support
- FIDO2 SSH native support
- OpenPGP and PIV applets
- Touch/tap policies for user presence
- PIN/PUK with secure retry counters
- Cross-OS tooling (Windows, macOS, Linux)
- Widely deployed in enterprise DevOps

**Cons**
- Closed hardware and firmware
- Proprietary manufacturing

**Best for**: Teams wanting "it just works" across SSH/FIDO2, PGP, and enterprise SSO.

References: [Yubico SSH + FIDO2](https://developers.yubico.com/SSH/Securing_SSH_with_FIDO2.html), [Yubico PGP Walk-Through](https://developers.yubico.com/PGP/PGP_Walk-Through.html)

### Nitrokey / Gnuk (Open Hardware/Firmware)

**Pros**
- Open source hardware and firmware
- Fully auditable security model
- Strong OpenPGP support (Start/Pro/3)
- On-device key generation
- Gnuk is completely free software

**Cons**
- Slower cryptographic operations
- Fewer enterprise integration features
- FIDO2 support varies by model
- Smaller support community

**Best for**: Organizations with strict open-source requirements and those prioritizing auditability over convenience.

References: [Nitrokey OpenPGP](https://docs.nitrokey.com/nitrokeys/features/openpgp-card/), [Nitrokey on-device keygen](https://docs.nitrokey.com/nitrokeys/features/openpgp-card/openpgp-keygen-on-device), [Gnuk docs](https://www.fsij.org/doc-gnuk/intro.html), [Debian wiki: Gnuk](https://wiki.debian.org/GNUK)

### SoloKeys

**Current Status**
- Focused primarily on FIDO2 authentication
- OpenPGP support exists but not mainstream
- Solo2 OpenPGP applet status should be verified before deployment
- Community-driven development with variable update cadence

**Best for**: FIDO2-only deployments; verify OpenPGP capabilities before adopting for PGP workflows.

Reference: [SoloKeys OpenPGP repo/status](https://github.com/solokeys/openpgp)

### Ledger Nano

**Capabilities**
- SSH/PGP agent app available
- Works if you already own one
- Firmware-level security model

**Limitations**
- Tooling and documentation thinner than YubiKey
- Crypto-wallet-centric design
- Less common in DevOps workflows
- Requires careful setup and testing

**Best for**: Users who already have a Ledger for cryptocurrency and want to add SSH/PGP capabilities.

References: [Ledger Support](https://support.ledger.com/article/115005200649-zd), [Ledger SSH blog](https://dud225.github.io/LedgerHQ.github.io/ssh-with-openpgp-card-app/)

---

## Part E: Concrete Recipes

### 1) FIDO2 SSH (Portable + Phishing-Resistant)

```bash
# Generate a hardware-backed resident SSH key (token holds the secret handle)
ssh-keygen -t ed25519-sk -O resident -O verify-required -C "me@laptop"

# Copy public key to servers/Git providers as usual
cat ~/.ssh/id_ed25519_sk.pub

# Use: key touch + (optional) PIN required on every auth
```

**What this enables**
- Physical key required for authentication
- No private key material on disk
- Portable across machines (resident key)
- Protection against credential phishing

References: [Yubico SSH + FIDO2](https://developers.yubico.com/SSH/Securing_SSH_with_FIDO2.html), [ssh-keygen manpage](https://man7.org/linux/man-pages/man1/ssh-keygen.1.html)

### 2) OpenPGP Subkeys on Card (Sign/Mail/Auth)

```bash
# Move S/E/A subkeys to card
gpg --edit-key <KEYID> key 1
gpg --edit-key <KEYID> keytocard  # repeat for each subkey slot

# Optional SSH via gpg-agent:
echo "enable-ssh-support" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

Reference: [Yubico PGP Walk-Through](https://developers.yubico.com/PGP/PGP_Walk-Through.html)

### 3) SOPS with Age + YubiKey + KMS

```bash
# Enroll YubiKey identity for age
age-plugin-yubikey --generate >> ~/.config/age/keys.txt

# Create/rotate a secret
sops --encrypt --age "$(age-plugin-yubikey --list | awk '{print $1}')" secret.yaml > secret.enc.yaml

# Add an AWS/GCP KMS recipient for machines in .sops.yaml (see above)
```

References: [age-plugin-yubikey](https://github.com/str4d/age-plugin-yubikey), [SOPS README](https://github.com/getsops/sops), [Flux + SOPS](https://fluxcd.io/flux/guides/mozilla-sops/)

### 4) NixOS Integration (sops-nix)

```nix
{
  imports = [ inputs.sops-nix.nixosModules.sops ];
  
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  
  # If using age hardware identities, point to the keys file on the node:
  sops.age.keyFile = "/var/lib/sops-nix/age-keys.txt";
  
  sops.secrets."db/password".path = "/run/secrets/db_password";
}
```

Reference: [sops-nix README](https://github.com/Mic92/sops-nix)

---

## Backup, Rotation, and Recovery

### Backup Strategy

**Hardware tokens** (recommended approach)
- Keep **two hardware tokens** initialized identically (primary + spare)
- Store spare in secure location (safe, safety deposit box)
- Test spare regularly to ensure it works

**PGP-specific**
- Export and print revocation certificate for primary key
- Store encrypted backup of primary key offline
- Document subkey fingerprints and creation dates
- Keep backup of public keyring

**Age/SOPS-specific**
- Backup age identities (encrypted) to secure storage
- Document all age recipients used in production
- Maintain KMS key policies in version control

### Rotation Strategy

**PGP subkeys**
- Rotate subkeys periodically (annually recommended)
- Set expiration dates on subkeys
- Primary key can re-issue subkeys without changing identity

**SOPS/Age secrets**
- Rotate age recipients and re-encrypt via policy
- Update .sops.yaml and run `sops updatekeys`
- Automated rotation for KMS keys via cloud provider lifecycle

**Cloud KMS**
- Enable automatic key rotation (AWS KMS: every year)
- Set key deletion window (30 days recommended)
- Monitor key usage via CloudTrail/Cloud Audit Logs

### Recovery Procedures

**Lost/stolen token**
1. Revoke compromised subkeys using primary certificate
2. Issue new subkeys to replacement token
3. Update authorized_keys on all servers
4. Re-encrypt SOPS secrets with new recipients
5. Rotate any passwords that were accessible

**Forgotten PIN**
1. Use PUK to reset PIN (limited attempts)
2. If PUK exhausted, initialize new token from backup
3. Update all systems with new public keys

References: [SOPS README](https://github.com/getsops/sops), [Nitrokey OpenPGP](https://docs.nitrokey.com/nitrokeys/features/openpgp-card/)

---

## Decision Guide: Which Hardware Key

### Quick Decision Tree

**Choose YubiKey 5/NFC if:**
- You want "it just works" across SSH/FIDO2 + PGP + enterprise SSO
- You need comprehensive documentation and tooling
- You're deploying to a team (consistency matters)
- You value broad compatibility over open firmware

**Choose Gnuk/Nitrokey if:**
- You require open hardware and firmware (auditable security)
- You can accept performance trade-offs
- You're in a strictly FOSS environment
- You need on-device key generation with transparency

**Choose Ledger Nano if:**
- You already own one and are comfortable with wallet-centric tooling
- You're willing to navigate less comprehensive DevOps documentation
- You want to consolidate crypto wallet and SSH/PGP on one device

**Choose Trezor + trezor-agent if:**
- You need multi-vendor support (Trezor, Ledger, KeepKey, Jade, OnlyKey)
- You want age encryption support in addition to SSH/GPG
- You're already using Trezor for cryptocurrency

### Comparison Matrix

| Feature | YubiKey | Nitrokey/Gnuk | Ledger | Trezor (+ agent) |
|---------|---------|---------------|--------|------------------|
| FIDO2 SSH | Native | Varies | Via app | Via agent |
| OpenPGP | Native | Native | Via app | Via agent |
| Age encryption | Via plugin | Via plugin | Limited | Via agent |
| Documentation | Excellent | Good | Limited | Good |
| Open hardware | No | Yes | No | Partially |
| DevOps focus | High | Medium | Low | Medium |

References: [Yubico PGP Walk-Through](https://developers.yubico.com/PGP/PGP_Walk-Through.html), [Yubico SSH + FIDO2](https://developers.yubico.com/SSH/Securing_SSH_with_FIDO2.html), [Gnuk docs](https://www.fsij.org/doc-gnuk/intro.html), [Ledger Support](https://support.ledger.com/article/115005200649-zd)

---

## Trezor Agent vs Ledger SSH/PGP Agent

### What Each Repo Is

**trezor-agent** ([romanz/trezor-agent](https://github.com/romanz/trezor-agent))
- Host-side agent + library for multiple hardware wallets
- Supports: Trezor, Ledger, KeepKey, Blockstream Jade, OnlyKey
- Provides SSH, GPG, and **age** key operations
- Private keys generated on and confined to device
- Well-documented with step-by-step guides

**LedgerHQ/app-ssh-agent** ([LedgerHQ/app-ssh-agent](https://github.com/LedgerHQ/app-ssh-agent))
- Firmware-side application for Ledger devices
- Supports: Ledger Blue, Nano S/X/S Plus/Stax
- Algorithms: P-256 (prime256v1) and ed25519
- Designed to work with host clients (recommends trezor-agent)
- More limited scope than trezor-agent

### What They Do (Capabilities & Workflow)

**trezor-agent capabilities**
- **SSH**: Hardware-backed SSH identities with button confirmation
- **GPG**: Sign and verify with device-resident keys
- **age**: Encrypt/decrypt using hardware-backed age identities
- **Design**: Private keys never leave token (see [DESIGN.md](https://github.com/romanz/trezor-agent/blob/master/doc/DESIGN.md))
- **Integration**: Works with standard OpenSSH, GnuPG, and age clients

**Ledger app-ssh-agent capabilities**
- **SSH public key extraction**: `getPublicKey.py` script
- **Agent mode**: Runs SSH/PGP agent for Ledger device
- **Approval**: Each operation requires Ledger confirmation
- **Recommendation**: Use with trezor-agent for "extra functionalities"

**Trezor official guide** ([SSH with Trezor](https://trezor.io/guides/bonus-tools/ssh-with-trezor))
- Password-less SSH authentication
- Secure copy (scp) with hardware keys
- Git over SSH with device-backed identities
- Also documents modern OpenSSH + FIDO2 paths (separate from agent flows)

### What They Enable (DevEx & Ops)

**Hardware-backed SSH for fleets**
- Device acts as SSH identity
- Button-press (and optional PIN) required for each auth
- Reduces key-exfiltration risk on laptops and CI jumpboxes
- Portable across machines with resident keys

**Hardware-backed code signing and email**
- GPG subkeys resident on token via trezor-agent
- Sign Git commits and packages with attestable provenance
- Email encryption with hardware-protected private keys

**Age secrets with a token**
- trezor-agent extends to age encryption
- Encrypt SOPS files to device-bound recipient
- Integrates cleanly with sops-nix or Flux GitOps
- README includes age docs and examples

**Multi-vendor flexibility**
- trezor-agent supports multiple device vendors
- Teams aren't locked to single hardware provider
- Consistent workflow across Trezor, Ledger, KeepKey, Jade, OnlyKey

### Nix/NixOS Integration

**trezor-agent packaging**
- Available in Homebrew: `brew install trezor-agent`
- Available in nixpkgs: `pkgs.trezor-agent`
- Easy to pin versions via flake for reproducible dev shells
- Works on macOS, Linux, and NixOS

**Ledger app packaging**
- Firmware + small host scripts
- No widely-used Nix package for device app
- For declarative Nix experience, use trezor-agent as host client
- Device app installed via Ledger Live

References: [Homebrew: trezor-agent](https://formulae.brew.sh/formula/trezor-agent), [MyNixOS: trezor-agent](https://mynixos.com/nixpkgs/package/trezor-agent)

### Quick Comparison

| Aspect | trezor-agent (host) | Ledger app-ssh-agent (device app) |
|--------|---------------------|-----------------------------------|
| Protocols | SSH, GPG, **age** | SSH, PGP |
| Devices | Trezor, Ledger, KeepKey, Jade, OnlyKey | Ledger (Blue, Nano S/X/S Plus/Stax) |
| Host client | n/a (it **is** the host) | Recommends trezor-agent for extra features |
| Key types | Device-dependent (Ed25519, P-256, etc.) | P-256 (prime256v1) and ed25519 |
| Packaging | Homebrew + nixpkgs | Build firmware; Python scripts; no common Nix package |
| Maintenance | Active development | Slower update cadence |

### Security Considerations

**Agent forwarding risk**
- Forwarding SSH agent to untrusted servers is dangerous
- Forwarded agent can sign challenges while connection active
- Keep `ForwardAgent=no` by default
- Use jump hosts only on trusted infrastructure
- Prefer short-lived forwarding sessions

**Local compromise considerations**
- Malware with local access can prompt device repeatedly
- Physical presence (button/touch) mitigates but doesn't eliminate risk
- User must verify what they're signing on device display
- Hardware tokens don't protect against social engineering

**Firmware/app supply chain**
- Keep device firmware updated from official sources
- Ledger app has some aging instructions (Python 2 mentions)
- Issues reported with ed25519 on certain host OS configurations
- Validate compatibility on your OS before production rollout

**Key type & compatibility**
- Ledger app supports prime256v1 and ed25519
- Older OpenSSH/GPG stacks may have curve restrictions
- Confirm server policy (e.g., ed25519-only environments)
- Test authentication before deploying to fleet

**Usability & maintenance**
- trezor-agent shows ongoing activity (recent age support, regular releases)
- Broad device coverage with consistent workflow
- Ledger agent repo has narrower scope and older open issues
- Plan for testing and fallback mechanisms

References: [SSH.com: ssh-agent protocol](https://www.ssh.com/academy/ssh/agent), [LedgerHQ/app-ssh-agent issues](https://github.com/LedgerHQ/app-ssh-agent/issues)

### Practical Usage

**Fast path (most flexible)**
1. Install trezor-agent on workstation or NixOS jump host
2. Register device-backed SSH public key (`ssh-add -L` when agent running)
3. Use for Git and host access
4. Optionally enable GPG signing and age decryption for SOPS

**Ledger-first path**
1. Install Ledger app on device via Ledger Live
2. Pair with trezor-agent as host client for better UX
3. Confirm curve policy (ed25519 or P-256) with servers
4. Test authentication flow end-to-end

**GitOps/Nix fit**
1. Pin trezor-agent via nixpkgs for reproducible dev shells
2. Use Homebrew for macOS teammates
3. Ensure CI runners have same agent version
4. Document device setup in team wiki

### Minimal Usage Sketches

**trezor-agent (host) — single SSH command**
```bash
# Run SSH command via device identity
trezor-agent [email protected] -- ssh [email protected]
```

Reference: [romanz/trezor-agent](https://github.com/romanz/trezor-agent)

**Ledger app — extract pubkey and run agent**
```bash
# Extract SSH public key
python getPublicKey.py  # prints ecdsa-sha2-nistp256 ... or ed25519 ...

# Start agent for that public key
python agent.py --key AAAA...
```

Reference: [LedgerHQ/app-ssh-agent](https://github.com/LedgerHQ/app-ssh-agent)

### Bottom Line

**Use trezor-agent if:**
- You want a single, well-documented host workflow
- You need SSH, GPG, **and** age support
- You want flexibility across multiple hardware vendors
- You prefer actively maintained tools with recent releases

**Use Ledger app-ssh-agent if:**
- You're Ledger-only and comfortable with limited scope
- You're okay with the maintenance cadence (older issues exist)
- You pair it with trezor-agent for richer features (as recommended by Ledger)

For most teams: **trezor-agent** provides the best balance of functionality, documentation, and multi-vendor support.

---

## Appendix: Additional References

### Detailed Guides and Walkthroughs

**sops-nix + age with concrete examples**
- [Stapelberg: sops-nix with age](https://michael.stapelberg.ch/posts/2025-08-24-secret-management-with-sops-nix/) — NixOS service integration
- [Major.io: Flux + age](https://major.io/p/encrypted-gitops-secrets-with-flux-and-age/) — GitOps encrypted secrets

**SoloKeys OpenPGP development**
- [SoloKeys OpenPGP repo](https://github.com/solokeys/openpgp) — Check current status before adoption
- Development evolves; verify compatibility before production use

### Community Resources

**NixOS Security**
- NixOS Wiki: Security best practices
- sops-nix GitHub: Issues and discussions
- age-plugin-yubikey: YubiKey-specific age integration

**Hardware Token Communities**
- Yubico Developer Portal: Comprehensive guides
- Nitrokey Documentation: Open-source focus
- Trezor Community: Multi-device agent discussions

### Tool Repositories

- [SOPS](https://github.com/getsops/sops) — Secrets OPerationS
- [age](https://github.com/FiloSottile/age) — Simple file encryption
- [age-plugin-yubikey](https://github.com/str4d/age-plugin-yubikey) — YubiKey plugin for age
- [sops-nix](https://github.com/Mic92/sops-nix) — NixOS integration
- [trezor-agent](https://github.com/romanz/trezor-agent) — Multi-device SSH/GPG/age agent
- [LedgerHQ/app-ssh-agent](https://github.com/LedgerHQ/app-ssh-agent) — Ledger SSH/PGP app
