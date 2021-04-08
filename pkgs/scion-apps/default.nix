{ lib
, fetchFromGitHub
, buildGoModule
, linux-pam
}:

buildGoModule rec {
  pname = "scion-apps";
  version = "unstable-2021-04-07";

  src = fetchFromGitHub {
    owner = "netsec-ethz";
    repo = "scion-apps";
    rev = "cb415c391ac3e376bffb9af6260e529037de48ad";
    sha256 = "03w2630n2bjq7yyvdz6pr4m39s7v2d52yhfsjg93zv6xsnq1h1dv";
  };

  vendorSha256 = "16l9ff150pz4pnrihirjd2gxsvy5xadf5w46pa3v5yr86d60144j";

  buildInputs = [ linux-pam ];

  buildFlagsArray = ''
    -ldflags=
    -s
    -w
    -X main.version=${version}
  '';

  postInstall = ''
    mkdir -p $out/share/scion-webapp
    cp -r webapp/web/* $out/share/scion-webapp
  '';

  meta = with lib; {
    description = "Public repository for SCION applications";
    homepage = "https://www.scionlab.org/";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
