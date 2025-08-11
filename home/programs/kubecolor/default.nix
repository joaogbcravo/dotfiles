{ pkgs, config, ...}:
{
  programs.kubecolor = {
    enable = true;  
    enableAlias = true;
  };
}
