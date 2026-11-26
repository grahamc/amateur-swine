{ osConfig, pkgs, ... }:
let
  hyprland = osConfig.programs.hyprland.package;
in
{
  home.stateVersion = "26.11";

  home.packages = [
    pkgs.claude-code
    pkgs.gh
    pkgs.git
    pkgs.jujutsu
    pkgs.tmux
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    # The NixOS module installs Hyprland and the portal.
    package = null;
    portalPackage = null;
    configType = "lua";

    extraConfig = ''
      -- Start from the upstream default configuration.
      dofile("${hyprland}/share/hypr/hyprland.lua")

      -- amateur-swine stays closed in a rack, with a TinyPilot on the external display.
      -- logind ignores the lid, so the internal screen stays on unless Hyprland turns it off.
      -- When the lid is closed, turn off the internal screen.
      -- The TinyPilot's EDID gives the external display a mode that the TinyPilot can capture.
      local function lid_closed()
        for _, name in ipairs({ "LID0", "LID" }) do
          local f = io.open("/proc/acpi/button/lid/" .. name .. "/state", "r")
          if f then
            local state = f:read("*a")
            f:close()
            return state:find("closed") ~= nil
          end
        end
        return false
      end

      if lid_closed() then
        hl.monitor({ output = "eDP-1", disabled = true })
      end

      -- Read the lid again when it opens or closes.
      hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("${hyprland}/bin/hyprctl reload"), { locked = true })
      hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("${hyprland}/bin/hyprctl reload"), { locked = true })
    '';
  };
}
