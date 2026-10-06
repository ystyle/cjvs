package cjvs

func usage() {
    println(
        """
Usage: cjvs [options...]
  list, ls        List Cangjie installations.
  ls-remote, rls  List all remote Cangjie versions.
                    eg:
                      cjvs rls                                     # List all versions
                      cjvs rls sts                                 # List STS versions only
                      cjvs rls lts                                 # List LTS versions only
                      cjvs rls sts --beta                          # List STS versions with beta
  install, i      Install a new Cangjie version.
                    eg:
                      cjvs install 0.53.13                         # install online
                      cjvs install 1.2.0-ohos                      # install a cross-compile SDK
                      cjvs install 0.59.6 ~/Downloads/cangjie-0.59.6-linux_x64.tar.gz # install a local version
  switch, use     Switch to use the specified version.
  default         Set the default Cangjie version.
  remove, rm      Remove a specific version.
  env             Print and set up required environment variables for cjvs
                    eg:
                      cjvs env zsh                                 # Generate env for zsh
                      cjvs env bash                                # Generate env for bash
                      cjvs env bash -no-ld-library-path            # Generate env without LD_LIBRARY_PATH
                      cjvs env nushell | save -f ~/.cjvs.nu
                    options:
                      -no-ld-library-path  Do not export LD_LIBRARY_PATH (Linux/macOS only)
                      -stdx                Export CANGJIE_STDX_PATH through a symlink;
                                           cjpm cannot read symlinks yet, use 'cjvs stdx-env'
  stdx            Manage stdx (extension library) versions.
                    eg:
                      cjvs stdx list                               # List installed stdx versions
                      cjvs stdx install 1.0.0                      # Install stdx (auto-download)
                      cjvs stdx install 1.0.0 ~/Downloads/stdx.zip # Install from local zip
                      cjvs stdx use 1.0.0                          # Switch stdx version
                      cjvs stdx use 1.0.0 static                   # Switch with static library
                      cjvs stdx default 1.0.0                      # Set default stdx version
                      cjvs stdx default 1.0.0 dynamic              # Set default with dynamic library
                      cjvs stdx config static                      # Set default library type
                      cjvs stdx remove 1.0.0                       # Remove stdx version
                    note:
                      available versions: https://atomgit.com/Cangjie/cangjie_stdx/releases
                      (the online list API needs a token, so cjvs does not list remote versions)
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