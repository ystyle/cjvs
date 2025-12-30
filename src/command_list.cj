package cjvs

import std.fs.{Path, exists, FileInfo, SymbolicLink}
import std.sort.sort
import std.env.getVariable
import cjvs.config.{config}
import cjvs.tools.listdir

// 列出本地已安装的版本
func listVersion(_: Array<String>) {
    let configdir = Path(config.storeDir)
    var dirs = listdir(configdir).toArray()
    var used: ?Path = None

    if (let Some(v) <- getVariable("CJVS_MULTISHELL_PATH") && exists(v)) {
        let h = Path(v)
        used = h
        // 读取到软连接: 正常应该都是软链接才对
        if (FileInfo(h).isSymbolicLink()) {
            used = SymbolicLink.readFrom(h)
        }
    }

    if (dirs.size > 0) {
        sort<Path, String>(dirs, key: {p => p.fileName})
    }

    println("Installed Cangjie versions(makr up * is in used):")
    for (dir in dirs) {
        print("\t")
        if (let Some(p) <- used) {
            if (p == dir) {
                print("* ")
            } else {
                print("  ")
            }
        } else {
            print("  ")
        }
        println(dir.fileName)
    }
}
