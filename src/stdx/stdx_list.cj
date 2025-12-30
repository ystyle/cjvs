package cjvs.stdx

import std.fs.{Path, exists}
import std.sort.sort
import std.collection.ArrayList
import cjvs.tools.listdir
import cjvs.config.config

// 列出已安装的 stdx 版本
func stdxList(_: Array<String>) {
    let stdxDir = Path(config.stdxDir)

    if (!exists(stdxDir)) {
        println("No stdx versions installed.")
        return
    }

    var dirs = listdir(stdxDir).toArray()

    // 过滤掉 dynamic 和 static 目录
    var versions = ArrayList<Path>()
    for (dir in dirs) {
        let name = dir.fileName.toString()
        if (name != "dynamic" && name != "static") {
            versions.add(dir)
        }
    }

    if (versions.size > 0) {
        sort<Path, String>(versions.toArray(), key: {p => p.fileName})
    }

    if (versions.isEmpty()) {
        println("No stdx versions installed.")
        return
    }

    println("Installed stdx versions (* = current):")

    // 获取当前版本
    var currentVersion: ?String = config.stdxDefault

    for (versionPath in versions) {
        let version = versionPath.fileName.toString()
        let isCurrent = if (let Some(v) <- currentVersion) {
            v == version
        } else {
            false
        }

        print("\t")
        if (isCurrent) {
            print("* ")
        } else {
            print("  ")
        }

        // 检查安装的库类型
        let dynamicPath = versionPath.join("dynamic").join("stdx")
        let staticPath = versionPath.join("static").join("stdx")
        let hasDynamic = exists(dynamicPath)
        let hasStatic = exists(staticPath)

        let types = if (hasDynamic && hasStatic) {
            "(dynamic, static)"
        } else if (hasDynamic) {
            "(dynamic)"
        } else if (hasStatic) {
            "(static)"
        } else {
            ""
        }

        println("${version} ${types}")
    }
}
