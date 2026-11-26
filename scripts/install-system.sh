# Install amateur-swine to /mnt.
# Run prepare-disk first.
#
# The system was built in CI and is already on the installer image,
# so this needs no network and no FlakeHub login.
#
# TOPLEVEL is set by the Nix wrapper.

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this as root." >&2
  exit 1
fi

for path in /mnt /mnt/nix /mnt/persist /mnt/home /mnt/efi /mnt/boot; do
  if ! mountpoint -q "$path"; then
    echo "$path is not mounted. Run prepare-disk first." >&2
    exit 1
  fi
done

secrets=/mnt/persist/etc/secrets
mkdir -p "$secrets/initrd" /mnt/persist/etc/ssh
chmod 0700 "$secrets" "$secrets/initrd"

# Host keys.
for key in "$secrets/initrd/ssh_host_ed25519_key" /mnt/persist/etc/ssh/ssh_host_ed25519_key; do
  if [ ! -e "$key" ]; then
    ssh-keygen -q -t ed25519 -N "" -C amateur-swine -f "$key"
  fi
done

if [ ! -e /mnt/persist/etc/machine-id ]; then
  systemd-machine-id-setup --root=/mnt/persist
fi

if [ ! -s "$secrets/initrd/zfs-key-url" ]; then
  echo "$secrets/initrd/zfs-key-url is missing. prepare-disk writes it." >&2
  exit 1
fi

# The password for grahamc, for sudo and for the local console.
if [ ! -s "$secrets/grahamc.passwd" ]; then
  echo "Type a password for grahamc."
  until hash=$(mkpasswd -m yescrypt) && [ -n "$hash" ]; do
    echo "Try again."
  done
  (umask 077 && printf '%s\n' "$hash" > "$secrets/grahamc.passwd")
fi

nixos-install --system "$TOPLEVEL" --no-root-passwd --no-channel-copy

echo
echo "Installation is complete."
echo
echo "Host key fingerprints:"
ssh-keygen -l -f "$secrets/initrd/ssh_host_ed25519_key.pub" | sed 's/^/  initrd (port 2222): /'
ssh-keygen -l -f /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub | sed 's/^/  system (port 22):   /'
echo
echo "Next:"
echo "  umount -R /mnt"
echo "  zpool export rpool"
echo "  reboot"
