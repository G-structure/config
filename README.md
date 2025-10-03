1. Install Nix
```
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
```

2. Install Homebrew
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. First Install
```
mv ~/.zshrc ~/.zshrc.backup
sudo nix run nix-darwin -- switch --flake .#wikigen-mac
```

## Refrence
- [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)
- [Colima](https://github.com/abiosoft/colima)
- [ledger ssh + gpg agent](https://github.com/LedgerHQ/app-ssh-agent)
- [Hardware-based SSH/GPG/age agent](https://github.com/romanz/trezor-agent)
