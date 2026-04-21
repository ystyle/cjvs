package cjvs

import std.fs.{Directory, File, Path, removeIfExists, exists, rename}
import std.io.{copy}
import cjvs.config.defaultConfig
import cjvs.model.Version
import cjvs.tools.{getHttpClient, uncompress, getVersions}

// 安装版本
func install(args: Array<String>) {
    if (args.size < 2) {
        println("cjvs install :version")
        return
    }
    let version = args[1]
    if (args.size == 3) {
        if (exists(Path(defaultConfig.storeDir).join(version))) {
            println("already installed ${version}")
            return
        }
        // 安装本地文件
        let filepath = args[2]
        if (exists(filepath) && (filepath.endsWith(".zip") || filepath.endsWith(".tar.gz"))) {
            doinstallLocal(version, filepath)
            if (defaultConfig.default.isNone()) {
                defaultVersion(["default", version])
            }
        } else {
            println("path: ${filepath}, is not a zip or tar.gz file")
        }
        return
    }
    // 安装线上版本
    let groups = getVersions()
    for ((channel, versions) in groups) {
        for (item in versions) {
            if (item.version == version) {
                if (exists(Path(defaultConfig.storeDir).join(version))) {
                    println("already installed ${version}")
                    return
                }
                doinstall(item)
                if (defaultConfig.default.isNone()) {
                    defaultVersion(["default", version])
                }
                return
            }
        }
    }
    println("remote version: ${version} is not found")
}

// 安装本地文件
func doinstallLocal(version: String, filepath: String): Unit {
    // 创建缓存文件夹
    if (!exists(defaultConfig.cacheDir)) {
        Directory.create(defaultConfig.cacheDir, recursive: true)
    }
    // 解压
    let extractDir = Directory.createTemp(defaultConfig.cacheDir)
    var ext = Path(filepath).extensionName
    if (ext == "gz") {
        ext = "tar.gz"
    }
    uncompress(ext, filepath, extractDir.toString())

    // 移动到安装目录
    let tempCangjieHome = extractDir.join("cangjie")
    let versionDir = Path(defaultConfig.storeDir).join(version)
    rename(tempCangjieHome, to: versionDir)
    // 删除缓存目录
    removeIfExists(defaultConfig.cacheDir, recursive: true)
    println("install success.")
}

// 下载并安装仓颉
func doinstall(version: Version): Unit {
    println("installing ${version.version}...")
    try {
        // 创建请求
        let client = getHttpClient()
        let res = client.get(version.url)
        // 创建缓存文件夹
        if (!exists(defaultConfig.cacheDir)) {
            Directory.create(defaultConfig.cacheDir, recursive: true)
        }
        // download
        let downloadedFile = File.createTemp(defaultConfig.cacheDir)
        copy(res.body, to: downloadedFile)
        // 解压
        let extractDir = Directory.createTemp(defaultConfig.cacheDir)
        uncompress(version.ext, downloadedFile.info.path.toString(), extractDir.toString())
        // 移动到安装目录
        let tempCangjieHome = extractDir.join("cangjie")
        let versionDir = Path(defaultConfig.storeDir).join(version.version)
        rename(tempCangjieHome, to: versionDir)
        println("install success.")
    } finally {
        // 删除缓存文件
        removeIfExists(defaultConfig.cacheDir, recursive: true)
    }
}
