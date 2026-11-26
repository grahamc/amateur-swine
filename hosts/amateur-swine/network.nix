{ ... }:
{
  # DHCP on the USB-C Ethernet adapter.
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.networks."10-ethernet" = {
    matchConfig.Name = "en*";
    networkConfig.DHCP = "yes";
  };
  services.resolved.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
    hostKeys = [
      {
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # Everything on the tailnet can reach every port.
  # The LAN can reach only SSH.
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
