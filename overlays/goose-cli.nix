final: prev:

let
  version = "1.16.1";

  src = prev.fetchFromGitHub {
    owner = "block";
    repo = "goose";
    tag = "v${version}";
    hash = "sha256-lMlpgsLkPQsvc5Ad8sRrwO27ytb5hpF3doUR18DUrvw=";
  };
in
{
  goose-cli = prev.goose-cli.overrideAttrs {
    inherit version src;

    cargoDeps = final.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-WPrCwvGVOuTKXEHLR0WRV+YXr4r10fQf9t/Sfs/2bNI=";
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
