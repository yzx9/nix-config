final: prev:

let
  version = "1.17.0";

  src = prev.fetchFromGitHub {
    owner = "block";
    repo = "goose";
    tag = "v${version}";
    hash = "sha256-6G0uU0prDrzZYJC02EiHF3klH3k/Mu0Xc2irnJbG1UY=";
  };
in
{
  goose-cli = prev.goose-cli.overrideAttrs {
    inherit version src;

    cargoDeps = final.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-9ojODipsIlfUia3MLa7T+4+nVICoQOimcd40M44kF20=";
    };

    checkFlags = (prev.checkFlags or [ ]) ++ [
      # need keyring access
      "--skip=config::base::tests::test_multiple_secrets"
      "--skip=config::base::tests::test_secret_management"
      "--skip=config::signup_tetrate::tests::test_configure_tetrate"
      "--skip=providers::factory::tests::test_create_lead_worker_provider"
      "--skip=providers::factory::tests::test_lead_model_env_vars_with_defaults"
      "--skip=providers::factory::tests::test_create_regular_provider_without_lead_config"
      # need network access
      "--skip=providers::gcpauth::tests::test_token_refresh_race_condition"
      "--skip=tunnel::lapstone_test::test_tunnel_end_to_end"
      "--skip=tunnel::lapstone_test::test_tunnel_post_request"
    ];
  };
}
