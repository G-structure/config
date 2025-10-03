{ pkgs, system ? "x86_64-linux" }:

let
  # Starlight site directory
  siteDir = "site";

  # Development server script
  starlight-dev = pkgs.writeShellScript "starlight-dev" ''
    set -euo pipefail
    export PATH="${pkgs.nodejs_20}/bin:${pkgs.nodePackages.pnpm}/bin:$PATH"

    # Find the site directory (from PWD or git root)
    if [ -d "${siteDir}" ]; then
      cd "${siteDir}"
    elif [ -d "$PWD/${siteDir}" ]; then
      cd "$PWD/${siteDir}"
    else
      echo "❌ Error: Could not find ${siteDir} directory"
      echo "Please run this command from your Config repository root"
      exit 1
    fi

    # Install dependencies if node_modules doesn't exist
    if [ ! -d "node_modules" ]; then
      echo "📦 Installing dependencies..."
      pnpm install
    fi

    echo "🚀 Starting Starlight dev server..."
    echo "📝 Edit files in docs/ for live reload"
    exec pnpm dev
  '';

  # Build script
  starlight-build = pkgs.writeShellScript "starlight-build" ''
    set -euo pipefail
    export PATH="${pkgs.nodejs_20}/bin:${pkgs.nodePackages.pnpm}/bin:$PATH"

    # Find the site directory
    if [ -d "${siteDir}" ]; then
      cd "${siteDir}"
    elif [ -d "$PWD/${siteDir}" ]; then
      cd "$PWD/${siteDir}"
    else
      echo "❌ Error: Could not find ${siteDir} directory"
      exit 1
    fi

    # Install dependencies if node_modules doesn't exist
    if [ ! -d "node_modules" ]; then
      echo "📦 Installing dependencies..."
      pnpm install
    fi

    echo "🏗️ Building Starlight documentation site..."
    pnpm build
    echo "✅ Documentation built in $(pwd)/dist/"
  '';

  # Preview script
  starlight-preview = pkgs.writeShellScript "starlight-preview" ''
    set -euo pipefail
    export PATH="${pkgs.nodejs_20}/bin:${pkgs.nodePackages.pnpm}/bin:$PATH"

    # Find the site directory
    if [ -d "${siteDir}" ]; then
      cd "${siteDir}"
    elif [ -d "$PWD/${siteDir}" ]; then
      cd "$PWD/${siteDir}"
    else
      echo "❌ Error: Could not find ${siteDir} directory"
      exit 1
    fi

    # Check if build exists
    if [ ! -d "dist" ]; then
      echo "❌ No build found. Run 'nix run .#starlight-build' first."
      exit 1
    fi

    echo "👀 Starting preview server..."
    exec pnpm preview
  '';

in
{
  inherit starlight-dev starlight-build starlight-preview;

  # Build inputs for docs shell
  buildInputs = with pkgs; [
    nodejs_20
    nodePackages.npm
    nodePackages.pnpm
  ];

  # Shell hook for docs environment
  shellHook = ''
    echo "📚 Documentation Development Environment"
    echo ""
    echo "Commands:"
    echo "  cd site && pnpm dev     - Start Starlight dev server"
    echo "  cd site && pnpm build   - Build static site"
    echo "  cd site && pnpm preview - Preview built site"
    echo ""
    echo "Or use Nix apps:"
    echo "  nix run .#starlight-dev     - Start dev server"
    echo "  nix run .#starlight-build   - Build static site"
    echo "  nix run .#starlight-preview - Preview built site"
    echo ""
  '';

  # Apps for nix run commands
  apps = {
    starlight-dev = {
      type = "app";
      program = toString starlight-dev;
    };
    starlight-build = {
      type = "app";
      program = toString starlight-build;
    };
    starlight-preview = {
      type = "app";
      program = toString starlight-preview;
    };
  };
}
