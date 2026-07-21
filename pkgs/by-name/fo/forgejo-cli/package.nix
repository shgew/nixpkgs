{
  lib,
  stdenv,
  rustPlatform,
  fetchFromCodeberg,
  pkg-config,
  installShellFiles,
  writableTmpDirAsHomeHook,
  libgit2,
  oniguruma,
  openssl,
  zlib,
  versionCheckHook,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "forgejo-cli";
  version = "0.6.0";

  __structuredAttrs = true;

  src = fetchFromCodeberg {
    owner = "forgejo-contrib";
    repo = "forgejo-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-XG7IPfl5yLToDQ+P0JkMxhfqsGd3cGWYCNrmlFf9j2Y=";
  };

  cargoHash = "sha256-+7WiOmYBjTMEsIGaqnMVTIHhzTpm8ObnljNXFnDazhI=";

  nativeBuildInputs = [
    pkg-config
    installShellFiles
    writableTmpDirAsHomeHook # Needed for shell completions
  ];

  buildInputs = [
    libgit2
    oniguruma
    openssl
    zlib
  ];

  env = {
    RUSTONIG_SYSTEM_LIBONIG = true;
    BUILD_TYPE = "nixpkgs";
  };

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    # The generated nushell completion declares an invalid parameter name
    # (`[OWNER]/NAME`), which nushell refuses to parse; rewrite it to a valid
    # identifier before installing.
    $out/bin/fj completion nushell > fj.nu
    substituteInPlace fj.nu \
      --replace-fail '[OWNER]/NAME: string' 'owner_name: string'

    installShellCompletion --cmd fj \
      --bash <($out/bin/fj completion bash) \
      --fish <($out/bin/fj completion fish) \
      --zsh <($out/bin/fj completion zsh) \
      --nushell fj.nu
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "version";
  doInstallCheck = true;

  meta = {
    description = "CLI application for interacting with Forgejo";
    homepage = "https://codeberg.org/forgejo-contrib/forgejo-cli";
    changelog = "https://codeberg.org/forgejo-contrib/forgejo-cli/releases/tag/v${finalAttrs.version}";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [
      da157
      isabelroses
    ];
    mainProgram = "fj";
  };
})
