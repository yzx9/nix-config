{ pkgs }:

let
  anthropics-skills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "5128e1865d670f5d6c9cef000e6dfc4e951fb5b9";
    hash = "sha256-xFsg66TCtKzSgRIW6Ab771FWEIhei3jPgfE4byMiB44=";
  };
in
{
  skill-creator = "${anthropics-skills}/skills/skill-creator";
}
