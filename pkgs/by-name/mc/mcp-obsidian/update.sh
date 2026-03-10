#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nodejs nix-update

set -euo pipefail

version=$(npm view @mauricio.wolff/mcp-obsidian version)

# Generate updated lock file
cd "$(dirname "${BASH_SOURCE[0]}")"
npm i --package-lock-only @mauricio.wolff/mcp-obsidian@"$version"
rm -f package.json

# Update version and hashes
cd -
nix-update mcp-obsidian --version "$version"
