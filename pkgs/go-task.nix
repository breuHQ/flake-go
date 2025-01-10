{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "go-task";
  version = "3.40.1";

  src = fetchFromGitHub {
    owner = "go-task";
    repo = "task";
    rev = "v${version}";
    sha256 = "sha256-jQKPTKEzTfzqPlNlKFMduaAhvDsogRv3vCGtZ4KP/O4=";
  };

  vendorHash = "sha256-bw9NaJOMMKcKth0hRqNq8mqib/5zLpjComo0oj22A/U=";
  subPackages = ["cmd/task"];

  ldflags = ["-s" "-w" "-X main.version=${version}"];

  meta = with lib; {
    description = "Task is a task runner / simpler Make alternative written in Go.";
    homepage = "https://taskfile.dev/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
