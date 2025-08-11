{ pkgs, config, ... }: {
  programs = {
    git = {
      enable = true;

      userName = "João Cravo";
      userEmail = "joaogbcravo@gmail.com";
    };

    git-credential-oauth = {
      # https://github.com/hickford/git-credential-oauth
      # No more passwords! No more personal access tokens! No more SSH keys!
      enable = true;
    };
  };
}
