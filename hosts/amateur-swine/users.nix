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
    # No password: log in with an SSH key, or with the greetd automatic login.
    openssh.authorizedKeys.keys = import ../../lib/ssh-keys.nix;
  };

  # grahamc has no password, so sudo must not ask for one.
  security.sudo.wheelNeedsPassword = false;

  # Lock root.
  users.users.root.hashedPassword = "!";
}
