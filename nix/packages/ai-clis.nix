{ pkgs, lib }:

pkgs.buildNpmPackage {
  pname = "ai-clis";
  version = "1.0.0";

  src = ../../tools/js;

  npmDepsHash = "sha256-aSip2gUeEM3RRCszF8jvH9MX0X3dRbLW5C4dy+lsdpE=";

  dontNpmBuild = true;

  # Expose CLI binaries to $out/bin
  postInstall = ''
    mkdir -p $out/bin

    # Find and symlink all CLI binaries from node_modules/.bin
    if [ -d "$out/lib/node_modules/ai-cli-bundle/node_modules/.bin" ]; then
      for bin in "$out/lib/node_modules/ai-cli-bundle/node_modules/.bin"/*; do
        if [ -f "$bin" ] || [ -L "$bin" ]; then
          ln -s "$bin" "$out/bin/$(basename "$bin")"
        fi
      done
    fi
  '';

  meta = with lib; {
    description = "Bundle of pinned npm CLIs (Claude Code, MCP Inspector)";
    platforms = platforms.darwin ++ platforms.linux;
  };
}
