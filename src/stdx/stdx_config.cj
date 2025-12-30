package cjvs.stdx

import std.env.getVariable
import std.fs.{exists, removeIfExists, SymbolicLink, Path}
import cjvs.config.config
import cjvs.tools.{getAppConfigFile, CurrentOS, arch}

// 设置默认库类型
func stdxConfig(args: Array<String>) {
    if (args.size < 3) {
        println("Usage: cjvs stdx config <static|dynamic>")
        println("Current default type: ${config.stdxType}")
        return
    }

    let typeArg = args[2]
    if (typeArg != "static" && typeArg != "dynamic") {
        println("Error: library type must be 'static' or 'dynamic'")
        return
    }

    // 检查是否在多 shell 环境中
    if (let Some(stdxLinkPath) <- getVariable("CANGJIE_STDX_PATH")) {
        // 需要重新链接符号链接
        if (let Some(v) <- config.stdxDefault) {
            let newStdxRealPath = Path("${config.stdxDir}/${v}/${CurrentOS}_${arch}_llvm/${typeArg}/stdx")

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

            // 更新配置
            config.stdxType = typeArg
            config.save(getAppConfigFile())

            println("Library type switched to: ${typeArg}")
            println("Current stdx version: ${v}")
        } else {
            println("No default stdx version set")
        }
    } else {
        // 不在多 shell 环境中，只更新配置
        config.stdxType = typeArg
        config.save(getAppConfigFile())

        println("Default library type set to: ${typeArg}")
        if (let Some(v) <- config.stdxDefault) {
            println("Current stdx version: ${v}")
            println("Please restart your shell or run: eval \"\$(cjvs env bash -stdx)\"")
        } else {
            println("No default stdx version set")
        }
    }
}
