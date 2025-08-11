{ rev, inputs, ... }: {
  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = "aarch64-darwin";
  };
  nix.settings.experimental-features = "nix-command flakes";
  networking.hostName = "macmini";

  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = true;

    # User owning the Homebrew prefix
    user = "jcravo";

    # Declarative tap management
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };

    # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
    mutableTaps = false;
  };

  # Used for backwards compatibility. please read the changelog
  # before changing: `darwin-rebuild changelog`.
  system.stateVersion = 5;
  system.primaryUser = "jcravo";
  # system.configurationRevision = rev or null;
  system.configurationRevision = rev;

  # system.configurationRevision = self.rev or self.dirtyRev or null;

  system.keyboard = {
    enableKeyMapping = true;
    userKeyMapping = [
      # Remap Caps Lock to F19.
      # TODO apparently this doesn't load on startup
      {
        HIDKeyboardModifierMappingSrc = 30064771129;
        HIDKeyboardModifierMappingDst = 30064771182;
      }
    ];
  };

  system.defaults.dock = {
    appswitcher-all-displays = true;
    autohide = true;
    autohide-delay = 0.0;
    autohide-time-modifier = 0.15;
    dashboard-in-overlay = false;
    enable-spring-load-actions-on-all-items = false;
    expose-animation-duration = 0.2;
    expose-group-apps = false;
    launchanim = true;
    mineffect = "genie";
    minimize-to-application = false;
    mouse-over-hilite-stack = true;
    mru-spaces = false;
    orientation = "bottom";
    show-process-indicators = true;
    show-recents = true;
    showhidden = true;
    static-only = false;
    tilesize = 48;
    wvous-bl-corner = 1;
    wvous-br-corner = 1;
    wvous-tl-corner = 1;
    wvous-tr-corner = 1;
    persistent-apps = [
      "/Users/jcravo/.nix-profile/Applications/Brave Browser.app"
      "/Users/jcravo/.nix-profile/Applications/Spotify.app"
      "/Users/jcravo/.nix-profile/Applications/Visual Studio Code.app"
      "/Users/jcravo/.nix-profile/Applications/WezTerm.app"
    ];
  };

  # Declare the user that will be running `nix-darwin`.
  users.users.jcravo = {
    name = "jcravo";
    home = "/Users/jcravo";
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";

    taps = [ "homebrew/cask" ];
    brews = [ ];
    casks = [
      # Build, render, and create LEGO instructions
      "bricklink-studio"
      # Docker
      "docker-desktop"
      # Multi-platform multi-messaging app
      "ferdium"
      # Terminal
      "ghostty"
      # VPN client for secure internet access and private browsing
      "nordvpn"
      # Workspace simplifier - to organize your workspace and boost your productivity
      "rambox"
      # Video game digital distribution service
      "steam"
      # Vagrant - command line utility for managing the lifecycle of virtual machines.
      "vagrant"
      # Virtualbox
      "virtualbox"
    ];
  };

  system.activationScripts = {
    # Xcode Command Line Tools pre-install check
    xcode-select.text = ''
      if ! xcode-select -p &> /dev/null; then
        echo "⚠️  Xcode Command Line Tools not installed. Triggering install..."
        xcode-select --install
        echo "👉 Please finish installation in the GUI and re-run: darwin-rebuild switch"
        exit 1
      fi
    '';
    # TODO make an echo message like above
    rosetta.text = ''
      softwareupdate --install-rosetta --agree-to-license
    '';
  };
}
