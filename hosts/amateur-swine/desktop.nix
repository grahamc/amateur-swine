# Hyprland, for use before the machine goes in the rack.
# For remote use, start wayvnc in the Hyprland session:
#   wayvnc 0.0.0.0
# The firewall lets only the tailnet reach port 5900.
{ config, pkgs, ... }:
{
  # The xdg-desktop-portal 1.22.1 notification tests fail in the build sandbox.
  # Secure Packages does not cache it, so CI must build it.
  nixpkgs.overlays = [
    (final: prev: {
      xdg-desktop-portal = prev.xdg-desktop-portal.overrideAttrs { doCheck = false; };
    })
  ];

  programs.hyprland.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session.command = builtins.concatStringsSep " " [
      "${pkgs.tuigreet}/bin/tuigreet"
      "--time"
      "--remember"
      "--remember-session"
      "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
    ];
  };

  environment.systemPackages = with pkgs; [
    kitty
    wayvnc
  ];
}
