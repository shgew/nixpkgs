#!/usr/bin/env nu

$env.NIXPKGS_ALLOW_UNFREE = "1"

let packages = open edited-packages.nuon
let platform = $nu.os-info.name
let to_update = ($packages | get $platform) ++ ($packages | get both)

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
