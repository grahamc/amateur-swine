# Hyprland, for use before the machine goes in the rack.
# For remote use, start wayvnc in the Hyprland session:
#   wayvnc 0.0.0.0
# The firewall lets only the tailnet reach port 5900.
{ config, pkgs, ... }:
{
  programs.hyprland.enable = true;

  services.greetd = {
    enable = true;
    # grahamc has no password, so start Hyprland for grahamc at boot.
    # After a logout, restart greetd to log in again.
    settings.initial_session = {
      user = "grahamc";
      command = "${config.programs.hyprland.package}/bin/start-hyprland";
    };
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
