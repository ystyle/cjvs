package cjvs.stdx

import std.fs.{exists, removeIfExists, SymbolicLink, Path}
import cjvs.config.defaultConfig
import cjvs.tools.{getAppConfigFile, getStdxPath}

// 切换 stdx 版本
func stdxSwitch(args: Array<String>) {
    if (args.size < 3) {
        println("Usage: cjvs stdx use <version> [static|dynamic]")
        return
    }

    let version = args[2]

    // 检查版本是否已安装
    if (!isStdxInstalled(version)) {
        println("stdx ${version} is not installed.")
        return
    }

    // 设置当前版本的库类型
    var libType = "dynamic"
    if (args.size > 3) {
        let typeArg = args[3]
        if (typeArg == "static" || typeArg == "dynamic") {
            libType = typeArg
        } else {
            println("Error: library type must be 'static' or 'dynamic'")
            return
        }
    }

    // 始终更新配置文件
    defaultConfig.stdxDefault = Some(version)
    defaultConfig.stdxType = libType
    defaultConfig.save(getAppConfigFile())

    // 如果在多 shell 环境中，也更新符号链接
    if (let Some(stdxLinkPath) <- getStdxLinkPath()) {
        let newStdxRealPath = Path(getStdxPath(version, libType))

        if (!exists(newStdxRealPath)) {
            println("Error: stdx path not found: ${newStdxRealPath}")
            return
        }

        try {
            removeIfExists(stdxLinkPath, recursive: true)
        } catch (e: Exception) {
            println("Switch failed: remove symbolic link failed: ${stdxLinkPath}")
            return
        }

        try {
            SymbolicLink.create(Path(stdxLinkPath), to: newStdxRealPath)
        } catch (e: Exception) {
            println("Switch failed: create symbolic link failed: ${stdxLinkPath}")
            return
        }

        println("Switch success")
        println("Now using stdx version: ${version} (${libType})")
    } else {
        println("Default stdx version set to ${version} (${libType})")
        println("Please restart your shell or run: eval \"\$(cjvs stdx-env bash)\"")
    }
}
