from std import os.{getArgs, getEnv, homeDir}
from std import os.posix.{symlink, remove}
from std import fs.{Directory, File, Path, FileInfo}
let ConfigPath = ".config/cjvs"
let StorePath = ".config/cjvs/store"
var CangjieHOME: String = ""

func usage() {
    println(
        """
Usage: cjvs [options...]
  list, ls     List Canjie installations.
  switch, s    Switch to use the specified version.
  remove, rm   Remove a specific version.

GLOBAL OPTIONS:
  --help, -h     show help
  --version, -v  print the version
"""
    )
}

func version() {
    println("cjvs version 0.0.7")
}

func check(): Bool {
    // 检查环境变量: CANGJIE_HOME
    let cangjieHomeOpt = getEnv("CANGJIE_HOME")
    if (let None <- cangjieHomeOpt) {
        println("Environment variable CANGJIE_HOME is empty.")
        return false
    }
    // 创建存储目录
    let homedir = homeDir()
    let configdir = homedir.info.path.join(ConfigPath)
    if (!Directory.exists(configdir)) {
        Directory.create(configdir)
    }
    let storedir = homedir.info.path.join(StorePath)
    if (!Directory.exists(storedir)) {
        Directory.create(storedir)
    }
    // 检查CANGJIE_HOME, 是否存在, 存在时, 非软连接时报错
    let cangjieHome = cangjieHomeOpt.getOrThrow()
    if (Directory.exists(cangjieHome) && !Directory(cangjieHome).info.isSymbolicLink()) {
        println("CANGJIE_HOME: ${cangjieHome} should be a symbolic link")
        return false
    }
    CangjieHOME = cangjieHome
    return true
}

main(): Unit {
    // 检查设置
    if (!check()) {
        return
    }
    let args = getArgs()
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
        println("CangjieHOME: ${CangjieHOME}")
    }
    // 执行命令
    match (command) {
        case "install" | "i" => install(args)
        case "list" | "ls" => listVersion(args)
        case "switch" | "s" => switchVersion(args)
        case "remove" | "rm" => removeVersion(args)
        case _ => println("unknow command.")
    }
}

func install(args: Array<String>) {
    // todo un
    println("no support yet")
}

func listVersion(args: Array<String>) {
    let homedir = homeDir()
    let configdir = homedir.info.path.join(StorePath)
    let dirs = Directory(configdir).directoryList()
    var used: ?FileInfo = None
    if (Directory.exists(CangjieHOME)) {
        used = FileInfo(CangjieHOME)
    }
    dirs.sortBy({ dir1, dir2 =>
        let name1 = dir1.path.fileName ?? ""
        let name2 = dir2.path.fileName ?? ""
        if (name1 < name2) {
            return Ordering.LT
        }
        if (name1 > name2) {
            return Ordering.GT
        }
        return Ordering.EQ
    })
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
        println("${dir.path.fileName??""}")
    }
}

func switchVersion(args: Array<String>) {
    if (args.size != 2) {
        println("cjvs switch :version")
        return
    }
    let version = args[1]
    let homedir = homeDir()
    let versiondir = homedir.info.path.join(StorePath).join(version)
    if (!Directory.exists(versiondir)) {
        println("${version} is not found.")
        return
    }
    if (Path(CangjieHOME).isSymbolicLink()) {
        let rd = remove(CangjieHOME)
        if (rd != 0) {
            println("delete CANGJIE_HOME: ${CangjieHOME} failed, please check permissions")
            return
        }
    }
    
    let sld = symlink(versiondir.toString(), CangjieHOME)
    if (sld != 0) {
        println("create symbolic link failed: ${CangjieHOME}, please check permissions")
        return
    }
    println("Switch success")
    println("Now using version: ${version}")
}

func removeVersion(args: Array<String>) {
    if (args.size != 2) {
        println("cjvs remove :version")
        return
    }
    let version = args[1]
    let homedir = homeDir()
    let versiondir = homedir.info.path.join(StorePath).join(version)
    if (!Directory.exists(versiondir)) {
        println("${version} is not found.")
        return
    }
    try {
        Directory.delete(versiondir, recursive: true)
    } catch (_) {
        println("not yet supported")
    }
}