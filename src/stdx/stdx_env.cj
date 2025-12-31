package cjvs.stdx

import std.fs.Path
import cjvs.config.config

@When[os == "Linux"]
public func stdxEnv(args: Array<String>) {
    stdxEnvUnix(args, "linux")
}

@When[os == "macOS"]
public func stdxEnv(args: Array<String>) {
    stdxEnvUnix(args, "macos")
}

func stdxEnvUnix(args: Array<String>, os: String) {
    // 支持两种调用方式：
    // 1. cjvs stdx-env zsh -> args = ["stdx-env", "zsh"] -> shell = args[1]
    // 2. cjvs stdx env zsh -> args = ["stdx", "env", "zsh"] -> shell = args[2]
    if (args.size < 2 || (args[0] != "stdx-env" && args.size < 3)) {
        println("Usage: cjvs stdx-env <shell>")
        println("       cjvs stdx env <shell>")
        println("")
        println("Available shells: bash, zsh, nushell, elvish")
        return
    }

    let shell = if (args[0] == "stdx-env") { args[1] } else { args[2] }

    if (let None <- config.stdxDefault) {
        println("Error: No default stdx version set.")
        println("Use 'cjvs stdx default <version>' to set a default version.")
        return
    }

    let libType = config.stdxType
    let version = config.stdxDefault ?? ""
    let stdxPath = getStdxPath(version, libType)

    match (shell) {
        case "bash" | "zsh" =>
            println("export CANGJIE_STDX_PATH=\"${stdxPath}\"")
        case "nushell" =>
            println(
                """
export-env {
    \$env.CANGJIE_STDX_PATH = '${stdxPath}'
}
""")
        case "elvish" =>
            println("set-env CANGJIE_STDX_PATH \"${stdxPath}\"")
        case _ => println("unsupport shell: ${shell}")
    }
}

@When[os == "Windows"]
public func stdxEnv(args: Array<String>) {
    // 支持两种调用方式：
    // 1. cjvs stdx-env zsh -> args = ["stdx-env", "zsh"] -> shell = args[1]
    // 2. cjvs stdx env zsh -> args = ["stdx", "env", "zsh"] -> shell = args[2]
    if (args.size < 2 || (args[0] != "stdx-env" && args.size < 3)) {
        println("Usage: cjvs stdx-env <shell>")
        println("       cjvs stdx env <shell>")
        println("")
        println("Available shells: powershell, nushell, elvish")
        return
    }

    let shell = if (args[0] == "stdx-env") { args[1] } else { args[2] }

    if (let None <- config.stdxDefault) {
        println("Error: No default stdx version set.")
        println("Use 'cjvs stdx default <version>' to set a default version.")
        return
    }

    let libType = config.stdxType
    let version = config.stdxDefault ?? ""
    let stdxPath = getStdxPath(version, libType)

    match (shell) {
        case "powershell" =>
            println("\$env:CANGJIE_STDX_PATH = \"${stdxPath}\"")
        case "nushell" =>
            println(
                """
export-env {
    \$env.CANGJIE_STDX_PATH = '${stdxPath}'
}
""")
        case "elvish" =>
            println("set-env CANGJIE_STDX_PATH \"${stdxPath}\"")
        case _ => println("unsupport shell: ${shell}")
    }
}
