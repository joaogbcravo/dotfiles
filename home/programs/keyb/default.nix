{ config, pkgs, lib, ... }:

let
  keyb = pkgs.buildGoModule {
    pname = "keyb";
    version = "0.7.0";

    src = pkgs.fetchFromGitHub {
      owner = "kencx";
      repo = "keyb";
      rev = "v0.7.0";
      sha256 = "XfVYF1fetR3ZZ3n5ozgxaRE/l+AgiLaZy4G/YGDdDyU="; # Replace if needed
    };
    
    vendorHash = "sha256-81x5PcH2rN3x5R5AClRYQwz03agJ0nCX8bFKzWUy84U=";

    meta = {
      description = "Terminal utility for creating and viewing custom hotkey cheatsheets";
      homepage = "https://terminaltrove.com/keyb/";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
    };
  };
in {
  config = {
    home.packages = [ keyb ];
  };
}