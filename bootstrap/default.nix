{ python3Packages, git }:

python3Packages.buildPythonApplication {
  pname = "ocf-nix-bootstrap";
  version = "2024-04-16";
  format = "other";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp ${./bootstrap} $out/bin/ocf-nix-bootstrap
  '';

  propagatedBuildInputs = [
    git
  ];

  meta = {
    description = "OCF NixOS bootstrap script";
    homepage = "https://github.com/oliver-ni/ocf-nix-desktops";
  };
}
