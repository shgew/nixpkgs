#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-update

set -euo pipefail

project="here_forawhile/terminalphone"
api="https://gitlab.com/api/v4/projects/$(printf '%s' "$project" | sed 's|/|%2F|g')"

# Latest commit on default branch
read -r rev date < <(
  curl -fsSL "$api/repository/branches/main" \
    | jq -r '"\(.commit.id) \(.commit.committed_date)"'
)
date="${date%%T*}"

# Upstream uses CHANGELOG for version numbers; pick the last "Version X.Y.Z" entry
base=$(
  curl -fsSL "https://gitlab.com/${project}/-/raw/${rev}/CHANGELOG" \
    | grep -oE '^Version [0-9]+(\.[0-9]+)+' \
    | awk '{print $2}' \
    | tail -1
)

version="${base}-unstable-${date}"

nix-update terminalphone --version "$version"
