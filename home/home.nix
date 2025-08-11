{ config, pkgs, lib, nur, ... }:

let
  # Get all `.nix` files under the './programs' directory
  programsDir = ./programs;

  # This part is crucial for finding the modules.
  programModules = lib.filter (path:
    lib.strings.hasSuffix "/default.nix"
    (toString path)) # Keeps only files ending with "/default.nix"
    (lib.filesystem.listFilesRecursive programsDir);

  aliasesToml = builtins.fromTOML (builtins.readFile ./config/aliases.toml);
in {
  imports = programModules ++ [ ./programs.nix ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  nix.package = pkgs.nix;
  nixpkgs.overlays = [ nur.overlays.default ];

  home.packages = import ./packages.nix { inherit pkgs; };

  home.sessionVariables = { EDITOR = "vim"; };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;

  home.shellAliases = aliasesToml.aliases;
}
