package cjvs

import std.env.getVariable
import std.fs.{Directory, Path, SymbolicLink, exists}
import std.time.DateTime


@When[os == "Linux"]
import std.posix.{getuid, getpid}

@When[os == "Linux"]
func genenv(args: Array<String>) {
    if (args.size != 2) {
        println("cjvs env :shell")
        return
    }
    let uid = getuid()
    let pid = getpid()
    let unix = DateTime.now().toUnixTimeStamp().toMilliseconds()
    let shellpath = "/run/user/${uid}/cjvs_multishells/${pid}_${unix}"
    // 创建目录
    if (!exists(Path(shellpath).parent)) {
        Directory.create(Path(shellpath).parent, recursive: true)
    }
    let shell = args[1]
    match (shell) {
        case "bash" | "zsh" =>
            if (let Some(v) <- config.default) {
                let defaultV = Path(config.storeDir).join(v)
                SymbolicLink.create(Path(shellpath), to: defaultV)
            }
            println('export CJVS_MULTISHELL_PATH="${shellpath}"')
            println(
                'export PATH=$CJVS_MULTISHELL_PATH/bin:$CJVS_MULTISHELL_PATH/tools/bin:$CJVS_MULTISHELL_PATH/debugger/bin:$PATH:$HOME/.cjpm/bin'
            )
            println(
                'export LD_LIBRARY_PATH=$CJVS_MULTISHELL_PATH/runtime/lib/linux_$(uname -m)_llvm:$CJVS_MULTISHELL_PATH/tools/lib:$LD_LIBRARY_PATH'
            )
            // if (shell == "zsh") {
            //     println('rehash')
            // }
        case "powershell" =>
            let path = getVariable("PATH") ?? ""
            // println('$env:CJVS_MULTISHELL_PATH = \"${config.cangjieHome}\"')
            // println(
                // '$env:PATH = \"${config.cangjieHome}\\bin;${config.cangjieHome}\\tools\\bin;${config.cangjieHome}\\tools\\lib;${config.cangjieHome}\\debugger\\bin;${config.cangjieHome}\\runtime\\lib\\windows_x86_64_llvm;${path}\"'
            // )
        case _ => println("unsupport shell")
    }
}

@When[os != "Linux"]
func genenv(args: Array<String>) {
}