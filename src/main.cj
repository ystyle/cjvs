package cjvs

import std.process.CurrentProcess
import std.fs.{Directory, File, Path, FileInfo, removeIfExists, exists, SymbolicLink, OpenMode, rename}
import std.io.{copy}
import net.http.{ClientBuilder}
import net.tls.TlsClientConfig
import encoding.json.stream.*
import std.collection.{HashMap, ArrayList}
import std.process.Process
// import zip4cj.*
// import compress.zlib.*
// import compress4cj.*
// import compress4cj.compress.*
// import compress4cj.compress.archivers.*
// import compress4cj.compress.compressors.*

let AppConfigPath = Path(".config/cjvs")
let ConfigFilePath = Path(".config/cjvs/config.json")
var config = Config()

main(): Unit {
    // 检查设置
    if (!check()) {
        return
    }
    let args = CurrentProcess.current.arguments
    // 打印使用帮助
    if (args.size == 0 || args.containsAny(["--help", "-h"])) {
        usage()
        return
    }
    // 打印版本
    if (args.containsAny(["--version", "-v"])) {
        version()
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
  remove, rm      Remove a specific version.

GLOBAL OPTIONS:
  --help, -h     show help
  --version, -v  print the version
"""
    )
}

func version() {
    println("cjvs version 0.0.9")
}

func check(): Bool {
    let homedir = CurrentProcess.current.homeDirectory
    // 检查环境变量: CANGJIE_HOME
    let cangjieHomeOpt = CurrentProcess.current.getEnv("CANGJIE_HOME")

    // 读取或创建配置文件
    config = if (exists(homedir.join(ConfigFilePath))) {
        let ff: File = File(homedir.join(ConfigFilePath), OpenMode.Read)
        let conf = Config.fromJson(JsonReader(ff))
        conf.cangjieHome = cangjieHomeOpt.getOrThrow()
        conf
    } else {
        // 创建默认配置
        let conf = Config()
        conf.cangjieHome = cangjieHomeOpt ?? homedir.join(".cangjie").toString()
        // 创建应用目录
        let configdir = homedir.join(AppConfigPath)
        if (!exists(configdir)) {
            Directory.create(configdir)
        }
        // 保存初始配置
        let ff: File = File(homedir.join(ConfigFilePath), OpenMode.Write)
        conf.toJson(JsonWriter(ff))
        // 创建存储目录
        let storedir = homedir.join(config.storeDir)
        if (!exists(config.storeDir)) {
            Directory.create(storedir)
        }
        conf
    }

    // 检查CANGJIE_HOME, 是否存在, 存在时, 非软连接时报错
    if (exists(config.cangjieHome) && !FileInfo(config.cangjieHome).isSymbolicLink()) {
        println("CANGJIE_HOME: ${config.cangjieHome} is not a symbolic link, you should remove it.")
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
        println("Channel: ${channel}")
        for (version in versions) {
            println("\t${version.version}")
        }
    }
}

// 获取当前系统可所有的可用版本列表
func getVersions(): HashMap<String, ArrayList<Version>> {
    let client = ClientBuilder().readTimeout(Duration.minute).tlsConfig(TlsClientConfig()).build()
    let res = client.get(config.index)
    let versions = Array<Version>.fromJson(JsonReader(res.body))
    let groups = HashMap<String, ArrayList<Version>>()
    for (version in versions) {
        if (version.os == CurrentOS && version.arch == arch) {
            if (groups.contains(version.channel)) {
                groups[version.channel].append(version)
            } else {
                groups[version.channel] = ArrayList<Version>(version)
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

// 下载并安装仓颉
func doinstall(version: Version): Unit {
    println("installing ${version.version}...")
    try {
        // 创建请求
        let client = ClientBuilder().readTimeout(Duration.hour).tlsConfig(TlsClientConfig()).build()
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
        match (version.ext) {
            case "zip" =>
                // let zipFile = ZipFile("demo.zip") // 创建ZipFile类
                // zipFile.setRunInThread(false) // 设置是否用子线程运行任务
                // zipFile.extractAll(config.cacheDir) // 解压到 output 文件夹, 文件夹不存在则创建
                // zipFile.close()
                let (status, out, outerr) = Process.runOutput("unzip", [downloadedFile.info.path.toString(), "-d", extractDir.toString()])
                if (status != 0) {
                    println("Install failed: ")
                    println(String.fromUtf8(out))
                    println(String.fromUtf8(outerr))
                    return
                }
             ()
            case "tar.gz" => 
                let (status, out, outerr) = Process.runOutput("tar", ["-zxf", downloadedFile.info.path.toString(), "-C", extractDir.toString()])
                if (status != 0) {
                    println("Install failed: ")
                    println(String.fromUtf8(out))
                    println(String.fromUtf8(outerr))
                    return
                }
            ()
            case _ => println("unsupport file format")
        }
        // 移动到安装目录
        let tempCangjieHome = extractDir.join("cangjie")
        let versionDir = Path(config.storeDir).join(version.version)
        rename(tempCangjieHome, to: versionDir)
    } finally {
        // 删除缓存文件
        removeIfExists(config.cacheDir, recursive: true)
    }
}


// 列出本地已安装的版本
func listVersion(args: Array<String>) {
    let homedir = CurrentProcess.current.homeDirectory
    let configdir = Path(config.storeDir)
    let dirs = listdir(configdir)
    var used: ?Path = None
    if (exists(config.cangjieHome)) {
        let h = Path(config.cangjieHome)
        used = h
        // 读取到软连接: 正常应该都是软链接才对
        if (FileInfo(h).isSymbolicLink()) {
            used = SymbolicLink.readFrom(h)
        }
    }
    dirs.sortBy(
        stable: false,
        comparator: {
            dir1, dir2 =>
            let name1 = dir1.fileName
            let name2 = dir2.fileName
            if (name1 < name2) {
                return Ordering.LT
            }
            if (name1 > name2) {
                return Ordering.GT
            }
            return Ordering.EQ
        }
    )
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
    if (FileInfo(config.cangjieHome).isSymbolicLink()) {
        try {
            removeIfExists(config.cangjieHome, recursive: true)
        } catch (e: Exception) {
            println(
                "Switch failed: remove CANGJIE_HOME symbolic link failed: ${config.cangjieHome} failed, please check permissions"
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
    let homedir = CurrentProcess.current.homeDirectory
    let versiondir = Path(config.storeDir).join(version)
    if (!exists(versiondir)) {
        println("${version} is not found.")
        return
    }
    try {
        _ = removeIfExists(versiondir, recursive: true)
    } catch (e: Exception) {
        println("not yet supported")
    }
}
