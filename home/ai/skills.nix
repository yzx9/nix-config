{ pkgs }:

let
  anthropics-skills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "33375500bcea98d610eb30ce10ac4e59b89c390d";
    hash = "sha256-xUs7UX8pOcZwR0okaSbI/f8EE5F4Zi/BUd+nIZNafPc=";
  };

  # https://github.com/mattpocock/skills — "Skills For Real Engineers"
  matt-skills = pkgs.fetchFromGitHub {
    owner = "mattpocock";
    repo = "skills";
    rev = "c55ee46073ed923f86ce59a5eb3b6d895095d1b7";
    hash = "sha256-L3CpIT2DeI+fUFl9fcygojtQo2DzEen69rMD1XqR1vM=";
  };
in
{
  skill-creator = "${anthropics-skills}/skills/skill-creator";

  # /grill-me is a thin wrapper that just runs a /grilling session, so both
  # must be present for it to work.
  grill-me = "${matt-skills}/skills/productivity/grill-me";
  grilling = "${matt-skills}/skills/productivity/grilling";
}
