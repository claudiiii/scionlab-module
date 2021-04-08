{ config, pkgs, ... }: {
  imports = [ ./modules/scionlab ];

  nixpkgs.overlays = [
    (import ./overlay.nix)
  ];
}
