# Repository Guidelines

## Project Structure & Module Organization
- `pkgs/`: package definitions. Prefer `pkgs/by-name/<2-letter-prefix>/<pkg>/package.nix`; legacy category directories still exist.
- `nixos/`: NixOS modules, integration tests, and release-note content.
- `lib/`: shared Nix library functions.
- `doc/`: Nixpkgs manual sources and documentation tooling.
- `maintainers/`: maintainer metadata and helper scripts.
- `ci/`: CI/evaluation helpers.

Keep changes tightly scoped to one area whenever possible.

## Build, Test, and Development Commands
- `nix-build -A <attrPath>`: build a package or attribute (for example, `nix-build -A hello`).
- `nix-shell --run treefmt` (or `nix develop --command treefmt`, `nix fmt`): format Nix files using the CI-enforced formatter.
- `nix-shell -p nixpkgs-review --run "nixpkgs-review wip"`: test local changes plus impacted reverse dependencies.
- `nix-build --attr pkgs.<pkg>.passthru.tests`: run package-level tests.
- `nix-build --attr nixosTests.<name>`: run a NixOS test.
- `sudo nixos-rebuild test -I nixpkgs=$PWD --fast`: smoke-test local module changes on a NixOS machine.

## Coding Style & Naming Conventions
- Follow `.editorconfig`: UTF-8, LF endings, trim trailing whitespace.
- Use spaces for indentation; `.nix`, `.md`, and `.json` use 2-space indentation.
- Use lowercase kebab-case for files/directories (`all-packages.nix`).
- Prefer explicit Nix function argument sets (`{ stdenv, fetchurl, ... }:`) over broad `args:` patterns unless truly generic.
- Use `lowerCamelCase` for variable names.

## Testing Guidelines
- Build every changed attribute locally before opening a PR.
- For package updates, run `nixpkgs-review` and sanity-check produced binaries in `./result/bin` when applicable.
- Add or update `passthru.tests` when behavior changes.
- Test with sandboxing enabled when possible (`sandbox = true`) to match Hydra expectations.

## Commit & Pull Request Guidelines
- Make one logical change per commit; squash fixup/noise commits.
- Do not end commit summary lines with a period.
- Use area-specific prefixes:
  - Packages: `<pkg>: <old> -> <new>` or `<pkg>: init at <version>`
  - Modules: `nixos/<module>: <change>`
  - Maintainers: `maintainers: <change>`
- PRs should include motivation, test evidence, and related issue links.
- Target `master` by default; use `staging` for large rebuild sets.

## Agent-Specific Workflow
- Use GitHub MCP for GitHub operations (issues, PRs, reviews).
- Use Context7 MCP for external library/API docs.
- For Nix package/option lookups, consult the NixOS MCP and Nix docs (`nix.dev`, `nixos.wiki`).
