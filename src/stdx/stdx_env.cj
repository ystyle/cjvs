package cjvs.stdx

import std.fs.Path
import cjvs.config.config
import cjvs.env.renderStdxEnv

@When[os == "Linux"]
public func stdxEnv(args: Array<String>) {
    stdxEnvUnix(args, "linux")
}

@When[os == "macOS"]
public func stdxEnv(args: Array<String>) {
    stdxEnvUnix(args, "macos")
}

func stdxEnvUnix(args: Array<String>, os: String) {
    if (args.size < 2 || (args[0] != "stdx-env" && args.size < 3)) {
        println("Usage: cjvs stdx-env <shell>")
        println("       cjvs stdx env <shell>")
        println("")
        println("Available shells: bash, zsh, fish, nushell, elvish")
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

    println(renderStdxEnv(shell, stdxPath))
}

@When[os == "Windows"]
public func stdxEnv(args: Array<String>) {
    if (args.size < 2 || (args[0] != "stdx-env" && args.size < 3)) {
        println("Usage: cjvs stdx-env <shell>")
        println("       cjvs stdx env <shell>")
        println("")
        println("Available shells: powershell, nushell, fish, elvish")
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

    println(renderStdxEnv(shell, stdxPath))
}
