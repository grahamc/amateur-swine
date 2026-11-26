{ ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"

    # USB-C Ethernet adapters.
    # The initrd needs the network to download the ZFS passphrase.
    "usbnet"
    "cdc_ether"
    "cdc_ncm"
    "r8152"
    "ax88179_178a"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  boot.initrd.systemd.enable = true;

  # Windows owns the EFI system partition, and it is small.
  # systemd-boot goes in the ESP, and the kernels and initrds go in a separate XBOOTLDR partition.
  # prepare-disk makes the XBOOTLDR partition and sets the partition labels.
  boot.loader = {
    systemd-boot = {
      enable = true;
      editor = false;
      configurationLimit = 20;
      xbootldrMountPoint = "/boot";
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
  };

  fileSystems."/efi" = {
    device = "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/nixos-boot";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };
}
