package cjvs

import std.fs.{exists, removeIfExists, SymbolicLink, Path}
import std.env.getVariable

// 切换版本
func switchVersion(args: Array<String>) {
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
    if (let Some(v) <- getVariable("CJVS_MULTISHELL_PATH")) {
        try {
            removeIfExists(v, recursive: true)
        } catch (e: Exception) {
            println(
                "Switch failed: remove CJVS_CANGJIE_HOME symbolic link failed: ${v} failed, please check permissions")
            return
        }
        try {
            SymbolicLink.create(Path(v), to: versiondir)
        } catch (e: Exception) {
            println("Switch failed: create symbolic link failed: ${v}, please check permissions")
            return
        }
        println("Switch success")
        println("Now using version: ${version}")
    } else {
        printConfig()
    }
}
