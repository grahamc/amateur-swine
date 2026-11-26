{ ... }:
{
  # / is erased at boot, so the user database comes only from this configuration.
  users.mutableUsers = false;

  users.users.grahamc = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
      "input"
    ];
    # install-system writes this file with mkpasswd.
    hashedPasswordFile = "/persist/etc/secrets/grahamc.passwd";
    openssh.authorizedKeys.keys = import ../../lib/ssh-keys.nix;
  };

  # Lock root.
  users.users.root.hashedPassword = "!";
}
