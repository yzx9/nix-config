{ pkgs }:

let
  anthropics-skills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "0a64e398ec6bb34a494f0c347e8ccae53a862f8e";
    hash = "sha256-0ZtHTJVHeW8jIprKgCo/yU2ZI2cZxUqD3Riet3UWdt8=";
  };

  # https://github.com/mattpocock/skills — "Skills For Real Engineers"
  matt-skills = pkgs.fetchFromGitHub {
    owner = "mattpocock";
    repo = "skills";
    rev = "0ab1b63a410a03d3627979a109c8695de27af954";
    hash = "sha256-Zg64vWsmtVk7WCH/f+bifju+L8yHeAwYbDNh6Ah43V0=";
  };
in
{
  skill-creator = "${anthropics-skills}/skills/skill-creator";

  # /grill-me is a thin wrapper that just runs a /grilling session, so both
  # must be present for it to work.
  grill-me = "${matt-skills}/skills/productivity/grill-me";
  grilling = "${matt-skills}/skills/productivity/grilling";
}
