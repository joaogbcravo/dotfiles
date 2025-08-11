{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pkgs.nur.repos.robinovitch61.kl
  ];
}