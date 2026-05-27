---
name: nixpkgs-add-package
description: Use when the user wants to add software to nixpkgs — phrases like "add a package", "create a package", "package X for nixpkgs", "write a nix derivation", "init a package", "package this Bash/Rust/Go/Python tool", or shares an upstream URL and asks for a derivation. Covers picking the right builder (stdenv / stdenvNoCC / buildRustPackage / buildGoModule / buildPythonApplication / buildNpmPackage), fetcher (fetchFromGitHub / GitLab / Gitea / fetchurl), wrapping scripts with runtime deps, modern idioms (finalAttrs, versionCheckHook, nix-update-script, longDescription, unstable date versions), and the build → vet → format loop. Strongly prefer this over recalling templates from memory — nixpkgs idioms change.
---

# Add a Package to nixpkgs

This skill is for landing a *new* package definition at `pkgs/by-name/<XX>/<name>/package.nix` and getting it to build cleanly. The user is `shgew`, a maintainer; default `meta.maintainers = with lib.maintainers; [ shgew ]` unless told otherwise.

## Operating principle: lean on tools, don't hand-type hashes

The slow way to write a derivation is to scaffold by hand with `lib.fakeHash` everywhere and re-run `nix-build` until each hash mismatch reveals the real value. The fast way is to let `nurl` and `nix-init` produce a correct fetcher block (or full derivation) in one shot, then edit. Reach for these *before* you start typing:

| Tool | When | What it does |
|------|------|--------------|
| `nix-init` | Starting from URL of GitHub/GitLab repo or release | Generates a full `package.nix` draft: picks builder, fills pname/version/src with real hashes, scaffolds meta. Saves ~10 minutes per package. |
| `nurl` | Already drafting; need just the `fetchFrom*` block | Prints the exact `fetchFromGitHub { … hash = "sha256-…"; }` (or other fetcher) with the real hash. |
| `nix-update <pkg>` | Updating existing pkg in this checkout | Bumps `version`, refetches src hash, refetches `cargoHash`/`vendorHash`/`npmDepsHash`. |
| `nix-prefetch-url` / `nix-prefetch-git` | Standalone tarball / unusual git source | Prefetch into the store and print SRI hash. |

Run with `nix run nixpkgs#<tool> -- <args>` if the binary isn't on PATH. Example:

```bash
nix run nixpkgs#nix-init -- --url https://github.com/owner/repo pkgs/by-name/re/repo/package.nix
nix run nixpkgs#nurl -- https://github.com/owner/repo v1.2.3   # prints fetcher block
```

Use these to dodge the fakeHash → rebuild → copy-paste loop entirely. Only fall back to `lib.fakeHash` when the source is in some odd location these tools don't understand.

## Step 1: Gather facts

Before any code, know:

1. **Attribute name** — lowercase, hyphen-separated. Becomes the file path and Nix attr.
2. **Upstream URL** — repo or release tarball.
3. **Latest tag/version** — check upstream releases. If upstream has no tagged releases, see "Unstable versioning" below.
4. **Build system** — Cargo (`Cargo.toml`) / Go modules (`go.mod`) / autotools / cmake / meson / Python (`pyproject.toml` or `setup.py`) / npm / pnpm / Bash script / other.
5. **License** — read upstream `LICENSE` and map to `lib.licenses.<attr>` (table below).
6. **Runtime dependencies** — for scripts and wrapped tools, every binary the program shells out to must be in `PATH` via a wrapper. For compiled tools, dynamic libs become `buildInputs`.

For nixpkgs attribute names of dependencies, use the NixOS MCP:

```
nix {"action":"search","type":"packages","query":"<name>"}
```

## Step 2: Choose the right builder

| Project shape | Builder |
|---------------|---------|
| Rust with `Cargo.lock` | `rustPlatform.buildRustPackage` |
| Go with `go.mod` | `buildGoModule` |
| Python CLI app (`pyproject.toml`) | `python3Packages.buildPythonApplication` |
| Python *library* | `python3Packages.buildPythonPackage` in `pkgs/development/python-modules/<name>/default.nix` (NOT `by-name`) |
| Node.js (npm) | `buildNpmPackage` |
| Node.js (pnpm) | `stdenv.mkDerivation` + `pnpm.fetchDeps` |
| C/C++ with autotools/cmake/meson | `stdenv.mkDerivation` |
| Bash/Perl/POSIX script, prebuilt binary, data-only | `stdenvNoCC.mkDerivation` |
| Single-file Python script (no build) | `stdenvNoCC.mkDerivation` (install + makeWrapper) |

`stdenvNoCC` is the "no C compiler" stdenv — use it any time there's nothing to compile. It's much lighter than full `stdenv`.

## Step 3: Path

```
pkgs/by-name/<XX>/<attr-name>/package.nix
```

`<XX>` = first two lowercase characters of the attr (`my-tool` → `my`, `7zip` → `7z`). No `all-packages.nix` entry needed — `pkgs/by-name` is auto-discovered.

## Step 4: Write the derivation

Always use the `finalAttrs` pattern (`builder (finalAttrs: { … })`). It lets `passthru`, overrides, and tag interpolation all see the same `version`. Reference upstream tag as `tag = finalAttrs.version;` when the tag is bare (`1.2.3`) or `tag = "v${finalAttrs.version}";` when prefixed. Use `rev = "<sha>";` only for commit pins (unstable versioning).

### Template: Rust

```nix
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  versionCheckHook,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "PNAME";
  version = "VERSION";

  src = fetchFromGitHub {
    owner = "OWNER";
    repo = "REPO";
    tag = "v${finalAttrs.version}";
    hash = "";
  };

  cargoHash = "";

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  passthru.updateScript = nix-update-script { };

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

For older Rust packages without `Cargo.lock` in the source archive, replace `cargoHash` with `cargoLock = { lockFile = ./Cargo.lock; };` and vendor the lockfile.

### Template: Go

```nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  versionCheckHook,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "PNAME";
  version = "VERSION";

  src = fetchFromGitHub {
    owner = "OWNER";
    repo = "REPO";
    tag = "v${finalAttrs.version}";
    hash = "";
  };

  vendorHash = "";

  ldflags = [
    "-s"
    "-w"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  passthru.updateScript = nix-update-script { };

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

If upstream vendors deps (has `vendor/`), use `vendorHash = null;`. The `-s -w` ldflags strip symbol tables for a smaller binary — standard for Go in nixpkgs.

### Template: Bash / POSIX script (stdenvNoCC + makeWrapper)

This is the right template whenever upstream is a single script (or a few scripts) that shells out to other tools. The wrapper puts every runtime dep on `PATH` so the user doesn't have to.

```nix
{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  bash,
  # runtime deps
  curl,
  jq,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "PNAME";
  version = "VERSION";

  src = fetchFromGitHub {
    owner = "OWNER";
    repo = "REPO";
    tag = "v${finalAttrs.version}";
    hash = "";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 PNAME.sh "$out/share/PNAME/PNAME.sh"
    install -Dm644 LICENSE -t "$out/share/doc/PNAME"
    install -Dm644 README.md -t "$out/share/doc/PNAME"

    makeWrapper ${lib.getExe bash} "$out/bin/PNAME" \
      --add-flags "$out/share/PNAME/PNAME.sh" \
      --prefix PATH : ${lib.makeBinPath [ curl jq ]}

    runHook postInstall
  '';

  meta = {
    description = "DESCRIPTION";
    homepage = "https://github.com/OWNER/REPO";
    license = lib.licenses.LICENSE;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "PNAME";
    platforms = lib.platforms.unix;
  };
})
```

Key moves:

- `stdenvNoCC` — nothing to compile.
- `dontConfigure = true; dontBuild = true;` — skip the phases there's nothing to do in.
- `runHook preInstall` / `runHook postInstall` — keeps the derivation overrideable.
- `lib.getExe bash` — preferred over `${bash}/bin/bash`.
- `lib.makeBinPath [ … ]` — turns a list of pkgs into a `:`-joined `bin/` path.
- For platform-specific runtime deps, use `lib.optionals stdenv.hostPlatform.isLinux [ … ]` inside the list.
- If the script hard-codes `$(dirname "$0")` for data dirs, patch it with `postPatch` using `substituteInPlace … --replace-fail OLD NEW` before install.

### Template: C/C++ (stdenv.mkDerivation)

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  # libs
  openssl,
  zlib,
  versionCheckHook,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "PNAME";
  version = "VERSION";

  src = fetchFromGitHub {
    owner = "OWNER";
    repo = "REPO";
    tag = "v${finalAttrs.version}";
    hash = "";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    openssl
    zlib
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "DESCRIPTION";
    homepage = "https://github.com/OWNER/REPO";
    license = lib.licenses.LICENSE;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "PNAME";
    platforms = lib.platforms.unix;
  };
})
```

For meson use `meson ninja` in `nativeBuildInputs`. For autotools-from-git use `autoreconfHook`. For a tarball that already has `./configure` checked in, the default phases work.

### Template: Python application

```nix
{
  lib,
  python3Packages,
  fetchFromGitHub,
  versionCheckHook,
  nix-update-script,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "PNAME";
  version = "VERSION";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "OWNER";
    repo = "REPO";
    tag = "v${finalAttrs.version}";
    hash = "";
  };

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "DESCRIPTION";
    homepage = "https://github.com/OWNER/REPO";
    license = lib.licenses.LICENSE;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "PNAME";
  };
})
```

Python *libraries* don't go here — they live under `pkgs/development/python-modules/<name>/default.nix` and use `buildPythonPackage`.

### Template: Node.js (npm)

```nix
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
}:

buildNpmPackage (finalAttrs: {
  pname = "PNAME";
  version = "VERSION";

  src = fetchFromGitHub {
    owner = "OWNER";
    repo = "REPO";
    tag = "v${finalAttrs.version}";
    hash = "";
  };

  npmDepsHash = "";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "DESCRIPTION";
    homepage = "https://github.com/OWNER/REPO";
    license = lib.licenses.LICENSE;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "PNAME";
  };
})
```

For pnpm projects use `stdenv.mkDerivation` plus `pnpm.fetchDeps` — different shape; check `pkgs/by-name/` for an existing pnpm package to copy from.

## Step 5: Fetcher selection

| Source | Fetcher | Required args |
|--------|---------|---------------|
| `github.com/x/y` | `fetchFromGitHub` | `owner`, `repo`, `tag` *(or `rev`)*, `hash` |
| `gitlab.com/x/y` | `fetchFromGitLab` | `owner`, `repo`, `tag`, `hash` |
| `codeberg.org`, `gitea.com`, self-hosted Gitea | `fetchFromGitea` | `domain`, `owner`, `repo`, `tag`, `hash` |
| Tarball at HTTP URL | `fetchurl` | `url`, `hash` |
| Plain git repo / submodule needed | `fetchgit` | `url`, `rev`, `hash`; optional `fetchSubmodules = true;` |
| GitHub with submodules | `fetchFromGitHub` + `fetchSubmodules = true;` | as above |

`tag` is the modern way to reference a release — it's a canonical alias that means "use this exact ref but verify it's a tag". Prefer it over `rev` for tagged releases.

## Step 6: Build, fill hashes, iterate

If `nix-init` left hashes empty (or you scaffolded by hand with `""`/`lib.fakeHash`):

```bash
nix-build -A <attr-name>
```

Nix reports the expected SRI hash. Paste it in, repeat for `cargoHash`/`vendorHash`/`npmDepsHash`. Order matters — source hash first, dependency hash next.

Typical build-failure fixes:

- **Missing native tool** → add to `nativeBuildInputs` (`pkg-config`, `cmake`, `ninja`, `autoreconfHook`).
- **Missing library** → add to `buildInputs`.
- **Tests fail unrelated to packaging** → `doCheck = false;` only as last resort; first try `checkFlags = [ "-skip=^TestX$" ];` (Go), `disabledTests = [ "test_x" ];` (Python).
- **Hard-coded `/usr/bin/env` / system paths** → `postPatch` with `substituteInPlace ... --replace-fail OLD NEW`. Use `--replace-fail` (not `--replace`) so a typo is loud.
- **Tool needs runtime deps at runtime** → wrap with `makeWrapper` (`--prefix PATH : ${lib.makeBinPath [ … ]}`).

## Step 7: Validate

Run all three, in order:

```bash
# 1. Build it.
nix-build -A <attr-name>

# 2. Smoke-test the binary.
./result/bin/<mainProgram> --version   # or --help

# 3. Run the nixpkgs structural lint (catches by-name layout mistakes, missing meta, etc.).
./ci/nixpkgs-vet.sh master
```

For non-trivial packages (lots of reverse deps, or you bumped a library): also

```bash
nix-shell -p nixpkgs-review --run "nixpkgs-review wip"
```

This builds your local changes plus every reverse dependency in the channel.

## Step 8: Format

`treefmt` runs nixfmt (the official nixpkgs formatter) and is enforced in CI:

```bash
nix-shell --run treefmt
# or:  nix fmt
```

Always do this before committing.

## Idioms reference

### Meta fields

- `description` — required. One short line. No trailing period. No "A tool that…" / "An app for…" prefix — start with a verb or noun.
- `longDescription` — optional multi-line paragraph for non-trivial software. Triple-quoted string.
- `homepage` — upstream URL.
- `changelog` — link to release notes for *this* version, interpolated with `${finalAttrs.version}`.
- `license` — `lib.licenses.<attr>`. Dual-licensed: `with lib.licenses; [ mit asl20 ]`.
- `maintainers` — `with lib.maintainers; [ shgew ]` by default (this user is a maintainer). For someone else, look up the handle in `maintainers/maintainer-list.nix`.
- `mainProgram` — name of the primary binary in `$out/bin/`. Required when the package ships an executable; lets `lib.getExe pkg` resolve.
- `platforms` — `lib.platforms.all`, `lib.platforms.unix`, `lib.platforms.linux`, `lib.platforms.darwin`. Omit if unsure — defaults to all.
- `sourceProvenance` — set when shipping a prebuilt binary (`with lib.sourceTypes; [ binaryNativeCode ]`) instead of building from source.

### Unstable versioning

When upstream has no tagged releases (only a branch), pin a commit and use the format `0-unstable-YYYY-MM-DD` (or `<last-tag>-unstable-YYYY-MM-DD`):

```nix
version = "1.1.6-unstable-2026-04-07";

src = fetchFromGitHub {
  owner = "owner";
  repo = "repo";
  rev = "e1d2512e8263de871232a338caa0e764ba1e3c2f";
  hash = "sha256-…";
};
```

The date is the commit date, not today's date. `rev` is the full 40-char SHA.

### Executables

- Inside a derivation: `lib.getExe pkg` over `"${pkg}/bin/name"`. `getExe` reads `meta.mainProgram` so it doesn't silently break on rename.
- For multiple binaries: `lib.getExe' pkg "tool-name"`.

### Patches

- `patches = [ ./fix-something.patch ];` — for `.patch` files in the same directory.
- `postPatch = '' substituteInPlace foo.sh --replace-fail OLD NEW ''` — for one-line tweaks.

### versionCheckHook

`nativeInstallCheckInputs = [ versionCheckHook ]; doInstallCheck = true;` runs `$out/bin/$mainProgram --version` after install and fails the build if the binary can't even start. Cheap, catches a class of bugs (broken wrappers, missing runtime libs) at build time. Use for any package with a CLI.

If `--version` isn't the right flag, override: `versionCheckProgramArg = "version";` (or `[ "version" ]`).

### nix-update-script

`passthru.updateScript = nix-update-script { };` lets nixpkgs maintainers (and `nix-update`) bump this package mechanically. Use on every new package that has a version.

### Shell completions

Many CLI tools ship completions for bash/zsh/fish. Install them via `installShellFiles`:

```nix
nativeBuildInputs = [ installShellFiles ];

postInstall = ''
  installManPage path/to/foo.1
  installShellCompletion --bash path/to/foo.bash
  installShellCompletion --zsh  path/to/_foo
  installShellCompletion --fish path/to/foo.fish
'';
```

For Rust/Go projects that *generate* completions at build time (`OUT_DIR`-style), point `installShellCompletion` at `$releaseDir/build/*/out/{foo.bash,foo.fish,_foo}` (Rust) or invoke the binary with a completion subcommand (Go: `$out/bin/foo completion bash > foo.bash`).

### Reproducible builds (build.rs / vergen / VCS metadata)

Some upstreams embed build-time git info (commit, build date) via `build.rs` + the `vergen` crate. Without a `.git` directory the build fails or produces a non-reproducible derivation. Fix by setting stable env values:

```nix
env.VERGEN_BUILD_DATE = "1970-01-01";
env.VERGEN_GIT_DESCRIBE = finalAttrs.version;
```

Same pattern applies to any tool that reads `$SOURCE_DATE_EPOCH`, embeds `git describe` output, or hard-codes build time.

### passthru.tests

When package behavior matters (not just "it built"), add a test. For NixOS-integration-style tests, point to a test in `nixos/tests/`. For lightweight checks, a `runCommand` that invokes the binary works.

### Common licenses

| SPDX | `lib.licenses.<attr>` |
|------|----------------------|
| MIT | `mit` |
| Apache-2.0 | `asl20` |
| GPL-3.0-only | `gpl3Only` |
| GPL-3.0-or-later | `gpl3Plus` |
| GPL-2.0-only | `gpl2Only` |
| GPL-2.0-or-later | `gpl2Plus` |
| LGPL-2.1-or-later | `lgpl21Plus` |
| LGPL-3.0-or-later | `lgpl3Plus` |
| BSD-2-Clause | `bsd2` |
| BSD-3-Clause | `bsd3` |
| MPL-2.0 | `mpl20` |
| ISC | `isc` |
| AGPL-3.0-or-later | `agpl3Plus` |
| Unlicense | `unlicense` |
| CC0-1.0 | `cc0` |
| Public Domain | `publicDomain` |

If unsure, check `lib/licenses.nix` for the full list.

## Commit message

```
<attr-name>: init at <version>
```

No trailing period. One commit per package. For unstable versions: `foo: init at 0-unstable-2026-05-27`.

## Checklist before opening PR

- [ ] `nix-build -A <attr>` succeeds clean
- [ ] All hashes are real, no `lib.fakeHash` / empty strings remaining
- [ ] `./result/bin/<mainProgram> --version` (or equivalent) prints something sane
- [ ] `meta.description` set; `meta.license` matches upstream; `meta.mainProgram` set for CLI tools
- [ ] `meta.maintainers` includes `shgew` (or the right handle)
- [ ] `passthru.updateScript = nix-update-script { };` set (unless explicitly N/A)
- [ ] `nix-shell --run treefmt` clean
- [ ] `./ci/nixpkgs-vet.sh master` passes
- [ ] For library / high-rebuild changes: `nixpkgs-review wip` clean
