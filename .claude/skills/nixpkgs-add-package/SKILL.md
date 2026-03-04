---
name: nixpkgs-add-package
description: Use when the user asks to "add a package", "create a package", "package X for nixpkgs", "write a nix package", "new package", or wants to add software to nixpkgs. Triggers on any request to create a new nixpkgs package definition.
---

# Add a Package to nixpkgs

## Step 1: Gather Information

Before writing anything, determine:

1. **Package name** — lowercase, hyphen-separated (e.g. `my-tool`). This becomes the Nix attribute name.
2. **Source location** — GitHub, GitLab, Codeberg, tarball URL, etc.
3. **Language/build system** — Rust (Cargo), Go (modules), C/C++ (autotools, cmake, meson), Python, Node.js, or other.
4. **Latest version** — check the upstream repository for the latest release tag.
5. **License** — check the upstream LICENSE file.

Use the GitHub MCP to inspect the upstream repository when it is on GitHub. Use the NixOS MCP (`mcp__nixos__nix`) with `action: "search"`, `type: "packages"` to find nixpkgs dependency attribute names.

## Step 2: Create Directory

Path is always:
```
pkgs/by-name/XX/package-name/package.nix
```
Where `XX` is the first two lowercase characters of the package name. No `all-packages.nix` entry needed — `pkgs/by-name` is auto-discovered.

## Step 3: Write package.nix

Choose the appropriate template. All use the `finalAttrs` pattern.

### Fetcher Selection

| Source | Fetcher | Key args |
|--------|---------|----------|
| GitHub | `fetchFromGitHub` | `owner`, `repo`, `tag`, `hash` |
| GitLab | `fetchFromGitLab` | `owner`, `repo`, `tag`, `hash` |
| Codeberg/Gitea | `fetchFromGitea` | `domain`, `owner`, `repo`, `tag`, `hash` |
| Direct URL | `fetchurl` | `url`, `hash` |
| Generic git | `fetchgit` | `url`, `rev`, `hash` |

Prefer `tag = finalAttrs.version;` when the upstream tag matches the version exactly, or `tag = "v${finalAttrs.version}";` when prefixed with `v`. Use `rev` only for commit SHAs.

### Template: Rust (Cargo)

```nix
{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "PNAME";
  version = "VERSION";

  src = fetchFromGitHub {
    owner = "OWNER";
    repo = "REPO";
    tag = "v${finalAttrs.version}";
    hash = lib.fakeHash;
  };

  cargoHash = lib.fakeHash;

  meta = {
    description = "DESCRIPTION";
    homepage = "https://github.com/OWNER/REPO";
    changelog = "https://github.com/OWNER/REPO/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.LICENSE;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "PNAME";
  };
})
```

### Template: Go

```nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "PNAME";
  version = "VERSION";

  src = fetchFromGitHub {
    owner = "OWNER";
    repo = "REPO";
    tag = "v${finalAttrs.version}";
    hash = lib.fakeHash;
  };

  vendorHash = lib.fakeHash;

  meta = {
    description = "DESCRIPTION";
    homepage = "https://github.com/OWNER/REPO";
    changelog = "https://github.com/OWNER/REPO/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.LICENSE;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "PNAME";
  };
})
```

If the project vendors dependencies (has a `vendor/` directory), use `vendorHash = null;`.

### Template: C/C++ (stdenv.mkDerivation)

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "PNAME";
  version = "VERSION";

  src = fetchFromGitHub {
    owner = "OWNER";
    repo = "REPO";
    tag = "v${finalAttrs.version}";
    hash = lib.fakeHash;
  };

  meta = {
    description = "DESCRIPTION";
    homepage = "https://github.com/OWNER/REPO";
    license = lib.licenses.LICENSE;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "PNAME";
    platforms = lib.platforms.all;
  };
})
```

Add `nativeBuildInputs` for build-time tools (cmake, meson, ninja, pkg-config, autoreconfHook) and `buildInputs` for libraries.

### Template: Node.js (npm)

```nix
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage (finalAttrs: {
  pname = "PNAME";
  version = "VERSION";

  src = fetchFromGitHub {
    owner = "OWNER";
    repo = "REPO";
    tag = "v${finalAttrs.version}";
    hash = lib.fakeHash;
  };

  npmDepsHash = lib.fakeHash;

  meta = {
    description = "DESCRIPTION";
    homepage = "https://github.com/OWNER/REPO";
    license = lib.licenses.LICENSE;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "PNAME";
  };
})
```

### Template: Python Application

Python *libraries* go in `python-modules/`, not `pkgs/by-name/`. Only standalone CLI tools use `pkgs/by-name/`.

```nix
{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "PNAME";
  version = "VERSION";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "OWNER";
    repo = "REPO";
    tag = "v${finalAttrs.version}";
    hash = lib.fakeHash;
  };

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
  ];

  meta = {
    description = "DESCRIPTION";
    homepage = "https://github.com/OWNER/REPO";
    license = lib.licenses.LICENSE;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "PNAME";
  };
})
```

## Step 4: Get Hashes

Start with `lib.fakeHash` for all hash fields, then build:

```bash
nix-build -A package-name
```

The build fails with a "hash mismatch" showing the correct hash. Replace `lib.fakeHash` with it. Repeat for each hash field (source hash first, then dependency hash like `cargoHash`/`vendorHash`/`npmDepsHash`).

## Step 5: Iterate Until It Builds

Common fixes:
- **Missing native build inputs** — add `pkg-config`, `cmake`, `meson`, `ninja` to `nativeBuildInputs`
- **Missing libraries** — add to `buildInputs`
- **Test failures** — use `doCheck = false;` as last resort; prefer fixing
- **Install issues** — override `installPhase` if the default doesn't work

## Step 6: Validate

```bash
./ci/nixpkgs-vet.sh master
```

## Meta Reference

- `description` — required. One line, no trailing period, no "A tool that..." prefix.
- `homepage` — upstream project URL.
- `changelog` — URL with `${finalAttrs.version}` interpolation.
- `license` — from `lib.licenses.*`. Dual: `with lib.licenses; [ mit asl20 ]`.
- `maintainers` — always `with lib.maintainers; [ shgew ]`.
- `mainProgram` — primary executable name. Set for all packages with binaries.
- `platforms` — e.g. `lib.platforms.all`, `lib.platforms.linux`. Omit if unsure.

### Common Licenses

| SPDX | Nix attribute |
|------|--------------|
| MIT | `mit` |
| Apache-2.0 | `asl20` |
| GPL-3.0-only | `gpl3Only` |
| GPL-3.0-or-later | `gpl3Plus` |
| GPL-2.0-only | `gpl2Only` |
| BSD-3-Clause | `bsd3` |
| BSD-2-Clause | `bsd2` |
| MPL-2.0 | `mpl20` |
| ISC | `isc` |
| AGPL-3.0-or-later | `agpl3Plus` |
| Unlicense | `unlicense` |

## Checklist

- [ ] Package builds with `nix-build -A package-name`
- [ ] All hashes are real (no `lib.fakeHash` remaining)
- [ ] `meta.description` is set and concise
- [ ] `meta.license` matches upstream
- [ ] `meta.maintainers` includes `shgew`
- [ ] `meta.mainProgram` is set (for packages with executables)
- [ ] `./ci/nixpkgs-vet.sh master` passes
