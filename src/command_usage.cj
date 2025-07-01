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

GLOBAL OPTIONS:
  --help, -h     show help
  --version, -v  print the version
"""
    )
}