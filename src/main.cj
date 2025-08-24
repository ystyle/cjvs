package cjvs

import encoding.json.stream.JsonReader
import std.env.{getCommandLine,  getVariable}
import std.fs.{Directory, File, Path, exists, OpenMode}

var config = Config()
var version = "1.0.0"
var CJVS_MULTISHELL_PATH = ""

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
    if (let None <- getVariable("CJVS_MULTISHELL_PATH")) {
        if (!args.containsAny(["env"])) {
            printConfig()
            return
        }
    } else {
        CJVS_MULTISHELL_PATH = getVariable("CJVS_MULTISHELL_PATH") ?? ""
    }

    // 检查设置
    if (!check()) {
        return
    }
    let command = args[0]

    // 执行命令
    match (command) {
        case "list" | "ls" => listVersion(args)
        case "rls" | "ls-remote" => remote(args)
        case "install" | "i" => install(args)
        case "switch" | "use" | "s" => switchVersion(args)
        case "default" => defaultVersion(args)
        case "remove" | "rm" => removeVersion(args)
        case "env" => genenv(args)
        case _ => println("unknow command.")
    }
}

func printVersion() {
    println("cjvs version ${version}")
}

func printConfig() {
    println("Add the following script to your shell configuration file:")
    println("")
    if (CurrentOS == "linux") {
        println("zsh:")
        println('\teval "$(cjvs env zsh)"')
        println("bash:")
        println('\teval "$(cjvs env bash)"')
        println("nushell:")
        println("""
if (is-admin) {
  cjvs env nushell | save -f ~/.cjvs.nu
  use ~/.cjvs.nu
  echo "cjvs loaded."
}
""")
    }
    if (CurrentOS == "windows") {
        println("powershell:")
        println("\tcjvs.exe env powershell | Out-String | Invoke-Expression")
        println("nushell:")
        println("""
    if (is-admin) {
        cjvs env nushell | save -f ~/.cjvs.nu
        use ~/.cjvs.nu
    }
""")
    }

    println("elvish:")
    println("\teval (cjvs.exe env elvish | slurp)")
    
}

func check(): Bool {
    // 读取或创建配置文件
    config = if (exists(getAppConfigFile())) {
        let ff: File = File(getAppConfigFile(), OpenMode.Read)
        Config.fromJson(JsonReader(ff))
    } else {
        // 创建默认配置
        let conf = Config()
        // 创建应用目录
        let configdir = getAppConfigDir()
        if (!exists(configdir)) {
            Directory.create(configdir)
        }
        // 保存初始配置
        conf.save()
        // 创建存储目录
        if (!exists(config.storeDir)) {
            Directory.create(config.storeDir)
        }
        conf
    }
    return true
}
