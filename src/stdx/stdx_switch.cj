package cjvs.stdx

import std.env.getVariable
import std.fs.{exists, removeIfExists, SymbolicLink, Path}
import cjvs.config.config
import cjvs.tools.{getAppConfigFile, CurrentOS, arch}

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

    // 检查是否在多 shell 环境中
    if (let Some(stdxLinkPath) <- getVariable("CANGJIE_STDX_PATH")) {
        // 计算新的 stdx 实际路径
        let newStdxRealPath = Path("${config.stdxDir}/${version}/${CurrentOS}_${arch}_llvm/${libType}/stdx")

        // 检查新路径是否存在
        if (!exists(newStdxRealPath)) {
            println("Error: stdx path not found: ${newStdxRealPath}")
            return
        }

        // 重新链接符号链接
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
        // 不在多 shell 环境中，只更新配置
        config.stdxDefault = Some(version)
        config.stdxType = libType
        config.save(getAppConfigFile())

        println("Default stdx version set to ${version} (${libType})")
        println("Please restart your shell or run: eval \"\$(cjvs stdx-env bash)\"")
    }
}
