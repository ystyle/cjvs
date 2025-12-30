package cjvs.stdx

import std.fs.{Path, exists}
import std.process.executeWithOutput
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

    // 删除 dynamic 和 static 目录
    let dynamicPath = versionPath.join("dynamic")
    let staticPath = versionPath.join("static")

    if (exists(dynamicPath)) {
        // 递归删除
        let (status, _, err) = executeWithOutput("rm", ["-rf", dynamicPath.toString()])
        if (status != 0) {
            println("Failed to remove dynamic: ${String.fromUtf8(err)}")
            return
        }
    }

    if (exists(staticPath)) {
        let (status, _, err) = executeWithOutput("rm", ["-rf", staticPath.toString()])
        if (status != 0) {
            println("Failed to remove static: ${String.fromUtf8(err)}")
            return
        }
    }

    // 删除版本目录（如果为空）
    let (status, _, _) = executeWithOutput("rmdir", ["--ignore-fail-on-non-empty", versionPath.toString()])
    if (status == 0) {
        println("Removed stdx ${version}")
    }

    // 如果删除的是当前默认版本，清除默认设置
    if (let Some(v) <- config.stdxDefault && v == version) {
        config.stdxDefault = None
        config.save(getAppConfigFile())
    }
}
