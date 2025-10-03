# WikiGen's home-manager configuration
{ config, pkgs, ... }:
{
  imports = [
    ../../nix/profiles/hardware-security.nix
  ];

  home.stateVersion = "24.11";

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = pkgs.lib.mkIf pkgs.stdenv.isDarwin {
      git = "ledger-agent wikigen@wikigens-MacBook-Pro -- git";
      ssh = "ledger-agent wikigen@wikigens-MacBook-Pro -- ssh";
    };
    initContent = ''
      # Colima autostart
      if command -v colima &>/dev/null; then
        if ! colima status &>/dev/null; then
          echo "Starting Colima..."
          colima start --cpu 4 --memory 8 --disk 100
        fi
      fi
    '';
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Luc Chartier";
    userEmail = "luc@distorted.media";
  };
}
