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

    # Ledger Hardware Security
    ledger-ssh-agent  # SSH agent for Ledger hardware wallets
    ledger-agent      # Ledger SSH/GPG agent from trezor-agent
  ];

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
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

  programs.git = {
    enable = true;
    userName = "wikigen";
    userEmail = "wikigen@example.com";  # Update this
  };

  # GPG configuration for Ledger OpenPGP card
  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      reader-port = "Ledger Token";
      allow-admin = true;
      enable-pinpad-varlen = true;
      disable-ccid = true;
      pcsc-shared = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry_mac;
  };

  # Shell environment for GPG/SSH
  home.sessionVariables = {
    GPG_TTY = "$(tty)";
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
  };
}
