{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "signoz-otel-collector";
  version = "0.144.6";

  src = fetchFromGitHub {
    owner = "SigNoz";
    repo = "signoz-otel-collector";
    tag = "v${finalAttrs.version}";
    hash = "sha256-rNnsGilB0R9HzH7ThJXp9ntTRFSCFlD0UrL3avrHHMQ=";
  };

  subPackages = [ "cmd/signozotelcollector" ];

  # sonic v1.14.1 does not compile with the Go 1.26 toolchain in pinned
  # nixpkgs (GoMapIterator was removed); sonic added Go 1.26 support in
  # v1.15.0. Patch go.mod for the offline vendored build and let the
  # dependency fixed-output derivation regenerate the vendor tree.
  postPatch = ''
    substituteInPlace go.mod \
      --replace-fail "github.com/bytedance/sonic v1.14.1" "github.com/bytedance/sonic v1.15.5" \
      --replace-fail "github.com/bytedance/sonic/loader v0.3.0" "github.com/bytedance/sonic/loader v0.5.3"
  '';

  modBuildPhase = ''
    runHook preBuild
    if [ -d vendor ]; then
      echo "vendor folder exists, please set 'vendorHash = null;' in your expression"
      exit 10
    fi
    export GIT_SSL_CAINFO=$NIX_SSL_CERT_FILE
    go mod tidy
    go mod vendor
    mkdir -p vendor
    runHook postBuild
  '';

  vendorHash = "sha256-rYvfb4/rZmPzQ8ul/rDBh9A2/wcybylnnJuid+qMpUU=";

  postInstall = ''
    mv $out/bin/signozotelcollector $out/bin/signoz-otel-collector
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "SigNoz's OpenTelemetry Collector distribution with ClickHouse exporters and schema migrator";
    homepage = "https://github.com/SigNoz/signoz-otel-collector";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ yzx9 ];
    mainProgram = "signoz-otel-collector";
    platforms = lib.platforms.linux;
  };
})
