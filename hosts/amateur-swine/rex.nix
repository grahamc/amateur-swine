# Rex login server.
# Tailscale identifies the person who connects.
# Change the principal if your tailnet login is not grahamc@github.
{ ... }:
let
  me = "tailscale:grahamc@github";
in
{
  services.rex.loginServer = {
    enable = true;
    accounts.grahamc.principals = [ me ];
    defaults.${me} = "grahamc";
    tailscaleServe.enable = true;
  };
}
