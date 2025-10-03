# Ledger Nano S Setup Guide: SOPS + age + SSH

**Goal:** Secure SSH authentication and SOPS secret management using your Ledger Nano S, all integrated with your Nix flake.

**Stack:**
- Hardware: Ledger Nano S
- SSH/GPG: `trezor-agent` (supports Ledger)
- Secrets: SOPS + age
- Platform: macOS with Nix/nix-darwin

---

## Prerequisites

- [ ] Ledger Nano S device
- [ ] USB cable
- [ ] macOS system with Nix installed

---

## Step 1: Install Software via Nix Flake

**What:** Add all required software to your Nix configuration: Ledger Live, trezor-agent, age, and SOPS.

**Actions:**

1. **Update your darwin-configuration.nix:**

   The following packages have been added to `/Users/wikigen/Config/darwin-configuration.nix`:
   ```nix
   # Hardware Security Tools (via Nix)
   trezor-agent  # Supports Ledger for SSH/GPG/age
   age           # Modern encryption tool
   sops          # Secret management

   # Homebrew casks (GUI apps)
   casks = [
     "ledger-live"  # GUI app for Ledger device management
   ];
   ```

   **Note:** Ledger Live is installed via Homebrew because it's not available for ARM Mac in nixpkgs.

2. **Rebuild your system:**
   ```bash
   cd /Users/wikigen/Config
   darwin-rebuild switch --flake .#wikigen-mac
   ```

3. **Verify installation:**
   ```bash
   # CLI tools (from Nix)
   which trezor-agent
   which age
   which sops

   # GUI app (from Homebrew)
   open -a "Ledger Live"
   ```

**Status:** ⏳ Ready to rebuild

---

## Step 2: Initialize Your Ledger Device

**What:** Set up your Ledger Nano S with PIN and recovery phrase.

**Actions:**

1. **Launch Ledger Live:**
   ```bash
   open -a "Ledger Live"
   ```

2. **Connect and initialize your Ledger Nano S:**
   - Connect via USB
   - Follow the on-screen setup:
     - Choose "Set up as new device"
     - **CRITICAL:** Write down your 24-word recovery phrase on paper
     - Store it in a safe place (NOT on your computer)
     - Set a PIN code (6-8 digits recommended)
     - Confirm your recovery phrase by entering words when prompted

3. **Update firmware (if prompted):**
   - Ledger Live will check for firmware updates
   - Install any available updates
   - This ensures compatibility with latest apps

**Status:** ⏳ Not started

---

## Step 3: Install SSH/GPG App on Ledger

**What:** The SSH/GPG app enables your Ledger to handle SSH authentication and GPG operations.

**Actions:**

1. **Enable Developer Mode in Ledger Live:**
   - Open Ledger Live
   - Click the gear icon (⚙️) in the top right for **Settings**
   - Navigate to **"Experimental features"** tab
   - Toggle **"Developer mode"** to ON
   - This reveals developer apps including SSH/PGP Agent

2. **Install the SSH/PGP Agent app:**
   - Navigate to **"Manager"** (left sidebar)
   - Connect and unlock your Ledger device (enter PIN)
   - Search for **"SSH/PGP Agent"** or **"SSH"**
   - Click **"Install"** button
   - Confirm on your Ledger device (press both buttons)
   - Wait for installation to complete

3. **Verify installation:**
   - On your Ledger device, scroll through apps
   - You should see "SSH/PGP Agent"
   - Open it (press both buttons) - should show "SSH/PGP Agent is ready"

**Status:** ⏳ Ready to install

---

## Step 3: Install trezor-agent and Dependencies via Nix

**What:** `trezor-agent` provides SSH/GPG/age operations for hardware wallets including Ledger. We'll add it to your Nix configuration.

**Actions:**

[TO BE COMPLETED]

**Status:** ⏳ Not started

---

## Step 4: Configure SSH with Ledger

**What:** Set up SSH authentication using your Ledger device.

**Actions:**

[TO BE COMPLETED]

**Status:** ⏳ Not started

---

## Step 5: Set Up age Encryption with Ledger

**What:** Configure age encryption to use your Ledger for secret management.

**Actions:**

[TO BE COMPLETED]

**Status:** ⏳ Not started

---

## Step 6: Configure SOPS with age

**What:** Integrate SOPS secret management with your age-encrypted Ledger identity.

**Actions:**

[TO BE COMPLETED]

**Status:** ⏳ Not started

---

## Quick Reference Commands

[TO BE COMPLETED]

---

## Troubleshooting

[TO BE COMPLETED]

---

## Security Notes

- **Recovery phrase:** Never store digitally, never photograph
- **PIN:** Required to unlock device
- **Physical security:** Keep device in secure location when not in use
- **Backup:** Consider purchasing a second Ledger for backup

---

## Next Steps After Setup

- [ ] Add SSH public key to GitHub/servers
- [ ] Encrypt first secret with SOPS
- [ ] Test decryption workflow
- [ ] Set up backup procedures
