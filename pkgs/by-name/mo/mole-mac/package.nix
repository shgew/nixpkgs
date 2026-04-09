{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
}:

buildGoModule (finalAttrs: {
  pname = "mole-mac";
  version = "1.33.0";

  src = fetchFromGitHub {
    owner = "tw93";
    repo = "Mole";
    tag = "V${finalAttrs.version}";
    hash = "sha256-IQcnwpwzabRLznqSin73OI7G7Jw1OjXX2JBIPFkquas=";
  };

  vendorHash = "sha256-LznLZ0NO8VBWP95ReAVORUMIDhh7/pgTY5mGNN2tND8=";

  subPackages = [
    "cmd/analyze"
    "cmd/status"
  ];

  ldflags = [
    "-s"
    "-w"
  ];

  nativeBuildInputs = [ makeWrapper ];

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
