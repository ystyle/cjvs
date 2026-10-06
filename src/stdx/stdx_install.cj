package cjvs.stdx

import std.fs.{Path, exists, Directory, removeIfExists, rename, File}
import std.io.copy
import cjvs.tools.{uncompress, getAppConfigFile, getHttpClient, CurrentOS, arch}
import cjvs.config.defaultConfig

// 安装 stdx 版本
func stdxInstall(args: Array<String>) {
    if (args.size < 3) {
        println("Usage: cjvs stdx install <version> [zip-file]")
        println("  <version>: stdx version to install")
        println("  zip-file : local zip file (optional)")
        println("             when omitted, downloads cangjie-stdx-<os>-<arch>-<version>.zip from atomgit")
        println("")
        println("Available versions: https://atomgit.com/Cangjie/cangjie_stdx/releases")
        println("  (the online list API needs a token, so cjvs does not list remote versions)")
        return
    }

    let version = args[2]
    let zipFile = if (args.size >= 4) { args[3] } else { "" }

    if (isStdxInstalled(version)) {
        println("stdx ${version} is already installed.")
        return
    }

    println("installing stdx ${version}...")

    let stdxDir = Path(defaultConfig.stdxDir)
    if (!exists(stdxDir)) {
        Directory.create(stdxDir)
    }

    if (!exists(Path(defaultConfig.cacheDir))) {
        Directory.create(defaultConfig.cacheDir, recursive: true)
    }

    var actualZip = zipFile
    if (zipFile == "") {
        let osName = if (CurrentOS == "macos") { "mac" } else { CurrentOS }
        let archName = if (arch == "x86_64") { "x64" } else { arch }
        let url = "https://atomgit.com/Cangjie/cangjie_stdx/releases/download/v${version}/cangjie-stdx-${osName}-${archName}-${version}.zip"
        println("downloading from atomgit...")
        let client = getHttpClient()
        let res = client.get(url)
        if (res.status != 200) {
            println("download failed: HTTP ${res.status}")
            return
        }
        let downloadedFile = File.createTemp(defaultConfig.cacheDir)
        copy(res.body, to: downloadedFile)
        actualZip = downloadedFile.info.path.toString()
        println("download complete.")
    } else {
        if (!exists(Path(actualZip))) {
            println("zip file not found: ${actualZip}")
            return
        }
        if (!actualZip.endsWith(".zip")) {
            println("file must be a .zip file")
            return
        }
    }

    let extractDir = Directory.createTemp(defaultConfig.cacheDir)
    println("extracting...")
    uncompress("zip", actualZip, extractDir.toString())

    let targetDir = stdxDir.join(version)
    rename(extractDir, to: targetDir)

    removeIfExists(defaultConfig.cacheDir, recursive: true)

    println("stdx ${version} installed successfully.")

    if (let None <- defaultConfig.stdxDefault) {
        defaultConfig.stdxDefault = Some(version)
        defaultConfig.save(getAppConfigFile())
        println("${version} is set as default stdx.")
    }
}