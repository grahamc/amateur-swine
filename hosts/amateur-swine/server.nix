# A laptop that stays closed in a rack.
{ ... }:
{
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  # Never sleep.
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # Turn off the console on the internal screen after 60 seconds.
  boot.kernelParams = [ "consoleblank=60" ];

  # Reboot 10 seconds after a kernel panic.
  boot.kernel.sysctl."kernel.panic" = 10;
}
