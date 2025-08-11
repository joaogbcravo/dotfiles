{ pkgs, config, ... }: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    mutableExtensionsDir = true;

    profiles = {
      default = {
        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;

        extensions = with pkgs.vscode-extensions; [
          github.copilot
          github.copilot-chat
          jnoortheen.nix-ide
          johnpapa.vscode-peacock
          ms-vscode-remote.remote-containers
          tamasfe.even-better-toml
        ];

        userSettings = {
          "workbench.colorTheme" = "Default Dark+";
          "editor.fontFamily" =
            "Fira Code, Menlo, Monaco, 'Courier New', monospace";
          "editor.fontSize" = 14;
          "editor.tabSize" = 4;
          "editor.insertSpaces" = true;
          "files.autoSave" = "onFocusChange";
          "editor.minimap.enabled" = true;
          "editor.formatOnSave" = true;
          "editor.rulers" = [ 80 120 ];
          "window.zoomLevel" = 0;
          "files.trimTrailingWhitespace" = true;
        };
      };
    };
  };
}
