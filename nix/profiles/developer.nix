# Developer tools profile
# Common development utilities
{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    # Data manipulation
    jq
    yq

    # File management
    tree

    # Build tools
    just
  ];
}
