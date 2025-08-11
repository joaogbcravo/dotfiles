{
  description = "My system configuration";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    mac-app-util = { url = "github:hraban/mac-app-util"; };

    nixpkgs = { url = "github:NixOS/nixpkgs/nixos-25.05"; };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = { url = "github:zhaofengli-wip/nix-homebrew"; };

    nur = {
      url = "github:nix-community/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, mac-app-util, nix-darwin
    , nix-homebrew, nur, ... }:

    let

      systems = {
        linux = "aarch64-linux";
        darwin = "aarch64-darwin";
      };

      mkPkgs = system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

    in {
      # homeConfigurations.linux-sandbox = import ./hosts/linux-sandbox.nix { inherit inputs self; };
      homeConfigurations = {
        linux-sandbox = home-manager.lib.homeManagerConfiguration {
          extraSpecialArgs = { inherit nur inputs self; };
          pkgs = mkPkgs systems.linux;
          modules = [ ./home/home.nix ./hosts/linux-sandbox.nix ];
        };

        macmini = home-manager.lib.homeManagerConfiguration {
          extraSpecialArgs = { inherit inputs nur self; };

          pkgs = mkPkgs systems.darwin;
          modules = [
            mac-app-util.homeManagerModules.default # https://github.com/hraban/mac-app-util
            ./home/home.nix
            ./hosts/macmini.nix
          ];
        };
      };

      # darwinConfigurations.macmini = import ./machines/macmini.nix { inherit inputs self; };
      darwinConfigurations = {
        macmini = nix-darwin.lib.darwinSystem {
          modules = [
            inputs.nix-homebrew.darwinModules.nix-homebrew
            (import ./system/darwin/macmini.nix {
              inherit inputs;
              rev = self.rev or self.dirtyRev or null;
            })
          ];
        };
      };
    };
}
