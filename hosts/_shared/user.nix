let
  git = {
    name = "Zexin Yuan";
    email = "git@yzx9.xyz";
  };
in
{
  user_yzx9 = {
    inherit git;
    name = "yzx9";
  };

  user_yzx = {
    inherit git;
    name = "yzx";
  };
}
