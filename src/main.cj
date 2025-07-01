package cjvs

import std.process.CurrentProcess
import std.env.{getCommandLine, getHomeDirectory, getVariable}
import std.fs.{Directory, File, Path, FileInfo, removeIfExists, exists, SymbolicLink, OpenMode, rename}
import std.io.{copy}
import std.sort.sort
import encoding.json.stream.*
import std.collection.{HashMap, ArrayList}
import std.process.{Process, executeWithOutput}
// import zip4cj.*
// import compress.zlib.*
// import compress4cj.*
// import compress4cj.compress.*
// import compress4cj.compress.archivers.*
// import compress4cj.compress.compressors.*

let AppConfigPath = Path(".config/cjvs")
let ConfigFilePath = Path(".config/cjvs/config.json")
var config = Config()
var version = "0.0.16"

main(): Unit {
    let args = getCommandLine()[1..]
    // 打印使用帮助
    if (args.size == 0 || args.containsAny(["--help", "-h"])) {
        usage()
        return
    }
    // 打印版本
    if (args.containsAny(["--version", "-v"])) {
        printVersion()
        return
    }
    // 检查设置
    if (!check()) {
        return
    }
    let command = args[0]
    // 在调试模式打印仓颉home
    if (args.containsAny(["--debug"])) {
        println("CangjieHOME: ${config.cangjieHome}")
    }
    // 执行命令
    match (command) {
        case "rls" | "ls-remote" => remote(args)
        case "install" | "i" => install(args)
        case "list" | "ls" => listVersion(args)
        case "switch" | "use" | "s" => switchVersion(args)
        case "remove" | "rm" => removeVersion(args)
        case "env" => genenv(args)
        case _ => println("unknow command.")
    }
}

func usage() {
    println(
        """
Usage: cjvs [options...]
  list, ls        List Cangjie installations.
  switch, use     Switch to use the specified version.
  ls-remote, rls  List all remote Cangjie versions.
  install, i      Install a new Cangjie version. 
                    eg: 
                      cjvs install 0.53.13 # install online
                      cjvs install 0.59.6 ~/Downloads/cangjie-0.59.6-linux_x64.tar.gz # install a local version
  remove, rm      Remove a specific version.

GLOBAL OPTIONS:
  --help, -h     show help
  --version, -v  print the version
"""
    )
}

func printVersion() {
    println("cjvs version ${version}")
}

func check(): Bool {
    let homedir = getHomeDirectory()
    // 读取或创建配置文件
    config = if (exists(homedir.join(ConfigFilePath))) {
        let ff: File = File(homedir.join(ConfigFilePath), OpenMode.Read)
        Config.fromJson(JsonReader(ff))
    } else {
        // 创建默认配置
        let conf = Config()
        // 创建应用目录
        let configdir = homedir.join(AppConfigPath)
        if (!exists(configdir)) {
            Directory.create(configdir)
        }
        // 保存初始配置
        let ff: File = File(homedir.join(ConfigFilePath), OpenMode.Write)
        let jr = JsonWriter(ff)
        conf.toJson(jr)
        jr.flush()
        ff.flush()
        // 创建存储目录
        if (!exists(config.storeDir)) {
            Directory.create(config.storeDir)
        }
        conf
    }

    // 检查CANGJIE_HOME, 是否存在, 存在时, 非软连接时报错
    if (exists(config.cangjieHome) && !FileInfo(config.cangjieHome).isSymbolicLink()) {
        println("CJVS_CANGJIE_HOME: ${config.cangjieHome} is not a symbolic link, you should remove it.")
        return false
    }

    return true
}

// 在控制台列出所有的可用版本
func remote(args: Array<String>) {
    var showChannel = if (args.size >= 2 && ["beta", "lts"].contains(args[1])) {
        args[1]
    } else {
        "all"
    }
    let groups = getVersions()
    for ((channel, versions) in groups) {
        if (showChannel != "all" && channel != showChannel) {
            continue
        }
        sort(versions, key: {v => v.version})
        println("Channel: ${channel}")
        for (version in versions) {
            println("\t${version.version}")
        }
    }
}

// 获取当前系统可所有的可用版本列表
func getVersions(): HashMap<String, ArrayList<Version>> {
    let client = getHttpClient()
    let res = client.get(config.index)
    let versions = Array<Version>.fromJson(JsonReader(res.body))
    let groups = HashMap<String, ArrayList<Version>>()
    for (version in versions) {
        if (version.os == CurrentOS && version.arch == arch) {
            if (groups.contains(version.channel)) {
                groups[version.channel].add(version)
            } else {
                groups[version.channel] = ArrayList<Version>([version])
            }
        }
    }
    return groups
}

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

// 列出本地已安装的版本
func listVersion(args: Array<String>) {
    let configdir = Path(config.storeDir)
    var dirs = listdir(configdir).toArray()
    var used: ?Path = None
    if (exists(config.cangjieHome)) {
        let h = Path(config.cangjieHome)
        used = h
        // 读取到软连接: 正常应该都是软链接才对
        if (FileInfo(h).isSymbolicLink()) {
            used = SymbolicLink.readFrom(h)
        }
    }

    if (dirs.size > 0) {
        sort<Path, String>(dirs, key: {p => p.fileName})
    }

    println("Installed Cangjie versions(makr up * is in used):")
    for (dir in dirs) {
        print("\t")
        if (let Some(p) <- used) {
            if (p == dir) {
                print("* ")
            } else {
                print("  ")
            }
        } else {
            print("  ")
        }
        println(dir.fileName)
    }
}

// 切换版本
func switchVersion(args: Array<String>) {
    if (args.size != 2) {
        println("cjvs switch :version")
        return
    }
    let version = args[1]
    let versiondir = Path(config.storeDir).join(version)
    if (!exists(versiondir)) {
        println("${version} is not found.")
        return
    }
    if (!exists(config.cangjieHome) || FileInfo(config.cangjieHome).isSymbolicLink()) {
        try {
            removeIfExists(config.cangjieHome, recursive: true)
        } catch (e: Exception) {
            println(
                "Switch failed: remove CJVS_CANGJIE_HOME symbolic link failed: ${config.cangjieHome} failed, please check permissions"
            )
            return
        }
        try {
            SymbolicLink.create(Path(config.cangjieHome), to: versiondir)
        } catch (e: Exception) {
            println("Switch failed: create symbolic link failed: ${config.cangjieHome}, please check permissions")
            return
        }
        println("Switch success")
        println("Now using version: ${version}")
    } else {
        println("Switch failed: ${config.cangjieHome} is not a symbolic link, you should remove it manually")
    }
}

// 删除已安装版本
func removeVersion(args: Array<String>) {
    if (args.size != 2) {
        println("cjvs remove :version")
        return
    }
    let version = args[1]
    let versiondir = Path(config.storeDir).join(version)
    if (!exists(versiondir)) {
        println("${version} is not found.")
        return
    }
    var used: ?Path = None
    if (exists(config.cangjieHome)) {
        let h = Path(config.cangjieHome)
        used = h
        // 读取到软连接: 正常应该都是软链接才对
        if (FileInfo(h).isSymbolicLink()) {
            used = SymbolicLink.readFrom(h)
        }
    }
    if (let Some(u) <- used) {
        if (versiondir == u) {
            println("version: ${version} is inused.")
            return
        }
    }
    try {
        _ = removeIfExists(versiondir, recursive: true)
    } catch (e: Exception) {
        println("remote failed: ${e}")
    }
}

func genenv(args: Array<String>) {
    if (args.size != 2) {
        println("cjvs env :shell")
        return
    }
    let shell = args[1]
    match (shell) {
        case "bash" | "zsh" =>
            println('export CJVS_CANGJIE_HOME="$HOME/.cangjie"')
            println('export CANGJIE_HOME="$CJVS_CANGJIE_HOME"')
            println(
                'export PATH=$CANGJIE_HOME/bin:$CANGJIE_HOME/tools/bin:$CANGJIE_HOME/debugger/bin:$PATH:$HOME/.cjpm/bin'
            )
            println(
                'export LD_LIBRARY_PATH=$CANGJIE_HOME/runtime/lib/linux_$(uname -m)_llvm:$CANGJIE_HOME/tools/lib:$LD_LIBRARY_PATH'
            )
        case "powershell" =>
            let path = getVariable("PATH") ?? ""
            println('$env:CJVS_CANGJIE_HOME = \"${config.cangjieHome}\"')
            println(
                '$env:PATH = \"${config.cangjieHome}\\bin;${config.cangjieHome}\\tools\\bin;${config.cangjieHome}\\tools\\lib;${config.cangjieHome}\\debugger\\bin;${config.cangjieHome}\\runtime\\lib\\windows_x86_64_llvm;${path}\"'
            )
        case _ => println("unsupport shell")
    }
}
