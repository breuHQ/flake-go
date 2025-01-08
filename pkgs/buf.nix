{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:
buildGoModule rec {
  pname = "buf";
  version = "1.48.0";

  src = fetchFromGitHub {
    owner = "bufbuild";
    repo = "buf";
    rev = "v${version}";
    sha256 = "sha256-F1ZmhVAjm8KVFePXLeOnyvh1TvjXBDCwUizwQSpp6L4=";
  };

  vendorHash = "sha256-M5q93hJjEsdMG4N+bjHTTUqBLgy2b7oIRmkizuGxeoE=";
  subPackages = ["cmd/buf"];

  ldflags = ["-s" "-w" "-X github.com/bufbuild/buf/cmd/buf/cmd.version=${version}"];

  meta = with lib; {
    description = "A tool for working with Protocol Buffers";
    homepage = "https://buf.build";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
