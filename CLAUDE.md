# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Nixpkgs is a collection of over 120,000 software packages for the Nix package manager and NixOS Linux distribution. The repository uses a functional approach to package management with a sophisticated multi-stage bootstrapping system.

## Key Architecture Concepts

### Package Organization: `pkgs/by-name/` (Preferred)

New packages should be added to `pkgs/by-name/` using this structure:
```
pkgs/by-name/XY/xyz-package/package.nix
```
where `XY` is the lowercased 2-letter prefix of the package name.

Packages in this directory are automatically included without needing entries in `all-packages.nix`. The structure is validated by `nixpkgs-vet` in CI.

**Limitations:**
- Only for packages using `pkgs.callPackage` (not language-specific callPackages like `python3Packages.callPackage`)
- Only for top-level packages (not for nested package sets like `pythonPackages.*`)

### Standard Environment (stdenv)

All packages are built using `stdenv.mkDerivation`, which provides:
- Consistent build environment across platforms
- Standard build phases: `unpackPhase`, `patchPhase`, `configurePhase`, `buildPhase`, `checkPhase`, `installPhase`, `fixupPhase`
- Platform-specific implementations in `pkgs/stdenv/linux/`, `pkgs/stdenv/darwin/`, etc.

### Multi-Stage Bootstrapping

The package set is constructed as a fixed-point using `lib.fix` in `pkgs/top-level/stage.nix`, enabling:
- Self-referential package definitions
- Cross-compilation support via `pkgsBuildBuild`, `pkgsBuildHost`, `pkgsHostTarget`
- Overlay application in sequence

### Branch Structure

**Development branches:**
- `master` - Main development (unstable)
- `staging` - Accumulates changes causing mass rebuilds (1000+ packages)
- `staging-next` - Built by Hydra, tested before merging to master
- `release-YY.MM` - Stable releases (e.g., `release-24.11`)

**Staging workflow:**
```
staging → staging-next → master
         (manual)      (manual PR)
```

## Common Commands

### Building and Testing

```bash
# Build a package
nix-build -A package-name

# Enter development shell for a package
nix-shell '<nixpkgs>' -A package-name

# Review PR changes (recommended before submitting)
nix-shell -p nixpkgs-review --run "nixpkgs-review pr PR_NUMBER"

# Review local uncommitted changes
nix-shell -p nixpkgs-review --run "nixpkgs-review wip"

# Run NixOS tests
nix-build -A nixosTests.test-name

# Format code (enforced by CI)
nix fmt

# Validate pkgs/by-name structure
./ci/nixpkgs-vet.sh master

# Update all packages
nix-shell maintainers/scripts/update.nix

# Update specific package
nix-shell maintainers/scripts/update.nix --argstr package package-name
```

### Package Definition Template

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  # Dependencies automatically provided by callPackage
  dependency1,
  dependency2,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "package-name";  # Must be lowercase
  version = "1.2.3";       # Must start with digit; use "0-unstable-YYYY-MM-DD" for unreleased

  src = fetchFromGitHub {
    owner = "upstream";
    repo = "project";
    rev = "v${finalAttrs.version}";
    hash = "sha256-...";  # Get hash by building with fake hash first
  };

  buildInputs = [ dependency1 dependency2 ];

  doCheck = true;  # Enable tests if available

  passthru.tests = {
    # Custom tests
  };

  passthru.updateScript = nix-update-script { };  # Enable automatic updates

  meta = {
    description = "Short description";  # Capitalized, no article, no period
    homepage = "https://example.com";
    changelog = "https://example.com/changelog";
    license = lib.licenses.mit;         # Must match upstream
    maintainers = with lib.maintainers; [ username ];
    mainProgram = "binary-name";        # Name of primary executable
    platforms = lib.platforms.darwin;   # Or lib.platforms.linux, lib.platforms.all
  };
})
```

### Commit Conventions

```
package-name: 1.0.0 -> 2.0.0

Optional: Link to release notes or changelog
Optional: Additional context
```

**Rules:**
- Use lowercase package name
- No period at end of summary line
- Package-specific prefixes trigger automatic CI builds
- For maintainer additions: `maintainers: add handle`

### Getting Hash for Source Fetchers

Use a fake hash first, then copy the correct hash from the error:
```bash
nix-build -A package-name 2>&1 | grep "got:"
```

The error will show:
```
error: hash mismatch in fixed-output derivation:
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-R077sCvOAzrW1UcpUWWS7DBPnrkGwQ+nxH4V/lodui8=
```

## Pull Request Process

1. Fork and create feature branch from appropriate base (`master` for most changes, `staging` for mass rebuilds)
2. Make changes following conventions
3. Test locally with `nix-build -A package-name`
4. Test with `nixpkgs-review wip` if modifying existing packages
5. Format with `nix fmt`
6. Commit with conventional format
7. Push and create PR
8. Respond to CI checks (ofborg builds, GitHub Actions, nixpkgs-vet)
9. Address review comments

### Self-Merge for Maintainers

Maintainers can merge their own packages in `pkgs/by-name/` by commenting:
```
@NixOS/nixpkgs-merge-bot merge
```

Requirements:
- Package in `pkgs/by-name/`
- PR author is maintainer or has approval from maintainer
- All CI checks pass

## Important Files

### Entry Points
- `default.nix` - Top-level entry checking Nix version
- `pkgs/top-level/impure.nix` - Handles config and overlays
- `pkgs/top-level/stage.nix` - Bootstrapping and package set composition
- `pkgs/top-level/all-packages.nix` - Manual package definitions (27,000+ lines)
- `pkgs/top-level/by-name-overlay.nix` - Auto-imports `pkgs/by-name/` packages

### Package Definitions
- `pkgs/by-name/` - Modern name-based structure (preferred)
- `pkgs/applications/`, `pkgs/development/`, `pkgs/tools/` - Legacy category hierarchy
- `pkgs/build-support/` - Fetchers and builders
- `pkgs/stdenv/` - Standard environment implementations

### Documentation
- `CONTRIBUTING.md` - General contribution guidelines
- `pkgs/README.md` - Package-specific guidelines
- `pkgs/by-name/README.md` - by-name structure documentation

## Package Metadata Requirements

### Required Attributes
- `pname` - Package name (lowercase only)
- `version` - Must start with digit
- `src` - Source fetcher
- `meta.description` - Short description (capitalized, no article, no period)
- `meta.license` - Must match upstream license
- `meta.maintainers` - At least one maintainer for new packages

### Recommended Attributes
- `meta.mainProgram` - Primary executable name
- `meta.homepage` - Project homepage
- `meta.changelog` - Changelog URL
- `passthru.tests` - Automated tests
- `passthru.updateScript` - For automatic updates (use `nix-update-script`)
- `doCheck = true` - Enable upstream tests

## Security-Critical Packages

Packages in security-critical contexts require:
- Actively maintained upstream
- Responsible disclosure channels
- No known vulnerabilities
- Active committer among maintainers (for fast-moving packages like browsers)
- Unvendored security components
- Built from source (not binary blobs) when possible

## Testing Infrastructure

### Package Tests
```nix
# Built-in tests
doCheck = true;

# Post-install validation
doInstallCheck = true;

# Custom tests
passthru.tests = {
  simple = runCommand "${pname}-test" {} ''
    ${package}/bin/program --version
    touch $out
  '';
};
```

### NixOS Tests
Located in `nixos/tests/`, run with:
```bash
nix-build -A nixosTests.test-name
```

## Multiple Package Versions

For packages with multiple versions, use `inherit` to avoid triggering `pkgs/by-name` validation:
```nix
# all-packages.nix
inherit
  ({
    foo_1 = callPackage ../tools/foo/1.nix { };
    foo_2 = callPackage ../tools/foo/2.nix { };
  })
  foo_1
  foo_2
  ;
```

## CI/CD System

- **Hydra** - Official build farm (https://hydra.nixos.org/)
- **GitHub Actions** - PR checks, linting, evaluation
- **ofborg** - PR builder bot (triggered by commit prefixes)
- **nixpkgs-vet** - Validates `pkgs/by-name/` structure
- **nixpkgs-merge-bot** - Self-merge for maintainers

## Useful Patterns

### The callPackage Pattern
Dependencies are automatically provided based on function arguments:
```nix
# Package receives lib, stdenv, fetchurl automatically
{ lib, stdenv, fetchurl }:
stdenv.mkDerivation { ... }
```

### Multiple Outputs
Reduce closure size by splitting outputs:
```nix
outputs = [ "out" "dev" "doc" ];
```

### passthru for Sharing Data
```nix
passthru = {
  tests = { ... };
  updateScript = ./update.sh;
  inherit someInternalDep;
};
```

## Backporting

1. Merge to `master` first
2. Add `backport release-YY.MM` label
3. Or manually: `git cherry-pick -x <commit>` to release branch

Acceptable backports: security fixes, bug fixes, minor updates, major updates for security-critical apps
- I am a package maintainer (shgew). Add me to new packages I ask you to create.