{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  testers,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "aim";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "yzx9";
    repo = "aim";
    tag = "v${finalAttrs.version}";
    hash = "sha256-IJFvb54la6YvHFwY2fMgukUcvRm1H737q6qcUpsYJa0=";
  };

  cargoHash = "sha256-nL9sZvrVLSqZxTKaZZJE1pjGSEIDf1oZv5kFA+KuCXA=";

  nativeBuildInputs = [ installShellFiles ];

  passthru.tests = {
    version = testers.version {
      package = finalAttrs.finalPackage;
      version = finalAttrs.version;
    };
  };

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd aim \
      --bash <($out/bin/aim generate completion bash) \
      --fish <($out/bin/aim generate completion fish) \
      --zsh <($out/bin/aim generate completion zsh)
  '';

  meta = {
    description = " Analyze. Interact. Manage Your Time";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
    mainProgram = "aim";
  };
})
