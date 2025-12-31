package cjvs.stdx

import std.fs.{Path, exists, removeIfExists}
import cjvs.config.config
import cjvs.tools.getAppConfigFile

// 删除 stdx 版本
func stdxRemove(args: Array<String>) {
    if (args.size < 3) {
        println("Usage: cjvs stdx remove <version>")
        return
    }

    let version = args[2]

    // 检查版本是否已安装
    if (!isStdxInstalled(version)) {
        println("stdx ${version} is not installed.")
        return
    }

    let versionPath = Path(config.stdxDir).join(version)

    // 直接删除整个版本目录
    try {
        _ = removeIfExists(versionPath, recursive: true)
        println("Removed stdx ${version}")
    } catch (e: Exception) {
        println("Failed to remove stdx ${version}: ${e}")
        return
    }

    // 如果删除的是当前默认版本，清除默认设置
    if (let Some(v) <- config.stdxDefault && v == version) {
        config.stdxDefault = None
        config.save(getAppConfigFile())
    }
}
