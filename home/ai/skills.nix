{ pkgs }:

let
  anthropics-skills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "3b3fad96af16a10759d930941b4520ba0c40edae";
    hash = "sha256-nVid8vENmLDh7ffDqh+bJbEWtXcVltA0qa2rItmniZM=";
  };

  # https://github.com/mattpocock/skills — "Skills For Real Engineers"
  matt-skills = pkgs.fetchFromGitHub {
    owner = "mattpocock";
    repo = "skills";
    rev = "6654f6b60cd9d5be8b54c6fafe44346dabeb3b76";
    hash = "sha256-N5tpUIHO2VFeJntBTl6/VLDIVpqoshwFxNJlfXXUwsQ=";
  };
in
{
  skill-creator = "${anthropics-skills}/skills/skill-creator";

  # /grill-me is a thin wrapper that just runs a /grilling session, so both
  # must be present for it to work.
  grill-me = "${matt-skills}/skills/productivity/grill-me";
  grilling = "${matt-skills}/skills/productivity/grilling";
}
