# . (dot) Files

## Install

TODO

## Layout

The first level layout is as below:

    .
    ├── README.md
    ├── Taskfile.yml
    ├── flake.lock
    ├── flake.nix
    ├── home
    ├── hosts
    ├── system
    └── setup

### home

All configurations managed by home-manager

### hosts

Specific information for each host, like hostname or user name.

### system

Configurations for specific systems. Example: darwin configurations for nix-darwin

### setup

On setup we have the setup/bootstrap scripts to be used on fresh hosts.
We also have some "playground" scripts to test the dotfiles in docker and vagrant.
