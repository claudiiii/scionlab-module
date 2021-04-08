final: prev:
let
  inherit (prev) lib callPackage;
in
{
  scion = callPackage ./pkgs/scion { };

  scion-apps = callPackage ./pkgs/scion-apps { };
}
