{ pkgs, config, ... }: {
  programs.pet = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./config.toml);
  };
}
