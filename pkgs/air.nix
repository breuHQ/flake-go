{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "air";
  version = "1.61.5";

  src = fetchFromGitHub {
    owner = "air-verse";
    repo = "air";
    rev = "v${version}";
    sha256 = "sha256-QKNXEIMsw3MCfPg3Er9r3ncN6dxI2UsD7G/FcBIrP+Y=";
  };

  vendorHash = "sha256-tct0bWTvZhHslqPAe8uOwBx4z6gLAq57igcbV1tg9OU=";
  subPackages = ["."];

  ldflags = ["-s" "-w" "-X main.version=${version}"];

  meta = with lib; {
    description = "Live reload for Go apps";
    homepage = "https://github.com/cosmtrek/air";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
