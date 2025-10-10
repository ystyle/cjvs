package cjvs

import std.env.getVariable
import std.fs.{Directory, Path, SymbolicLink, HardLink, exists}
import std.time.DateTime
import std.env.getProcessId
@When[os == "Linux"]
import std.posix.{getuid}

@When[os == "Linux"]
func genenv(args: Array<String>) {
    if (args.size != 2) {
        println("cjvs env :shell")
        return
    }
    let uid = getuid()
    let pid = getProcessId()
    let unix = DateTime.now().toUnixTimeStamp().toMilliseconds()
    let shellpath = "/run/user/${uid}/cjvs_multishells/${pid}_${unix}"
    // 创建目录
    if (!exists(Path(shellpath).parent)) {
        Directory.create(Path(shellpath).parent, recursive: true)
    }
    if (let Some(v) <- config.default) {
        let defaultV = Path(config.storeDir).join(v)
        SymbolicLink.create(Path(shellpath), to: defaultV)
    }
    let shell = args[1]
    match (shell) {
        case "bash" | "zsh" =>
            let shellSource = """
export CJVS_MULTISHELL_PATH="${shellpath}"
export CANGJIE_HOME="${shellpath}"
export PATH=$CJVS_MULTISHELL_PATH/bin:$CJVS_MULTISHELL_PATH/tools/bin:$CJVS_MULTISHELL_PATH/debugger/bin:$PATH:$HOME/.cjpm/bin
export LD_LIBRARY_PATH=$CJVS_MULTISHELL_PATH/runtime/lib/linux_$(uname -m)_llvm:$CJVS_MULTISHELL_PATH/tools/lib:$LD_LIBRARY_PATH
"""
            println(shellSource)
        case "nushell" =>
            let nushellSource = """
export-env {
    let root = '${shellpath}'
    $env.CANGJIE_HOME = $root
    $env.CJVS_MULTISHELL_PATH = $root
    $env.PATH = ([
        ($root | path join 'bin')
        ($root | path join 'tools/bin')
        ($root | path join 'tools/lib')
    ] | append $env.PATH | uniq)
    $env.LD_LIBRARY_PATH = ([
        ($root | path join '/runtime/lib/linux_' + $nu.os-info.arch + '_llvm')
        ($root | path join 'tools/lib')
    ] | append $env.LD_LIBRARY_PATH | uniq)
}
"""
            println(nushellSource)
        case "elvish" =>
            let elvishSource = """
set-env CANGJIE_HOME "${shellpath}"
set-env CJVS_MULTISHELL_PATH "${shellpath}"
set-env PATH $E:CJVS_MULTISHELL_PATH"/bin"":"$E:CJVS_MULTISHELL_PATH"/tools/bin"":"$E:CJVS_MULTISHELL_PATH"/debugger/bin"":"$E:PATH":"$E:HOME"/.cjpm/bin"
set-env LD_LIBRARY_PATH $E:CJVS_MULTISHELL_PATH"/runtime/lib/linux_"(uname -m)"_llvm"":"$E:CJVS_MULTISHELL_PATH"/tools/lib"":"$E:LD_LIBRARY_PATH
"""
            println(elvishSource)
        case _ => println("unsupport shell")
    }
}

@When[os == "Windows"]
func genenv(args: Array<String>) {
    if (args.size != 2) {
        println("cjvs env :shell")
        return
    }
    let dir = getAppConfigDir()
    let unix = DateTime.now().toUnixTimeStamp().toMilliseconds()
    let pid = getProcessId()
    let shellpath = Path(dir).join("cjvs_multishells").join("${pid}_${unix}")
    // 创建目录
    if (!exists(shellpath.parent)) {
        Directory.create(shellpath.parent, recursive: true)
    }
    if (let Some(v) <- config.default) {
        let defaultV = Path(config.storeDir).join(v)
        SymbolicLink.create(shellpath, to: defaultV)
        // HardLink.create(shellpath, to: defaultV)
    }
    let shell = args[1]
    let path = getVariable("PATH") ?? ""
    match (shell) {
        case "powershell" =>
            println('$env:CANGJIE_HOME = \"${shellpath}\"')
            println('$env:CJVS_MULTISHELL_PATH = \"${shellpath}\"')
            println(
                '$env:PATH = \"${shellpath}\\bin;${shellpath}\\tools\\bin;${shellpath}\\tools\\lib;${shellpath}\\debugger\\bin;${shellpath}\\runtime\\lib\\windows_x86_64_llvm;${path}\"')
        case "nushell" =>
            let nushellSource = """
export-env {
let root = '${shellpath}'
$env.CANGJIE_HOME = $root
$env.CJVS_MULTISHELL_PATH = $root
$env.PATH = ([
    ($root | path join 'bin')
    ($root | path join 'tools/bin')
    ($root | path join 'tools/lib')
    ($root | path join 'debugger/bin')
    ($root | path join 'runtime/lib/windows_x86_64_llvm')
] | append $env.PATH | uniq)
}
"""
            println(nushellSource)
        case "elvish" =>
            let elvishSource = """
set-env CJVS_MULTISHELL_PATH "${shellpath}"
set-env CANGJIE_HOME "${shellpath}"
set-env PATH $E:CJVS_MULTISHELL_PATH"\\bin"":"$E:CJVS_MULTISHELL_PATH"\\tools\\bin"":"$E:CJVS_MULTISHELL_PATH"\\debugger\\bin"":"$E:PATH":"$E:HOME"\\.cjpm\\bin"
set-env LD_LIBRARY_PATH $E:CJVS_MULTISHELL_PATH"\\runtime\\lib\\windows_x86_64_llvm"":"$E:CJVS_MULTISHELL_PATH"\\tools\\lib"":"$E:LD_LIBRARY_PATH
"""
            println(elvishSource)
        case _ => println("unsupport shell")
    }
}
