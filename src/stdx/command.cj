package cjvs.stdx

// 处理 stdx 子命令的分发器
public func handleCommand(args: Array<String>): Unit {
    if (args.size < 2) {
        println("Usage: cjvs stdx <list|install|use|default|config|remove|env> [args]")
        return
    }

    let subCommand = args[1]

    match (subCommand) {
        case "list" | "ls" => stdxList(args)
        case "install" | "i" => stdxInstall(args)
        case "switch" | "use" => stdxSwitch(args)
        case "default" => stdxDefault(args)
        case "config" => stdxConfig(args)
        case "remove" | "rm" => stdxRemove(args)
        case "env" => stdxEnv(args)
        case _ => println("unknown stdx command: ${subCommand}\nUsage: cjvs stdx <list|install|use|default|config|remove|env> [args]")
    }
}
