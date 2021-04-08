{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "scionlab";
  version = "v2020.12-105-gfbc7c985";

  src = fetchFromGitHub {
    owner = "netsec-ethz";
    repo = "scion";
    rev = version;
    sha256 = "0nfkagg8rcwpz0kwaqp30f6yh1595glq21wfc58n7yad3l63wiyf";
  };

  patches = [ ./fix-go-mod.patch ];

  vendorSha256 = "0lk3lmjw2dxnapmv8xyd9c4pzn6nx08h04wc305xil3s0hkffakr";

  subPackages = [
    "go/posix-router/"
    "go/cs/"
    "go/posix-gateway/"
    "go/sciond/"
    "go/dispatcher/"
    "go/scion/"
    "go/scion-pki/"
    "go/tools/pathdb_dump"
  ];

  buildFlagsArray = ''
    -ldflags=
    -s
    -w
    -X github.com/scionproto/scion/go/lib/env.StartupVersion=${version}-scionlab
  '';

  meta = with lib; {
    description =
      "A global research network to test the SCION next-generation internet architecture";
    homepage = "https://www.scionlab.org/";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
