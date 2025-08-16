{ pkgs, ... }: {
  programs.zsh = {
    enable = true;

    autocd = true;
    autosuggestion = { enable = true; };

    enableCompletion = true;
    history = {
      ignoreDups = true;
      ignoreSpace = true;
      save = 100000;
      size = 100000;
    };

    oh-my-zsh = { enable = false; };

    plugins = [{
      name = "zsh-syntax-highlighting";
      src = pkgs.fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-syntax-highlighting";
        rev = "0.6.0";
        sha256 = "0zmq66dzasmr5pwribyh4kbkk23jxbpdw4rjxx0i7dx8jjp2lzl4";
      };
    }];

    # Learn more at https://zsh.sourceforge.io/Doc/Release/Options.html
    initContent = ''
      setopt AUTO_PUSHD

      setopt PUSHD_IGNORE_DUPS

      # Source secrets file if it exists
      [ -f $HOME/.dotfiles/home/secrets ] && set -a; source $HOME/.dotfiles/home/secrets; set +a
    '';
  };
}
