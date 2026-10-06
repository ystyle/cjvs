package cjvs.stdx

// 处理 stdx 子命令的分发器
public func handleCommand(args: Array<String>): Unit {
    if (args.size < 2) {
        println(
            """
Usage: cjvs stdx <list|install|use|default|config|remove|env> [args]
  list, ls                            List installed stdx versions.
  install, i <version> [zip-file]     Install stdx; without zip-file it downloads from atomgit.
  use <version> [static|dynamic]      Switch to use the specified stdx version.
  default <version> [static|dynamic]  Set the default stdx version.
  config <static|dynamic>             Set default library type.
  remove, rm <version>                Remove a specific stdx version.
  env <shell>                         Print CANGJIE_STDX_PATH for the current shell.

  Available versions: https://atomgit.com/Cangjie/cangjie_stdx/releases
  (the online list API needs a token, so cjvs does not list remote versions)
"""
        )
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
