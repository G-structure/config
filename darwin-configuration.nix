{ pkgs, self, ... }:

{
  # Basic system settings
  system.stateVersion = 5;

  # Set primary user for homebrew and other user-specific options
  system.primaryUser = "wikigen";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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
  ];

  # Homebrew for Colima (since it's macOS-specific)
  homebrew = {
    enable = true;
    brews = [
      "colima"
      "docker"
      "docker-compose"
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
