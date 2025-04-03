{
  networking = {
    interfaces.end0 = {
      ipv4.addresses = [
        {
          address = "10.6.18.188";
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = {
      address = "10.6.18.254";
      interface = "end0";
    };

    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };
}
