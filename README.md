# amateur-swine

NixOS for a Dell XPS 13 9300 that stays closed in a rack.
It boots next to Windows.

- Packages: Determinate Secure Packages, rolling.
- Nix: Determinate Nix.
- Disk: ZFS with native encryption.
  The machine downloads the passphrase at boot.
- Erase your darlings: `/` rolls back to an empty snapshot at each boot.
  `/nix`, `/home`, and `/persist` stay.
- Remote access: SSH, Tailscale, and a Rex login server.
- Desktop: Hyprland (Lua configuration from home-manager), with greetd at the console and wayvnc for remote use.

## Layout

| Path | Contents |
| --- | --- |
| `hosts/amateur-swine/` | The system configuration. |
| `hosts/amateur-swine/unlock.nix` | Initrd network, passphrase download, and SSH for a typed passphrase. |
| `hosts/amateur-swine/zfs.nix` | Datasets, mounts, and the root rollback. |
| `hosts/amateur-swine/impermanence.nix` | The paths kept on `/persist`. |
| `installer/` | The installer image. It contains the complete system, so installation needs no network. |
| `scripts/prepare-disk.sh` | Partitions the free space, makes the pool, and mounts it at `/mnt`. |
| `scripts/install-system.sh` | Makes host keys and the password, then runs `nixos-install`. |

## Disk layout

The Windows partitions do not change.
`prepare-disk` only adds partitions in the largest free space, and sets the name of the EFI system partition to `ESP`.

| Partition | Mount | Contents |
| --- | --- | --- |
| Windows EFI system partition, named `ESP` | `/efi` | systemd-boot and the Windows boot manager. |
| `nixos-boot`, 2 GiB, XBOOTLDR | `/boot` | NixOS kernels and initrds. The Dell ESP is too small for them. |
| `nixos-zfs` | | The pool `rpool`. |

| Dataset | Mount | At boot |
| --- | --- | --- |
| `rpool/local/root` | `/` | Rolls back to `@blank`. |
| `rpool/local/nix` | `/nix` | Stays. |
| `rpool/safe/home` | `/home` | Stays. Automatic snapshots. |
| `rpool/safe/persist` | `/persist` | Stays. Automatic snapshots. |
| `rpool/reserved` | | 10 GiB reservation. If the pool is full, set `refreservation=none` on it to get space. |

## Unlock at boot

1. The initrd gets an address with DHCP on the USB-C Ethernet adapter.
2. It downloads the passphrase from the URL in `/persist/etc/secrets/initrd/zfs-key-url`.
   It tries 30 times, 2 seconds apart.
3. If the download fails, it asks for the passphrase.
   Type it at the console, or connect over SSH:

   ```sh
   ssh -p 2222 root@<LAN address of amateur-swine>
   systemd-tty-ask-password-agent
   ```

The URL is not in this repository.
`prepare-disk` writes it to `/persist`, and the bootloader installation copies it into the initrd on `/boot`.
Thus, a person with the disk can read the URL.
If the machine is stolen, delete the gist.

To change the URL, edit `/persist/etc/secrets/initrd/zfs-key-url`, then run `sudo nixos-rebuild boot`.
To change the passphrase, run `sudo zfs change-key rpool`, and update the gist to match.

## Before installation

### In Windows

1. Run Windows Update until there are no more updates.
2. Install the Dell BIOS update.
   Suspend BitLocker first: `manage-bde -protectors -disable C:`.
3. Save your BitLocker recovery key.
4. Turn off Fast Startup.
5. In Disk Management, shrink C:.
   Leave at least 32 GiB of unallocated space.
6. Change the storage mode to AHCI, with Safe Mode:
   1. In an administrator prompt, run `bcdedit /set {current} safeboot minimal`.
   2. Reboot, and press F2 for the BIOS setup.
   3. Set Storage → SATA/NVMe Operation to **AHCI/NVMe**.
   4. Windows starts in Safe Mode.
      Run `bcdedit /deletevalue {current} safeboot`, and reboot.

### In the BIOS setup (F2)

1. Turn off Secure Boot.
2. Set the battery charge configuration to **Primarily AC Use**.
   The machine is always on AC power, and a battery that stays at 100% can swell.
3. If the BIOS has a setting to start the machine when AC power comes back, turn it on.

## Installation

1. Push this repository to GitHub.
   The `build` workflow builds the system and the installer image.
   The repository owner must have access to Determinate Secure Packages on FlakeHub.
2. Download the image from the workflow run:

   ```sh
   gh run download --name amateur-swine-installer
   ```

3. Write it to a USB-C flash drive.
   On macOS, find the drive with `diskutil list`, then:

   ```sh
   diskutil unmountDisk /dev/diskN
   sudo dd if=amateur-swine-installer.iso of=/dev/rdiskN bs=4m status=progress
   ```

4. Connect the USB-C Ethernet adapter and the flash drive.
   Press F12 at the Dell logo, and select the flash drive.
5. From another computer, connect with SSH: `ssh root@<address>`.
   (Or use the console.)
6. Prepare the disk:

   ```sh
   prepare-disk /dev/nvme0n1
   ```

   It shows the partition table and the free space.
   Then it asks for the passphrase URL and for `yes` before it writes anything.
7. Install:

   ```sh
   install-system
   ```

   It asks for a password for `grahamc`.
   It shows the SSH host key fingerprints at the end.
   Record them.
8. Unmount, export the pool, remove the flash drive, and reboot:

   ```sh
   umount -R /mnt
   zpool export rpool
   reboot
   ```

## After the first boot

1. Connect with SSH as `grahamc`.
2. Join the tailnet:

   ```sh
   sudo tailscale up
   ```

   Then turn on HTTPS for the tailnet in the Tailscale admin console, if it is not on.
   Rex uses Tailscale Serve, which needs HTTPS.
3. Log in to FlakeHub, so the machine can get Secure Packages:

   ```sh
   sudo determinate-nixd login
   ```

4. Make sure that Rex accepts your tailnet identity.
   `hosts/amateur-swine/rex.nix` allows `tailscale:grahamc@github`.
   If your Tailscale login is not GitHub, change it.
5. Test the unlock fallback.
   Reboot without the network cable, and type the passphrase over the console or SSH on port 2222.

## Updates

The `update-flake-lock` workflow opens a pull request each Monday.
After CI passes, merge it, then on the machine:

```sh
sudo nixos-rebuild switch --flake github:<owner>/<repo>#amateur-swine
```

## Remote desktop

Log in to Hyprland at the console.
greetd cannot start a Hyprland session for a remote user.
Then start wayvnc over SSH:

```sh
ssh grahamc@amateur-swine
WAYLAND_DISPLAY=wayland-1 wayvnc 0.0.0.0 &
```

The Hyprland session stays after you close the lid.
After a reboot, someone must log in at the console again.

Connect a VNC client to `amateur-swine:5900` over the tailnet.
The firewall blocks port 5900 on the LAN.

## TinyPilot

A TinyPilot KVM gives remote access to the BIOS, the boot menu, the passphrase prompt, and the Hyprland login.

- Connect a plain USB-C hub (not a Thunderbolt dock) with HDMI, Ethernet, USB-A, and power pass-through.
- HDMI from the hub goes to the TinyPilot, and the TinyPilot USB cable goes to the hub.
- The initrd has `usbhid` and early `i915`, so the keyboard and display work at the passphrase prompt.
- When the lid is closed, Hyprland turns off the internal screen (`home/grahamc.nix`), so the TinyPilot display is the only display.
- The TinyPilot cannot press the power button of a laptop.
  Use `reboot`, not `poweroff`.

## Things to keep on `/persist`

Only the paths in `hosts/amateur-swine/impermanence.nix` survive a reboot.
To find files that a program wrote to `/` since boot:

```sh
sudo zfs diff rpool/local/root@blank
```
