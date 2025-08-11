{ pkgs, ... }:
{
  programs.bash = {
    enable = true;

    # Optionally: add initExtra to source nix-daemon.sh
    bashrcExtra = ''
      export USER=$(whoami)
      if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
    '';
  };
}