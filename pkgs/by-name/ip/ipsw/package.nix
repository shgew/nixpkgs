{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "ipsw";
  version = "3.1.648";

  src = fetchFromGitHub {
    owner = "blacktop";
    repo = "ipsw";
    tag = "v${finalAttrs.version}";
    hash = "sha256-DrtOMJxbUFt27Ct7IsrpdR5JhBImkYAQ/A54DSTV6T0=";
  };

  vendorHash = "sha256-TdphzjySy5lCa3qsH662PujkRIOgg5M+UuaxMOWF8O0=";

  proxyVendor = true;

  nativeBuildInputs = [ installShellFiles ];

  subPackages = [
    "cmd/ipsw"
    "cmd/ipswd"
  ];

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/blacktop/ipsw/cmd/ipsw/cmd.AppVersion=${finalAttrs.version}"
    "-X=github.com/blacktop/ipsw/cmd/ipsw/cmd.AppBuildCommit=nixpkgs"
    "-X=github.com/blacktop/ipsw/api/types.BuildVersion=${finalAttrs.version}"
    "-X=github.com/blacktop/ipsw/api/types.BuildTime=nixpkgs"
  ];

  doCheck = false;

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd ipsw \
      --bash <($out/bin/ipsw completion bash) \
      --fish <($out/bin/ipsw completion fish) \
      --zsh <($out/bin/ipsw completion zsh)
    installShellCompletion --cmd ipswd \
      --bash <($out/bin/ipswd completion bash) \
      --fish <($out/bin/ipswd completion fish) \
      --zsh <($out/bin/ipswd completion zsh)
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "iOS/macOS research Swiss Army knife";
    homepage = "https://github.com/blacktop/ipsw";
    changelog = "https://github.com/blacktop/ipsw/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "ipsw";
  };
})
