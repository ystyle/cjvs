package cjvs
import std.fs.{Path, exists, removeIfExists, FileInfo, SymbolicLink}
import std.env.getVariable
import cjvs.config.config

// 删除已安装版本
func removeVersion(args: Array<String>) {
    if (args.size != 2) {
        println("cjvs remove :version")
        return
    }
    let version = args[1]
    let versiondir = Path(config.storeDir).join(version)
    if (!exists(versiondir)) {
        println("${version} is not found.")
        return
    }
    var used: ?Path = None
    if (let Some(v) <- getVariable("CJVS_MULTISHELL_PATH") && exists(v)) {
        let h = Path(v)
        used = h
        // 读取到软连接: 正常应该都是软链接才对
        if (FileInfo(h).isSymbolicLink()) {
            used = SymbolicLink.readFrom(h)
        }
    }
    if (let Some(u) <- used) {
        if (versiondir == u) {
            println("version: ${version} is inused.")
            return
        }
    }
    try {
        _ = removeIfExists(versiondir, recursive: true)
    } catch (e: Exception) {
        println("remote failed: ${e}")
    }
}