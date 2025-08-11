{ config, pkgs, lib, ... }:

let
  dive = pkgs.buildGoModule {
    pname = "dive";
    version = "0.13.1";

    src = pkgs.fetchFromGitHub {
      owner = "wagoodman";
      repo = "dive";
      rev = "v0.13.1";
      sha256 = "PXimdEgcPS1QQbhkaI2a55EIyWMIZTwRWj0Wx81nqcQ="; # Replace if needed
    };
    
    vendorHash = "sha256-egsFnnHZMPRTJeFw6uByE9OJH06zqKRTvQi9XhegbDI=";

    meta = {
      description = "A tool for exploring a Docker image, layer contents, and discovering ways to shrink the size of your Docker/OCI image";
      homepage = "https://terminaltrove.com/dive/";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
    };
  };
in {
  config = {
    home.packages = [ dive ];
  };
}