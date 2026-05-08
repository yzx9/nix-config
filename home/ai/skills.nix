{ pkgs }:

let
  anthropics-skills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "d211d437443a7b2496a3dad9575e7dddd724c585";
    hash = "sha256-5NGI0gojBGoXXus8CPhIrigyWSEYJg8gnCzWYl6PsLA=";
  };
in
{
  skill-creator = "${anthropics-skills}/skills/skill-creator";
}
