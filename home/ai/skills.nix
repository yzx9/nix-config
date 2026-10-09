{ pkgs }:

let
  anthropics-skills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "683bc88e56f3e09ba94f7055977f3d3aa499f202";
    hash = "sha256-APw+xMKqRvkLnuQxttiyyIeylrIMSxZovQnw3xEl1C4=";
  };

  # https://github.com/mattpocock/skills — "Skills For Real Engineers"
  matt-skills = pkgs.fetchFromGitHub {
    owner = "mattpocock";
    repo = "skills";
    rev = "b0618bc436ad893b3c5e84e55fba86586d34a404";
    hash = "sha256-1QwFBwG+gORvDvW4HM0LrZlHZKmKtWr7pUHU0MAXF2Y=";
  };
in
{
  skill-creator = "${anthropics-skills}/skills/skill-creator";

  # /grill-me is a thin wrapper that just runs a /grilling session, so both
  # must be present for it to work.
  grill-me = "${matt-skills}/skills/productivity/grill-me";
  grilling = "${matt-skills}/skills/productivity/grilling";
}
