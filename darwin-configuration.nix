{ pkgs, self, ... }:

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
