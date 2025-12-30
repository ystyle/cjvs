package cjvs

import stdx.encoding.json.stream.JsonReader
import std.env.{getCommandLine, getVariable}
import std.fs.{Directory, File, exists, OpenMode}
import cjvs.stdx.{handleCommand, stdxEnv}
import cjvs.model.Config
import cjvs.config.{config, CJVS_MULTISHELL_PATH}
import cjvs.tools.{getAppConfigDir, getAppConfigFile, CurrentOS, ContainsArray}
import cjpminfo.*

let version: String = @ModuleVer("0.3.0")

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
        case "stdx" => handleCommand(args)
        case "stdx-env" => stdxEnv(args)
        case _ => println("unknow command.")
    }
}

func printVersion() {
    println("cjvs version ${version}")
}

func printConfig() {
    println("Add the following script to your shell configuration file:")
    println("")
    if (CurrentOS == "linux" || CurrentOS == "macos") {
        println("zsh:")
        println('\teval "$(cjvs env zsh)"')
        println("bash:")
        println('\teval "$(cjvs env bash)"')
        println("nushell:")
        println(
            """
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
    if (CurrentOS == "windows") {
        println("\teval (cjvs.exe env elvish | slurp)")
    } else {
        println("\teval (cjvs env elvish | slurp)")
    }
}

func check(): Bool {
    // 读取或创建配置文件
    let configdir = getAppConfigDir()
    config = if (exists(getAppConfigFile())) {
        let ff: File = File(getAppConfigFile(), OpenMode.Read)
        let conf = Config.fromJson(JsonReader(ff))
        conf.initPaths(configdir)
        conf
    } else {
        // 创建默认配置
        let conf = Config()
        conf.initPaths(configdir)
        // 创建应用目录
        if (!exists(configdir)) {
            Directory.create(configdir)
        }
        // 保存初始配置
        conf.save(getAppConfigFile())
        // 创建存储目录
        if (!exists(conf.storeDir)) {
            Directory.create(conf.storeDir)
        }
        conf
    }
    return true
}
