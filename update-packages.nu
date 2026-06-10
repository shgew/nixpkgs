#!/usr/bin/env nu

$env.NIXPKGS_ALLOW_UNFREE = "1"

let nuon = open edited-packages.nuon
let platform = $nu.os-info.name
let to_update = ($nuon | get $platform) ++ ($nuon | get both)

print $"Updating ($to_update | length) packages for ($platform)..."

for pkg in $to_update {
  print $"\n--- Updating ($pkg) ---"
  try {
    nix-update --commit --build -u $pkg
    print $"(ansi green)Successfully updated ($pkg)(ansi reset)"
  } catch {
    print $"(ansi red)Failed to update ($pkg)(ansi reset)"
  }
}
