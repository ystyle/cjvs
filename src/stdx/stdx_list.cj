package cjvs.stdx

import std.fs.{Path, exists, canonicalize}
import std.sort.sort
import std.collection.ArrayList
import cjvs.tools.listdir
import cjvs.config.defaultConfig

// 列出已安装的 stdx 版本
func stdxList(_: Array<String>) {
    let stdxDir = Path(defaultConfig.stdxDir)

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

    // 获取当前版本：优先从符号链接读取（多 shell 环境），否则从配置读取
    var currentVersion: ?String = None
    if (let Some(stdxLinkPath) <- getStdxLinkPath()) {
        // 在多 shell 环境中，从符号链接实际指向读取版本
        if (exists(Path(stdxLinkPath))) {
            try {
                // 读取符号链接指向的实际路径
                // 格式: <config.stdxDir>/<version>/<platform>/<libType>/stdx
                let realPath = canonicalize(Path(stdxLinkPath)).toString()
                // 去掉 stdxDir 前缀，获取相对路径
                let relativePath = if (realPath.size > defaultConfig.stdxDir.size && realPath.size > defaultConfig.stdxDir.size + 1) {
                    realPath[defaultConfig.stdxDir.size + 1..]
                } else {
                    ""
                }
                // 提取版本号（相对路径的第一部分）
                if (relativePath.size > 0) {
                    let version = relativePath.split("/")[0]
                    currentVersion = Some(version)
                }
            } catch (e: Exception) {
                // 如果读取符号链接失败，使用配置文件
                currentVersion = defaultConfig.stdxDefault
            }
        } else {
            currentVersion = defaultConfig.stdxDefault
        }
    } else {
        currentVersion = defaultConfig.stdxDefault
    }

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
