{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.scionlab;

  socket = "/run/shm/dispatcher";

  sciondConfig = ''
    [general]
    id = "sd"
    config_dir = "${cfg.asConfigPath}"
    reconnect_to_dispatcher = true

    [metrics]
    prometheus = "127.0.0.1:30455"

    [path_db]
    connection = "${cfg.stateDir}/sd.path.db"

    [trust_db]
    connection = "${cfg.stateDir}/sd.trust.db"

    [drkey_db]
    connection = "${cfg.stateDir}/sd.drkey.db"

    [log.console]
    level = "debug"
  '';

  dispatcherConfig = ''
    [dispatcher]
    id = "dispatcher"
    socket_file_mode = "0777"
    application_socket = "${socket}/default.sock"

    [metrics]
    prometheus = "[127.0.0.1]:30441"

    [log.console]
    level = "debug"
  '';

  sigConfig = ''
    [gateway]
    traffic_policy_file = "${cfg.asConfigPath}/sig.json"

    [log.console]
    level = "debug"
  '';

  brConfig = ''
    [general]
    config_dir = "${cfg.asConfigPath}"
    id = "br-1"
    reconnect_to_dispatcher = true

    [metrics]
    prometheus = "127.0.0.1:30401"

    [log.console]
    level = "debug"
  '';

  csConfig = ''
    [beacon_db]
    connection = "${cfg.stateDir}/cs-1.beacon.db"

    [beaconing]
    origination_interval = "5s"
    propagation_interval = "5s"
    rev_overlap = "5s"
    rev_ttl = "20s"

    [general]
    config_dir = "${cfg.asConfigPath}"
    id = "cs-1"
    reconnect_to_dispatcher = true

    [metrics]
    prometheus = "127.0.0.1:30454"

    [path_db]
    connection = "${cfg.stateDir}/cs-1.path.db"

    [quic]
    address = "127.0.0.1:30354"

    [trust_db]
    connection = "${cfg.stateDir}/cs-1.trust.db"

    [beaconing.policies]
    propagation = "${cfg.asConfigPath}/beacon_policy.yaml"

    [drkey.drkey_db]
    connection = "${cfg.stateDir}/cs-1.drkey.db"

    [renewal_db]
    connection = "${cfg.stateDir}/cs-1.renewal.db"

    [log.console]
    level = "debug"
  '';

in
{
  options = {
    services.scionlab = {
      enable = mkEnableOption "Start a SCIONLab AS.";

      autoStart = mkEnableOption ''
        Automatically start on system boot.
        Will also start the OpenVPN service if configured.
      '';

      package = mkOption {
        type = types.package;
        default = pkgs.scion;
        defaultText = "pkgs.scion";
        example = literalExample "pkgs.scion";
        description = "SCION package to use.";
      };

      vpn = mkEnableOption "Enable the SCIONLab VPN Config.";

      vpnConfigFile = mkOption {
        type = types.path;
        default = null;
        description = "Path to the SCIONLab vpn config downloaded from the website.";
      };

      port = mkOption {
        type = types.port;
        default = 50001;
        description = "Local port that SCION will use.";
      };

      openPort = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Open port in the firewall for SCION.
          Set the port option, when using a different port than the default.
        '';
      };

      asConfigPath = mkOption {
        type = types.path;
        default = null;
        description = ''
          Path to the ASffaa... folder in the SCIONLab AS config downloaded from https://www.scionlab.org/.
          Make sure this is readable by the scion group.
        '';
      };

      stateDir = mkOption {
        type = types.path;
        default = "/var/lib/scion";
        description = "Folder to store the SCION state.";
      };
    };
  };

  config = mkIf cfg.enable {
    users.users.scion = {
      description = "SCION daemon user";
      group = "scion";
      # uid = config.ids.uids.scion;
    };

    users.groups.scion = {
      # gid = config.ids.gids.scion;
    };

    systemd.targets.scionlab = {
      description = "SCIONLab Service";
      wantedBy = optional cfg.autoStart "multi-user.target";
    };

    systemd.tmpfiles.rules = [
      "d '${cfg.stateDir}' - scion scion - -"
      "d '${socket}' 0777 scion scion - -"
    ];

    systemd.services.scion-daemon =
      let
        sciondConfigFile = pkgs.writeText "sciond.toml" (sciondConfig);
      in
      {
        description = "SCION Daemon";
        after = [ "network-online.target" "scion-dispatcher.service" ];
        wants = [ "network-online.target" ];
        partOf = [ "scionlab.target" ];
        serviceConfig = {
          Type = "simple";
          User = "scion";
          Group = "scion";
          ExecStart = "${cfg.package}/bin/sciond --config ${sciondConfigFile}";
          RemainAfterExit = false;
          KillMode = "control-group";
          Restart = "on-failure";
          RestartSec = 10;
        };
        wantedBy = [ "scionlab.target" ];
      };

    systemd.services.scion-dispatcher =
      let
        dispatcherConfigFile = pkgs.writeText "dispatcher.toml" (dispatcherConfig);
      in
      {
        description = "SCION Dispatcher";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        partOf = [ "scionlab.target" ];
        preStart = "rm -rf ${socket}/default.sock";
        serviceConfig = {
          Type = "simple";
          User = "scion";
          Group = "scion";
          ExecStart = "${cfg.package}/bin/dispatcher --config ${dispatcherConfigFile}";
          RemainAfterExit = false;
          LimitNOFILE = 4096;
          KillMode = "control-group";
          Restart = "on-failure";
          RestartSec = 10;
        };
        wantedBy = [ "scionlab.target" ];
      };

    systemd.services.scion-ip-gateway =
      let
        sigConfigFile = pkgs.writeText "sig.toml" (sigConfig);
      in
      {
        description = "SCION IP Gateway";
        after = [ "network-online.target" "scion-dispatcher.service" ];
        wants = [ "network-online.target" ];
        partOf = [ "scionlab.target" ];
        serviceConfig = {
          Type = "simple";
          # TODO: Allow creating TUN devices without being root.
          # User = "scion";
          # Group = "scion";
          ExecStart = "${cfg.package}/bin/posix-gateway --config ${sigConfigFile}";
          RemainAfterExit = false;
          KillMode = "control-group";
          Restart = "on-failure";
        };
        wantedBy = [ "scionlab.target" ];
      };

    systemd.services.scion-control-service =
      let
        csConfigFile = pkgs.writeText "cs.toml" (csConfig);
      in
      {
        description = "SCION Control Service";
        after = [ "network-online.target" "scion-dispatcher.service" ];
        wants = [ "network-online.target" ];
        partOf = [ "scionlab.target" ];
        serviceConfig = {
          Type = "simple";
          User = "scion";
          Group = "scion";
          ExecStart = "${cfg.package}/bin/cs --config ${csConfigFile}";
          RemainAfterExit = false;
          KillMode = "control-group";
          Restart = "on-failure";
        };
        wantedBy = [ "scionlab.target" ];
      };

    systemd.services.scion-border-router =
      let
        brConfigFile = pkgs.writeText "br.toml" (brConfig);
      in
      {
        description = "SCION Border Router";
        after = [ "network-online.target" "scion-dispatcher.service" ];
        wants = [ "network-online.target" ];
        partOf = [ "scionlab.target" ];
        serviceConfig = {
          Type = "simple";
          User = "scion";
          Group = "scion";
          ExecStart = "${cfg.package}/bin/posix-router --config ${brConfigFile}";
          RemainAfterExit = false;
          KillMode = "control-group";
          Restart = "on-failure";
        };
        wantedBy = [ "scionlab.target" ];
      };

    services.openvpn.servers = mkIf cfg.vpn {
      scionlabVPN = {
        config = '' config ${cfg.vpnConfigFile} '';
        autoStart = cfg.autoStart;
      };
    };

    networking.firewall.allowedUDPPorts = mkIf cfg.openPort [ cfg.port ];

    environment.systemPackages = [ cfg.package ];

    boot.kernelModules = [ "tun" ];
  };
}
