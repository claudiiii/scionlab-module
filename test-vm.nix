{ config, lib, pkgs, ... }:
let
  mount_host_path = toString ./scion_lab_config; # TODO: Change to your config folder
  as_config_path = "${mount_guest_path}/gen/ASffaa..."; # TODO: Change to your AS name
  vpn_config_file = "${mount_guest_path}/etc/openvpn/client-scionlab-..."; # TODO Change to your VPN config file
  mount_guest_path = "/etc/scion";
  mount_tag = "hostdir";
in
{
  imports = [ ./. ];

  config = {
    services.qemuGuest.enable = true;

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    boot = {
      initrd.postMountCommands = ''
        mkdir -p "$targetRoot/${mount_guest_path}"
        mount -t 9p "${mount_tag}" "$targetRoot/${mount_guest_path}" -o trans=virtio,version=9p2000.L,cache=none
      '';
    };

    services.openssh.permitRootLogin = "yes";
    services.openssh.enable = true;

    users.extraUsers.root.password = "";
    users.mutableUsers = false;

    virtualisation = {
      diskSize = 8000; # MB
      memorySize = 2048; # MB
      qemu.options = [
        "-virtfs local,path=${mount_host_path},security_model=none,mount_tag=${mount_tag}"
      ];

      # We don't want to use tmpfs, otherwise the nix store's size will be bounded
      # by a fraction of available RAM.
      writableStoreUseTmpfs = false;
    };

    networking.firewall.enable = false;

    system.name = "test";

    # TODO Add your additional programs here e.g. pkgs.scion-apps
    environment.systemPackages = [ ];

    services.scionlab = {
      enable = true;
      asConfigPath = as_config_path;
      vpn = true;
      vpnConfigFile = vpn_config_file;
    };
  };
}
