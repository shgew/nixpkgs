#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nodejs nix-update curl gnutar

set -euo pipefail

pkg_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

version=$(npm view @mauricio.wolff/mcp-obsidian version)

# Generate package-lock.json from the published tarball's package.json so the
# lock matches the actual published artifact (including devDependencies).
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -sL "https://registry.npmjs.org/@mauricio.wolff/mcp-obsidian/-/mcp-obsidian-${version}.tgz" \
  | tar -xz -C "$tmp"
( cd "$tmp/package" && npm i --package-lock-only --ignore-scripts )
cp "$tmp/package/package-lock.json" "$pkg_dir/package-lock.json"

# Update version and hashes
nix-update mcp-obsidian --version "$version"
