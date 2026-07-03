let
  git = {
    name = "Zexin Yuan";
    email = "git@yzx9.xyz";
  };

  nameservers = [
    "223.5.5.5"
    "1.1.1.1"
    "8.8.8.8"
  ];
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

  # networking
  mkNetworkingLab = interface: address: {
    inherit nameservers;

    interfaces.${interface}.ipv4.addresses = [
      {
        inherit address;
        prefixLength = 24;
      }
    ];

    defaultGateway = {
      inherit interface;
      address = "10.6.141.1";
    };
  };
}
