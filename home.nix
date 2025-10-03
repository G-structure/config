{ pkgs, ... }:

{
  home.stateVersion = "24.11";

  # User packages
  home.packages = with pkgs; [
    # Container tools
    skopeo
    dive

    # Development tools
    jq
    yq

    # Cloud tools
    awscli2
    terraform
  ];

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      # Colima autostart
      if command -v colima &>/dev/null; then
        if ! colima status &>/dev/null; then
          echo "Starting Colima..."
          colima start --cpu 4 --memory 8 --disk 100
        fi
      fi
    '';
  };

  programs.git = {
    enable = true;
    userName = "wikigen";
    userEmail = "wikigen@example.com";  # Update this
  };
}
