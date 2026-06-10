{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
  pkg-config,
  stdenv,
  libiconv,
  versionCheckHook,
  nix-update-script,
}:

let
  litellmPricing = fetchurl {
    url = "https://raw.githubusercontent.com/BerriAI/litellm/e59e34bed3670a6894d43129c2af16af28057d03/model_prices_and_context_window.json";
    hash = "sha256-aPue4NpPpTKAtAYCI8S8ojmVCDtYr+mxwtYkOASEg3w=";
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ccusage";
  version = "20.0.9";

  src = fetchFromGitHub {
    owner = "ryoppippi";
    repo = "ccusage";
    tag = "v${finalAttrs.version}";
    hash = "sha256-D/nj0zycBA1lEj0cgZK11Jucjgq6kcmHNmZVFlIgkxE=";
  };

  sourceRoot = "${finalAttrs.src.name}/rust";

  __structuredAttrs = true;
  strictDeps = true;

  cargoHash = "sha256-ohhHq+h5K05IKvPTQKm0ctt+6rdvaQjiGehRwJYSxWQ=";

  cargoBuildFlags = [
    "-p"
    "ccusage"
    "--bin"
    "ccusage"
  ];

  nativeBuildInputs = [ pkg-config ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [ libiconv ];

  env.CCUSAGE_PRICING_JSON_PATH = litellmPricing;

  doCheck = false;

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Analyze coding agent CLI token usage and costs from local data";
    homepage = "https://github.com/ryoppippi/ccusage";
    changelog = "https://github.com/ryoppippi/ccusage/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "ccusage";
    platforms = lib.platforms.unix;
  };
})
