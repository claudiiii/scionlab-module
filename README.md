# SCIONLab module for NixOS

Deploy a SCION AS with the help of [SCIONLab](https://www.scionlab.org/) and [NixOS](https://nixos.org/).

## Installation

To use the module simply checkout the repository and import it in your NixOS config.

``` nix
imports = [ /path/to/scionlab-module ];
```

Or, fetch it directly from GitHub:

``` nix
imports = [
  (builtins.fetchTarball {
    url = "https://github.com/claudiiii/scionlab-module/archive/main.tar.gz";
    # This hash needs to be updated
    sha256 = lib.fakeSha256;
  })
];
```

## Getting started

First you need to register an AS on the [SCIONLab website](https://www.scionlab.org/user/) and download the configuration files.
Next extract the configuration to a folder on your system and make it readable by the `scion` user and group. 
`/etc/scion` is a good place. You might need to enable the module first for the user and group to exist.

An example configuration might be:

``` nix
services.scionlab = {
  enable = true;
  asConfigPath = "/path/to/as/config";
  vpn = true;
  vpnConfigFile = "/path/to/vpn/config.conf";
};

```

To start using SCION you first need to start the VPN (if configured).

``` sh
$ systemctl start openvpn-scionlabVPN
```

And finally the SCIONLab services.

``` sh
$ systemctl start scionlab
```

Now everything should work. You can test that by showing the paths to a different AS.

``` sh
$ scion showpaths 17-ffaa:0:1107
```

## Using the VM

It's also possible to build a VM from the `test-vm.nix` configuration.
First you need to fill in the TODOs at the top of the file with the paths to your AS config.
Then to build the VM run the following snipped in the root of the repository.

``` sh
$ nix-build '<nixpkgs/nixos>' -A vm --arg configuration ./test-vm.nix --show-trace
```

The resulting VM can then be started.

``` sh
$ ./result/bin/run-nixos-vm
```
