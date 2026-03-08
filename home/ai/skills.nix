{ pkgs }:

let
  anthropics-skills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "b0cbd3df1533b396d281a6886d5132f623393a9c";
    hash = "sha256-GzNpraXV85qUwyGs5XDe0zHYr2AazqFppWtH9JvO3QE=";
  };
in
{
  skill-creator = "${anthropics-skills}/skills/skill-creator";
}
