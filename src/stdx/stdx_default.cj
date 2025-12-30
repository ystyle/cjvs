package cjvs.stdx

import cjvs.config.config
import cjvs.tools.getAppConfigFile

// 设置默认 stdx 版本
func stdxDefault(args: Array<String>) {
    if (args.size < 3) {
        println("Usage: cjvs stdx default <version> [static|dynamic]")
        return
    }

    let version = args[2]

    // 检查版本是否已安装
    if (!isStdxInstalled(version)) {
        println("stdx ${version} is not installed.")
        return
    }

    // 设置默认库类型
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

    config.stdxDefault = Some(version)
    config.stdxType = libType
    config.save(getAppConfigFile())

    println("Default stdx version set to ${version} (${libType})")
}
