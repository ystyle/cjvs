package cjvs.stdx

import std.fs.{Path, exists, Directory, removeIfExists, rename}
import cjvs.tools.{uncompress, getAppConfigFile}
import cjvs.config.config

// 安装 stdx 版本
func stdxInstall(args: Array<String>) {
    if (args.size < 4) {
        println("Usage: cjvs stdx install <version> <zip-file>")
        return
    }

    let version = args[2]
    let zipFile = args[3]

    // 检查是否已安装
    if (isStdxInstalled(version)) {
        println("stdx ${version} is already installed.")
        return
    }

    // 检查 zip 文件是否存在
    if (!exists(Path(zipFile))) {
        println("zip file not found: ${zipFile}")
        return
    }

    // 检查文件扩展名
    if (!zipFile.endsWith(".zip")) {
        println("file must be a .zip file")
        return
    }

    println("installing stdx ${version}...")

    // 创建 stdx 目录
    let stdxDir = Path(config.stdxDir)
    if (!exists(stdxDir)) {
        Directory.create(stdxDir)
    }

    // 创建缓存目录
    if (!exists(Path(config.cacheDir))) {
        Directory.create(config.cacheDir, recursive: true)
    }

    // 解压到临时目录
    let extractDir = Directory.createTemp(config.cacheDir)
    println("extracting...")
    uncompress("zip", zipFile, extractDir.toString())

    // 移动到目标目录
    let targetDir = stdxDir.join(version)
    rename(extractDir, to: targetDir)

    // 删除缓存目录
    removeIfExists(config.cacheDir, recursive: true)

    println("stdx ${version} installed successfully.")

    // 如果是第一个安装的版本，设置为默认
    if (let None <- config.stdxDefault) {
        config.stdxDefault = Some(version)
        config.save(getAppConfigFile())
        println("${version} is set as default stdx.")
    }
}
