# Place for programs without configs.
# As soon as they have some kind of config, move them to their own folder.

let
  enablePrograms = names:
    builtins.listToAttrs (builtins.map (name: {
      name = name;
      value = { enable = true; };
    }) names);
in {
  programs = enablePrograms [
    # A cat(1) clone with syntax highlighting and Git integration
    "bat"
    # Browser
    "brave"
    # As (yet another) process/system visualization and management application
    "bottom"
    # Resource monitor that shows usage and stats for processor, memory, disks, network and processes.
    "btop"
    # Fastfetch is atool for fetching system information and displaying it in a visually appealing way.
    "fastfetch"
    # fd is a program to find entries in your filesystem
    "fd"
    # Kubernetes terminal dashboard
    "k9s"
    # Docker terminal dashboard
    "lazydocker"
    # An interactive cheatsheet tool for the command-line.
    "navi"
    # Yet another Nix CLI helper. [Maintainers=@NotAShelf]
    "nh"
    # Faster alternative to grep
    "ripgrep"
  ];
}
