{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchPnpmDeps,
  makeBinaryWrapper,
  nodejs_22,
  nix-update-script,
  pnpm_10,
  pnpmConfigHook,
  stdenvNoCC,
}:

let
  pname = "signoz";
  version = "0.149.0";

  src = fetchFromGitHub {
    owner = "SigNoz";
    repo = "signoz";
    tag = "v${version}";
    hash = "sha256-Vznl2FBN1BFsih+T8M/WZiDQAMAS29ycG3N/cCXZkrs=";
  };

  signoz-frontend = import ./frontend.nix {
    inherit
      lib
      fetchPnpmDeps
      nodejs_22
      pnpm_10
      pnpmConfigHook
      stdenvNoCC
      src
      version
      ;
  };
in
buildGoModule (finalAttrs: {
  inherit pname version src;

  nativeBuildInputs = [ makeBinaryWrapper ];

  subPackages = [
    "cmd/community"
    "scripts/clickhouse/histogramquantile"
  ];

  tags = [ "timetzdata" ];

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

  ldflags = [
    "-s"
    "-w"
    "-X github.com/SigNoz/signoz/pkg/version.version=v${version}"
    "-X github.com/SigNoz/signoz/pkg/version.variant=community"
    "-X github.com/SigNoz/signoz/pkg/version.hash=4cb022d"
    "-X github.com/SigNoz/signoz/pkg/version.time=2026-11-04T05:12:37Z"
    "-X github.com/SigNoz/signoz/pkg/version.branch=v${version}"
  ];

  vendorHash = "sha256-CCafEtv6fjLsjCJRLoP2qqReWSs/KQVS8qBwRVXdTow=";

  postInstall =
    let
      share = "$out/share/signoz";
    in
    ''
      install -m 0755 -D $out/bin/histogramquantile $out/libexec/signoz/histogramQuantile
      rm $out/bin/histogramquantile
      mv $out/bin/community $out/bin/signoz

      mkdir -p ${share}
      cp -r ${signoz-frontend} ${share}/web
      cp -r ${finalAttrs.src}/templates ${share}/templates

      wrapProgram $out/bin/signoz \
        --set-default SIGNOZ_WEB_DIRECTORY "${share}/web" \
        --set-default SIGNOZ_EMAILING_TEMPLATES_DIRECTORY "${share}/templates/email" \
        --set-default SIGNOZ_ALERTMANAGER_SIGNOZ_TEMPLATES "${share}/templates/alertmanager/*.gotmpl"
    '';

  passthru = {
    frontend = signoz-frontend;
    updateScript = nix-update-script {
      extraArgs = [
        "--subpackage"
        "frontend"
      ];
    };
  };

  meta = {
    description = "OpenTelemetry-native observability platform (community edition)";
    homepage = "https://signoz.io/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ yzx9 ];
    mainProgram = "signoz";
    platforms = lib.platforms.linux;
  };
})
