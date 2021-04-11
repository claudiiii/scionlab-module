{ config, lib, pkgs, ... }: {
  imports = [ ../. ];

  config = {
    boot.loader.systemd-boot.enable = true;

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
      fsType = "ext4";
    };

    environment.systemPackages = [ pkgs.scion-apps ];
  };
}
