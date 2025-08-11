{ pkgs, ... }:
{
  programs.awscli = {
    # TODO really requires some kind of enable/disable based on home/work
    enable = true;
  };
}