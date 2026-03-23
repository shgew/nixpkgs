#!/usr/bin/env nu

$env.NIXPKGS_ALLOW_UNFREE = "1"

let packages = open edited-packages.nuon
let platform = if (uname | get kernel-name) == "Darwin" { "darwin" } else { "linux" }
let to_update = ($packages | get $platform) ++ ($packages | get both)

print $"Updating ($to_update | length) packages for ($platform)..."

$to_update | each {|pkg|
  print $"\n--- Updating ($pkg) ---"
  try {
    nix-update --commit --build -u $pkg
  } catch {
    print $"(ansi red)Failed to update ($pkg)(ansi reset)"
  }
}
