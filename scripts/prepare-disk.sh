# Prepare the disk for NixOS, next to Windows.
#
# Before you run this, shrink C: in Windows Disk Management.
# Leave the free space unallocated.
#
# This script:
#  - sets the partition name of the existing EFI system partition to "ESP".
#    It does not format the ESP.
#  - makes a 2 GiB XBOOTLDR partition ("nixos-boot") in the largest free space.
#  - makes a ZFS partition ("nixos-zfs") in the remaining free space.
#  - makes an encrypted ZFS pool (rpool) and the datasets.
#    The passphrase is the text that the key URL returns.
#  - mounts everything at /mnt.
#  - writes the key URL to /mnt/persist/etc/secrets/initrd/zfs-key-url.
#
# It does not change or delete any other partition.

disk="${1:-/dev/nvme0n1}"
esp_type="c12a7328-f81f-11d2-ba4b-00a0c93ec93b"
min_free_gib=32

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this as root." >&2
  exit 1
fi

if [ ! -b "$disk" ]; then
  echo "$disk is not a block device." >&2
  echo "Usage: prepare-disk [/dev/nvme0n1]" >&2
  exit 1
fi

for label in nixos-boot nixos-zfs; do
  if [ -e "/dev/disk/by-partlabel/$label" ]; then
    echo "A partition with the label $label already exists." >&2
    echo "Delete it yourself before you run this script again." >&2
    exit 1
  fi
done

if zpool list rpool >/dev/null 2>&1; then
  echo "A pool named rpool is already imported." >&2
  exit 1
fi

mapfile -t esps < <(lsblk -nrpo PATH,PARTTYPE "$disk" | awk -v t="$esp_type" '$2 == t { print $1 }')
if [ "${#esps[@]}" -ne 1 ]; then
  echo "Expected one EFI system partition on $disk, found ${#esps[@]}." >&2
  exit 1
fi
esp="${esps[0]}"
esp_number=$(cat "/sys/class/block/$(basename "$esp")/partition")

sector_size=$(blockdev --getss "$disk")
free_start=$(sgdisk -f "$disk" | tail -n1)
free_end=$(sgdisk -E "$disk" | tail -n1)
free_gib=$(( (free_end - free_start + 1) * sector_size / 1024 / 1024 / 1024 ))

echo
echo "Current partition table of $disk:"
sgdisk -p "$disk"
echo
lsblk -o NAME,SIZE,FSTYPE,PARTLABEL,LABEL "$disk"
echo
echo "EFI system partition: $esp (partition $esp_number). It will not be formatted."
echo "Largest free space: sectors $free_start to $free_end ($free_gib GiB)."
echo "New partitions: 2 GiB nixos-boot, then $((free_gib - 2)) GiB nixos-zfs."
echo

if [ "$free_gib" -lt "$min_free_gib" ]; then
  echo "There is less than $min_free_gib GiB of free space." >&2
  echo "Shrink C: more in Windows Disk Management." >&2
  exit 1
fi

# The URL that returns the ZFS passphrase.
# It is kept on this machine, and not in the repository.
while true; do
  read -r -s -p "URL of the ZFS passphrase: " key_url
  echo
  if passphrase=$(curl --fail --silent --show-error --max-time 20 "$key_url") && [ "${#passphrase}" -ge 8 ]; then
    unset passphrase
    break
  fi
  echo "Could not download a passphrase of 8 or more characters from that URL. Try again."
done

read -r -p "Type 'yes' to write the partition table: " answer
if [ "$answer" != yes ]; then
  echo "Stopped. Nothing was changed."
  exit 1
fi

set -x
set -o pipefail

sgdisk -c "$esp_number:ESP" "$disk"
sgdisk -n 0:0:+2G -t 0:ea00 -c 0:nixos-boot "$disk"
sgdisk -n 0:0:0 -t 0:bf00 -c 0:nixos-zfs "$disk"

partprobe "$disk"
udevadm settle

for label in ESP nixos-boot nixos-zfs; do
  until [ -e "/dev/disk/by-partlabel/$label" ]; do
    sleep 1
  done
done

mkfs.vfat -F 32 -n NIXBOOT /dev/disk/by-partlabel/nixos-boot

# zpool create reads the passphrase from stdin.
# Do not trace this command, so the URL is not printed.
set +x
curl --fail --silent --show-error --max-time 20 "$key_url" | zpool create \
  -o ashift=12 \
  -o autotrim=on \
  -O acltype=posixacl \
  -O xattr=sa \
  -O dnodesize=auto \
  -O normalization=formD \
  -O relatime=on \
  -O compression=zstd \
  -O encryption=aes-256-gcm \
  -O keyformat=passphrase \
  -O keylocation=prompt \
  -O canmount=off \
  -O mountpoint=none \
  rpool /dev/disk/by-partlabel/nixos-zfs
set -x

# Datasets under rpool/local are not backed up.
zfs create -o canmount=off -o mountpoint=none rpool/local
zfs create -o mountpoint=legacy rpool/local/root
zfs snapshot rpool/local/root@blank
zfs create -o mountpoint=legacy -o atime=off rpool/local/nix

# Datasets under rpool/safe get automatic snapshots.
zfs create -o canmount=off -o mountpoint=none -o com.sun:auto-snapshot=true rpool/safe
zfs create -o mountpoint=legacy rpool/safe/home
zfs create -o mountpoint=legacy rpool/safe/persist

# Keeps space free, so a full pool can still delete files.
zfs create -o canmount=off -o mountpoint=none -o refreservation=10G rpool/reserved

mount -t zfs rpool/local/root /mnt
mkdir -p /mnt/nix /mnt/home /mnt/persist /mnt/efi /mnt/boot
mount -t zfs rpool/local/nix /mnt/nix
mount -t zfs rpool/safe/home /mnt/home
mount -t zfs rpool/safe/persist /mnt/persist
mount -o umask=0077 /dev/disk/by-partlabel/ESP /mnt/efi
mount -o umask=0077 /dev/disk/by-partlabel/nixos-boot /mnt/boot

set +x
secrets=/mnt/persist/etc/secrets
mkdir -p "$secrets/initrd"
chmod 0700 "$secrets" "$secrets/initrd"
(umask 077 && printf '%s\n' "$key_url" > "$secrets/initrd/zfs-key-url")

echo
echo "The disk is ready, and it is mounted at /mnt."
echo "Next, run: install-system"
