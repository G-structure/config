# WikiGen's MacBook Pro configuration
{ config, pkgs, self, ... }:
{
  # Set primary user for homebrew and other user-specific options
  system.primaryUser = "wikigen";

  # User configuration
  users.users.wikigen = {
    name = "wikigen";
    home = "/Users/wikigen";
  };

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # AI CLI tools (Claude Code, MCP Inspector, etc.)
    self.packages.aarch64-darwin.ai-clis
  ];
}
