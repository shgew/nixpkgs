{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "mole-mac";
  version = "1.39.1";

  src = fetchFromGitHub {
    owner = "tw93";
    repo = "Mole";
    tag = "V${finalAttrs.version}";
    hash = "sha256-NrDUdDx4O/QE0+UgM0aw681vAUbwO0fJ+0t0H5QBm0M=";
  };

  vendorHash = "sha256-+JxttzU6y/ETUS8VWKIGCvAs/sM1Xz9DBU4eVniVIes=";

  subPackages = [
    "cmd/analyze"
    "cmd/status"
  ];

  ldflags = [
    "-s"
    "-w"
  ];

  # Upstream test invokes `du -I` (GNU-only); BSD `du` on Darwin lacks it.
  checkFlags = [ "-skip=TestGetDirectorySizeFromDuWithIgnoresSkipsCloudPlaceholderTree" ];

  nativeBuildInputs = [ makeWrapper ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "V(.*)"
    ];
  };

  postInstall = ''
    # Set up libexec directory with the shell script tree
    mkdir -p $out/libexec/mole/{bin,lib}

    # Install main script and subcommand scripts
    install -m755 $src/mole $out/libexec/mole/
    install -m755 $src/bin/*.sh $out/libexec/mole/bin/

    # Install library scripts
    cp -r $src/lib/* $out/libexec/mole/lib/
    chmod -R +x $out/libexec/mole/lib/

    # Place Go binaries where the shell scripts expect them
    mv $out/bin/analyze $out/libexec/mole/bin/analyze-go
    mv $out/bin/status $out/libexec/mole/bin/status-go

    # Create wrapper that execs the main script (preserves BASH_SOURCE resolution)
    makeWrapper $out/libexec/mole/mole $out/bin/mole
    ln -s $out/bin/mole $out/bin/mo
  '';

  meta = {
    description = "Deep clean and optimize your Mac";
    homepage = "https://github.com/tw93/Mole";
    changelog = "https://github.com/tw93/Mole/releases/tag/V${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "mole";
    platforms = lib.platforms.darwin;
  };
})
