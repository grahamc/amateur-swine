# Rex login server.
# Tailscale identifies the person who connects.
# The work tailnet reaches this machine through a Tailscale machine share.
{ ... }:
let
  principals = [
    "tailscale:grahamc@github"
    "tailscale:graham@determinate.systems"
  ];
in
{
  services.rex.loginServer = {
    enable = true;
    accounts.grahamc = { inherit principals; };
    defaults = builtins.listToAttrs (
      map (p: {
        name = p;
        value = "grahamc";
      }) principals
    );
    tailscaleServe.enable = true;
  };
}
