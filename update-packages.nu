#!/usr/bin/env nu

$env.NIXPKGS_ALLOW_UNFREE = "1"

const maintainer = "shgew"

let external = open edited-packages.nuon
let platform = $nu.os-info.name
let external_pkgs = ($external | get $platform) ++ ($external | get both)

let maintained_all = (
  ^rg -l -w $maintainer pkgs/by-name/
  | lines
  | each { |p| $p | path dirname | path basename }
  | uniq
)

# Drop packages not supported on this platform (meta.platforms / badPlatforms),
# even if maintained. tryEval skips non-existent or throwing attrs.
let names_nix = ($maintained_all | each { |n| $'"($n)"' } | str join " ")
let filter_expr = (
  'let pkgs = import <nixpkgs> { config.allowUnfree = true; }; lib = pkgs.lib; names = [ NAMES ]; isOk = n: (pkgs ? ${n}) && (let r = builtins.tryEval (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.${n}); in r.success && r.value); in builtins.filter isOk names'
  | str replace "NAMES" $names_nix
)
let maintained_pkgs = (nix eval --impure --json --expr $filter_expr | from json)
let dropped = (($maintained_all | length) - ($maintained_pkgs | length))

let to_update = ($external_pkgs ++ $maintained_pkgs | uniq)

print $"Updating ($to_update | length) packages for ($platform) \(($external_pkgs | length) external, ($maintained_pkgs | length) maintained, ($dropped) unsupported dropped\)..."

for pkg in $to_update {
  print $"\n--- Updating ($pkg) ---"
  try {
    nix-update --commit --build -u $pkg
    print $"(ansi green)Successfully updated ($pkg)(ansi reset)"
  } catch {
    print $"(ansi red)Failed to update ($pkg)(ansi reset)"
  }
}
