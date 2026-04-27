package cjvs.stdx

import cjvs.config.defaultConfig
import cjvs.tools.getStdxPath
import cjvs.env.renderStdxEnv

@When[os == "Linux"]
public func stdxEnv(args: Array<String>): Unit {
    stdxEnvUnix(args)
}

@When[os == "macOS"]
public func stdxEnv(args: Array<String>): Unit {
    stdxEnvUnix(args)
}

func stdxEnvUnix(args: Array<String>): Unit {
    if (args.size < 2 || (args[0] != "stdx-env" && args.size < 3)) {
        println("Usage: cjvs stdx-env <shell>")
        println("       cjvs stdx env <shell>")
        println("")
        println("Available shells: bash, zsh, fish, nushell, elvish")
        return
    }

    let shell = if (args[0] == "stdx-env") { args[1] } else { args[2] }

    if (let None <- defaultConfig.stdxDefault) {
        println("Error: No default stdx version set.")
        println("Use 'cjvs stdx default <version>' to set a default version.")
        return
    }

    let libType = defaultConfig.stdxType
    let version = defaultConfig.stdxDefault ?? ""
    let stdxPath = getStdxPath(version, libType)

    println(renderStdxEnv(shell, stdxPath))
}

@When[os == "Windows"]
public func stdxEnv(args: Array<String>): Unit {
    if (args.size < 2 || (args[0] != "stdx-env" && args.size < 3)) {
        println("Usage: cjvs stdx-env <shell>")
        println("       cjvs stdx env <shell>")
        println("")
        println("Available shells: powershell, nushell, fish, elvish")
        return
    }

    let shell = if (args[0] == "stdx-env") { args[1] } else { args[2] }

    if (let None <- defaultConfig.stdxDefault) {
        println("Error: No default stdx version set.")
        println("Use 'cjvs stdx default <version>' to set a default version.")
        return
    }

    let libType = defaultConfig.stdxType
    let version = defaultConfig.stdxDefault ?? ""
    let stdxPath = getStdxPath(version, libType)

    println(renderStdxEnv(shell, stdxPath))
}