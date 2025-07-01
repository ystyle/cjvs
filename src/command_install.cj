package cjvs

import std.fs.{Directory, File, Path, removeIfExists, exists, rename}
import std.io.{copy}

// 安装版本
func install(args: Array<String>) {
    if (args.size < 2) {
        println("cjvs install :version")
        return
    }
    let version = args[1]
    if (exists(Path(config.storeDir).join(version))) {
        println("already installed ${version}")
        return
    }
    if (args.size == 3) {
        // 安装本地文件
        let filepath = args[2]
        if (exists(filepath) && (filepath.endsWith(".zip") || filepath.endsWith(".tar.gz"))) {
            doinstallLocal(version, filepath)
            if (config.default.isNone()) {
                defaultVersion(["default", version])
            }
        } else {
            println("path: ${filepath}, is not a zip or tar.gz file")
        }
        return
    }
    let groups = getVersions()
    var versions = groups[config.channel]
    if (args.size >= 3 && ["beta", "lts"].contains(args[2]) && groups.contains(args[2])) {
        versions = groups[args[2]]
    }
    for (item in versions) {
        if (item.version == version) {
            doinstall(item)
            if (config.default.isNone()) {
                defaultVersion(["default", version])
            }
            return
        }
    }
    println("${version} is not found")
}

// 安装本地文件
func doinstallLocal(version: String, filepath: String): Unit {
    // 创建缓存文件夹
    if (!exists(config.cacheDir)) {
        Directory.create(config.cacheDir, recursive: true)
    }
    // 解压
    let extractDir = Directory.createTemp(config.cacheDir)
    var ext = Path(filepath).extensionName
    if (ext == "gz") {
        ext = "tar.gz"
    }
    uncompress(ext, filepath, extractDir.toString())

    // 移动到安装目录
    let tempCangjieHome = extractDir.join("cangjie")
    let versionDir = Path(config.storeDir).join(version)
    rename(tempCangjieHome, to: versionDir)
    // 删除缓存目录
    removeIfExists(config.cacheDir, recursive: true)
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
        if (!exists(config.cacheDir)) {
            Directory.create(config.cacheDir, recursive: true)
        }
        // download
        let downloadedFile = File.createTemp(config.cacheDir)
        copy(res.body, to: downloadedFile)
        // 解压
        let extractDir = Directory.createTemp(config.cacheDir)
        uncompress(version.ext, downloadedFile.info.path.toString(), extractDir.toString())
        // 移动到安装目录
        let tempCangjieHome = extractDir.join("cangjie")
        let versionDir = Path(config.storeDir).join(version.version)
        rename(tempCangjieHome, to: versionDir)
        println("install success.")
    } finally {
        // 删除缓存文件
        removeIfExists(config.cacheDir, recursive: true)
    }
}
