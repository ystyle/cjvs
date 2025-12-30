package cjvs

import std.fs.{Path, exists}
import cjvs.config.config
import cjvs.tools.getAppConfigFile

func defaultVersion(args: Array<String>) {
    if (args.size != 2) {
        println("cjvs switch :version")
        return
    }
    let version = args[1]
    let versiondir = Path(config.storeDir).join(version)
    if (!exists(versiondir)) {
        println("${version} is not found.")
        return
    }
    config.default = version
    config.save(getAppConfigFile())
    println("${version} is set as default version.")
}