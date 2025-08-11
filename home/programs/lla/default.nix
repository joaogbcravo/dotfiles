{ config, pkgs, lib, ... }:

let
  lla = pkgs.rustPlatform.buildRustPackage rec {
    pname = "lla";
    version = "0.3.11";

    src = pkgs.fetchFromGitHub {
      owner = "chaqchase";
      repo = "lla";
      rev = "v${version}";
      sha256 = "sha256-HxHUpFTAeK3/pE+ozHGmMUj0Jt7iKrbZ1xnFj7828Ng=";
    };

    cargoLock = { lockFile = "${src}/Cargo.lock"; };

    buildInputs = with pkgs; [ pkg-config openssl zlib fontconfig ];

    doCheck = true;

    meta = {
      description =
        "Blazing Fast and highly customizable ls Replacement with Superpowers";
      homepage = "https://github.com/chaqchase/lla";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
    };
  };
in { home.packages = [ lla ]; }
