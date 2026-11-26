# Rex login server.
# Tailscale identifies the person who connects.
# Change the principal if your tailnet login is not grahamc@github.
{ ... }:
{
  services.rex.loginServer = {
    enable = true;
    accounts.grahamc.principals = [ "tailscale:grahamc@github" ];
    tailscaleServe.enable = true;
  };
}
