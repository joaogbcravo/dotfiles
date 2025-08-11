{ config, pkgs, lib, ... }:

let
  dusage = pkgs.rustPlatform.buildRustPackage rec {
    pname = "dusage";
    version = "0.4.0";

    src = pkgs.fetchFromGitHub {
      owner = "mihaigalos";
      repo = "dusage";
      rev = "refs/tags/${version}";

      sha256 = "sha256-8nMx/HvsZCN4npKBj/iGn+mlx5g4MLfv314uyViIqUQ=";
    };

    cargoLock = { lockFile = "${src}/Cargo.lock"; };

    buildInputs = with pkgs; [ openssl zlib fontconfig ];

    doCheck = true;

    meta = {
      description = "A command line disk usage information tool.";
      homepage = "https://github.com/mihaigalos/dusage";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
    };
  };
in { home.packages = [ dusage ]; }
