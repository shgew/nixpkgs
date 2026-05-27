#!/usr/bin/env nu

$env.NIXPKGS_ALLOW_UNFREE = "1"

const maintainer = "shgew"

let external = open edited-packages.nuon
let platform = $nu.os-info.name
let external_pkgs = ($external | get $platform) ++ ($external | get both)

let maintained_pkgs = (
  ^rg -l -w $maintainer pkgs/by-name/
  | lines
  | each { |p| $p | path dirname | path basename }
  | uniq
)

let to_update = ($external_pkgs ++ $maintained_pkgs | uniq)

print $"Updating ($to_update | length) packages for ($platform) \(($external_pkgs | length) external, ($maintained_pkgs | length) maintained\)..."

for pkg in $to_update {
  print $"\n--- Updating ($pkg) ---"
  try {
    nix-update --commit --build -u $pkg
    print $"(ansi green)Successfully updated ($pkg)(ansi reset)"
  } catch {
    print $"(ansi red)Failed to update ($pkg)(ansi reset)"
  }
}
