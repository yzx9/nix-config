{ pkgs }:

let
  anthropics-skills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "9d2f1ae187231d8199c64b5b762e1bdf2244733d";
    hash = "sha256-U7Nt1xrFOSOEm4vuWmy4pVsEyvv+Hj4sv8yXOofmwAw=";
  };

  # https://github.com/mattpocock/skills — "Skills For Real Engineers"
  matt-skills = pkgs.fetchFromGitHub {
    owner = "mattpocock";
    repo = "skills";
    rev = "d574778f94cf620fcc8ce741584093bc650a61d3";
    hash = "sha256-XqF709Y9GMKINzZITlbCTyatG9AxRZh0qn2vcv1Z8yo=";
  };
in
{
  skill-creator = "${anthropics-skills}/skills/skill-creator";

  # /grill-me is a thin wrapper that just runs a /grilling session, so both
  # must be present for it to work.
  grill-me = "${matt-skills}/skills/productivity/grill-me";
  grilling = "${matt-skills}/skills/productivity/grilling";
}
