{
  lib,
  fetchzip,
  writeScript,
  proton-ge-bin,

  # Microarchitecture level of the prebuilt binaries.
  # Upstream ships "x86_64" and "x86_64_v3" tarballs for every release.
  microarch ? "x86_64",
  steamDisplayName ? "Proton CachyOS slr",
}:
proton-ge-bin.overrideAttrs (
  finalAttrs: _: {
    strictDeps = true;
    __structuredAttrs = true;

    inherit steamDisplayName;

    pname = "proton-cachyos-slr-bin" + lib.optionalString (microarch == "x86_64_v3") "-v3";
    version = "cachyos-11.0-20260602-slr";

    src = fetchzip {
      url = "https://github.com/CachyOS/proton-cachyos/releases/download/${finalAttrs.version}/proton-${finalAttrs.version}-${microarch}.tar.xz";
      hash =
        {
          x86_64 = "sha256-PRGifq6wCKNv5DJiaAZ/6/iWfA6CVu++YZAkX5Ww97U=";
          x86_64_v3 = "sha256-SVJSIqd7SEjtl2FcsCHOUgYYSDMn3cedA2GTGUNmDQM=";
        }
        .${microarch};
    };

    preFixup = ''
      substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
        --replace-fail "proton-${finalAttrs.version}-${microarch}" "${steamDisplayName}"
    '';

    # Both microarchitecture variants come from the same upstream release, so a
    # single script keeps proton-cachyos-slr-bin and proton-cachyos-slr-bin-v3
    # in lockstep. The v3 variant inherits the version from this file, hence
    # only its hash needs refreshing.
    passthru.updateScript = writeScript "update-proton-cachyos-slr" ''
      #!/usr/bin/env nix-shell
      #!nix-shell -i bash -p curl jq common-updater-scripts
      set -eu -o pipefail
      repo="https://api.github.com/repos/CachyOS/proton-cachyos/releases/latest"
      version="$(curl -sL "$repo" | jq '.tag_name' --raw-output)"
      if [[ "$version" == "${finalAttrs.version}" ]]; then
        echo "proton-cachyos-slr-bin is already up to date: $version" >&2
        exit 0
      fi
      update-source-version proton-cachyos-slr-bin "$version"
      update-source-version proton-cachyos-slr-bin-v3 "$version" --ignore-same-version
    '';

    meta = {
      description = ''
        Compatibility tool for Steam Play based on Wine and additional components.
        This version is built against the Steam Linux Runtime (SLR)${
          lib.optionalString (microarch == "x86_64_v3") " for the x86-64-v3 microarchitecture level"
        }.

        (This is intended for use in the `programs.steam.extraCompatPackages` option only.)
      '';
      homepage = "https://github.com/CachyOS/proton-cachyos";
      license = lib.licenses.bsd3;
      maintainers = with lib.maintainers; [
        Karrfy
        shgew
      ];
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  }
)
