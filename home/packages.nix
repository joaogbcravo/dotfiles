{ pkgs }:

let
  system = pkgs.stdenv.hostPlatform.system;

  commonPkgs = with pkgs; [
    # browser
    firefox
    # A Git credential helper that securely authenticates to GitHub, GitLab and BitBucket using OAuth.
    git-credential-oauth
    # A task runner / simpler Make alternative written in Go
    go-task
    # A top-like tool for your Kubernetes cluster.
    ktop
    # The official formatter for Nix code
    nixfmt-classic
    # The Rust toolchain installer
    rustup
    # A modern alternative to the tree command
    tre-command

  ];

  linuxCommonPkgs = with pkgs; [ xclip ];

  x86_64LinuxPkgs = with pkgs; [ google-chrome spotify ];

  darwinPkgs = with pkgs; [ google-chrome spotify ];

  pkgsForSystem = if system == "x86_64-linux" then
    commonPkgs ++ linuxCommonPkgs ++ x86_64LinuxPkgs
  else if system == "aarch64-linux" then
    commonPkgs ++ linuxCommonPkgs
  else if system == "aarch64-darwin" || system == "x86_64-darwin" then
    commonPkgs ++ darwinPkgs
  else
    commonPkgs;

in builtins.filter (p: p != null) pkgsForSystem
