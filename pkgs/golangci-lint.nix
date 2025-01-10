{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "golangci-lint";
  version = "1.62.2";

  src = fetchFromGitHub {
    owner = "golangci";
    repo = "golangci-lint";
    rev = "v${version}";
    sha256 = "sha256-8Itq4tWqJa9agGcPoQaJoQOgy/qhhegzPORDztS9T30=";
  };

  vendorHash = "sha256-SEoF+k7MYYq81v9m3eaDbIv1k9Hek5iAZ0TTJEgAsI4=";
  subPackages = ["."];

  ldflags = ["-s" "-w" "-X main.version=${version}"];

  meta = with lib; {
    description = "go linters aggregator";
    homepage = "https://golangci-lint.run";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
