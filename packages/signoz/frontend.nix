{
  lib,
  stdenvNoCC,
  fetchPnpmDeps,
  nodejs_22,
  pnpm_10,
  pnpmConfigHook,
  src,
  version,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "signoz-frontend";
  inherit version src;

  sourceRoot = "${finalAttrs.src.name}/frontend";

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      version
      src
      sourceRoot
      ;
    pnpm = pnpm_10;
    fetcherVersion = 5;
    hash = "sha256-OZiKyVYtAxp4685X9Q8kk4y/DRqeQdcHncFlsHgg01s=";
  };

  nativeBuildInputs = [
    nodejs_22
    pnpm_10
    pnpmConfigHook
  ];

  env = {
    # Skips Husky setup in upstream postinstall; the remaining postinstall
    # generators are local-only and rerun below after offline installation.
    CI = "1";
    VITE_VERSION = "v${version}";
    VITE_ENVIRONMENT = "production";
    # Unset means the Sentry plugin skips source-map upload entirely.
    VITE_SENTRY_AUTH_TOKEN = "";
  };

  # pnpmConfigHook installs dependencies offline with --ignore-scripts, so the
  # network-prone preinstall (`npx only-allow pnpm`) and Sentry CLI installer
  # never run. Explicitly rerun the local generators the build needs.
  postBuild = ''
    node ./i18-generate-hash.cjs
    node scripts/update-registry.cjs
    pnpm build
  '';

  installPhase = ''
    runHook preInstall
    cp -r build $out
    runHook postInstall
  '';

  meta = {
    description = "SigNoz web frontend static assets";
    homepage = "https://signoz.io/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ yzx9 ];
    platforms = lib.platforms.linux;
  };
})
