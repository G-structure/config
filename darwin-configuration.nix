{ config, pkgs, self, ... }:

{
  # Basic system settings
  system.stateVersion = 5;

  # Set primary user for homebrew and other user-specific options
  system.primaryUser = "wikigen";

  # Allow unfree packages and unsupported systems
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # Disable nix-darwin's Nix management (using Determinate Nix)
  nix.enable = false;

  # SOPS secrets management
  # Uses Ledger GPG key for encryption/decryption
  sops = {
    # Set GNUPGHOME so SOPS can find the Ledger GPG key
    gnupg.home = "~/.gnupg-ledger";

    # Default secrets file (can be overridden per secret)
    defaultSopsFile = ./nix/secrets/secrets.yaml;
  };

  # Environment variables for SOPS/GPG
  environment.variables = {
    # Point SOPS to the Ledger GPG keyring
    GNUPGHOME = "${config.users.users.wikigen.home}/.gnupg-ledger";
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    # AI CLI tools (Claude Code, MCP Inspector, etc.)
    self.packages.aarch64-darwin.ai-clis

    # Hardware Security & Secrets Management
    gnupg              # GPG for OpenPGP card (Ledger)
    pinentry_mac       # macOS GUI for GPG PIN entry
    age                # Modern encryption tool
    ssh-to-age         # Convert SSH keys to age format
    sops               # Secret management
  ];

  # Homebrew for macOS-specific and GUI apps
  homebrew = {
    enable = true;
    brews = [
      "colima"
      "docker"
      "docker-compose"
    ];
    casks = [
      "ledger-live"  # GUI app for Ledger device management (not available in nixpkgs for ARM Mac)
    ];
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
  };

  # User configuration
  users.users.wikigen = {
    name = "wikigen";
    home = "/Users/wikigen";
  };
}
