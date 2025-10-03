final: prev: {
  # Override Python packages to enable ledger-agent on macOS
  python313Packages = prev.python313Packages.overrideScope (pyFinal: pyPrev: {
    ledger-agent = pyPrev.ledger-agent.overrideAttrs (oldAttrs: {
      meta = oldAttrs.meta // {
        platforms = prev.lib.platforms.unix;  # Enable for all Unix-like systems including macOS
      };
    });
  });

  # Override the top-level ledger-agent package
  ledger-agent = prev.ledger-agent.overrideAttrs (oldAttrs: {
    meta = oldAttrs.meta // {
      platforms = prev.lib.platforms.unix;
    };
  });
}
