package cjvs

func usage() {
    println(
        """
Usage: cjvs [options...]
  list, ls        List Cangjie installations.
  ls-remote, rls  List all remote Cangjie versions.
  install, i      Install a new Cangjie version.
                    eg:
                      cjvs install 0.53.13 # install online
                      cjvs install 0.59.6 ~/Downloads/cangjie-0.59.6-linux_x64.tar.gz # install a local version
  switch, use     Switch to use the specified version.
  default         Set the default Cangjie version.
  remove, rm      Remove a specific version.
  env             Print and set up required environment variables for cjvs
  stdx            Manage stdx (extension library) versions.
                    eg:
                      cjvs stdx list                              # List installed stdx versions
                      cjvs stdx install 1.0.0 ~/Downloads/stdx.zip # Install stdx from local zip
                      cjvs stdx use 1.0.0                          # Switch stdx version
                      cjvs stdx use 1.0.0 static                   # Switch with static library
                      cjvs stdx default 1.0.0                      # Set default stdx version
                      cjvs stdx default 1.0.0 dynamic              # Set default with dynamic library
                      cjvs stdx config static                      # Set default library type
                      cjvs stdx remove 1.0.0                       # Remove stdx version
  stdx-env        Generate stdx environment variables for current shell.
                    eg:
                      cjvs stdx-env zsh                            # Generate env for zsh
                      cjvs stdx-env bash                           # Generate env for bash

GLOBAL OPTIONS:
  --help, -h     show help
  --version, -v  print the version
"""
    )
}