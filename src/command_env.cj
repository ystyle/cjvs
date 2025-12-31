package cjvs

import std.env.getProcessId
import std.fs.{Directory, Path, SymbolicLink, exists}
import std.time.DateTime
import cjvs.config.config
import cjvs.tools.ContainsArray

@When[os == "Linux"]
func genenv(args: Array<String>) {
    genenvUnix(args, "linux")
}

@When[os == "macOS"]
func genenv(args: Array<String>) {
    genenvUnix(args, "macos")
}

// Unix-like 系统（Linux/macOS）的通用环境生成函数
func genenvUnix(args: Array<String>, os: String) {
    if (args.size < 2) {
        println("cjvs env :shell")
        return
    }

    // 解析参数
    let appendLdLibraryPath = !args.containsAny(["-no-ld-library-path"])
    let enableStdx = args.containsAny(["-stdx"])

    let pid = getProcessId()
    let unix = DateTime.now().toUnixTimeStamp().toMilliseconds()
    let shellpath = "/tmp/cjvs_multishells/${pid}_${unix}"

    // 创建目录
    if (!exists(Path(shellpath).parent)) {
        Directory.create(Path(shellpath).parent, recursive: true)
    }
    if (let Some(v) <- config.default) {
        let defaultV = Path(config.storeDir).join(v)
        SymbolicLink.create(Path(shellpath), to: defaultV)
    }

    // 创建 stdx 符号链接
    var stdxPath = ""
    if (enableStdx && let Some(v) <- config.stdxDefault) {
        let libType = config.stdxType
        let osName = if (os == "macos") {
            "macos"
        } else {
            "linux"
        }
        let stdxRealPath = Path("${config.stdxDir}/${v}/${osName}_x86_64_llvm/${libType}/stdx")
        let stdxLinkPath = Path("/tmp/cjvs_multishells/stdx_${pid}_${unix}")

        // 创建符号链接，target 指向实际的 stdx 目录
        // 这样 CANGJIE_STDX_PATH 指向一个真实存在的目录（符号链接）
        SymbolicLink.create(stdxLinkPath, to: stdxRealPath)
        stdxPath = stdxLinkPath.toString()
    }

    let shell = args[1]
    match (shell) {
        case "bash" | "zsh" =>
            // LD_LIBRARY_PATH 路径配置
            let libPath = "\$CANGJIE_HOME/runtime/lib/${os}_\$(uname -m)_llvm:\$CANGJIE_HOME/runtime/lib/${os}_\$(uname -m)_cjnative:\$CANGJIE_HOME/lib/${os}_x86_64_jet:\$CANGJIE_HOME/tools/lib:\$CANGJIE_HOME/debugger/third_party/lldb/lib"

            let ldLibraryPathLine = if (appendLdLibraryPath) {
                "export LD_LIBRARY_PATH=${libPath}:\$LD_LIBRARY_PATH"
            } else {
                ""
            }

            let stdxLine = if (stdxPath.size > 0) {
                "export CANGJIE_STDX_PATH=\"${stdxPath}\""
            } else {
                ""
            }

            println(
                """
export CJVS_MULTISHELL_PATH="${shellpath}"
export CANGJIE_HOME="${shellpath}"
export PATH=\$CJVS_MULTISHELL_PATH/bin:\$CJVS_MULTISHELL_PATH/tools/bin:\$CJVS_MULTISHELL_PATH/debugger/bin:\$PATH:\$HOME/.cjpm/bin
${ldLibraryPathLine}
${stdxLine}

# Function to quickly set LD_LIBRARY_PATH for Cangjie
function cjenv() {
    export LD_LIBRARY_PATH=${libPath}:\$LD_LIBRARY_PATH
}
""")
        case "nushell" =>
            let ldLibraryBlock = if (appendLdLibraryPath) {
                """
    \$env.LD_LIBRARY_PATH = ([
        (\$root | path join '/runtime/lib/${os}_' + \$nu.os-info.arch + '_llvm')
        (\$root | path join '/runtime/lib/${os}_' + \$nu.os-info.arch + '_cjnative')
        (\$root | path join 'tools/lib')
    ] | append \$env.LD_LIBRARY_PATH | uniq)
"""
            } else {
                ""
            }

            let stdxLine = if (stdxPath.size > 0) {
                "    \$env.CANGJIE_STDX_PATH = '${stdxPath}'"
            } else {
                ""
            }

            println(
                """
export-env {
    let root = '${shellpath}'
    \$env.CANGJIE_HOME = \$root
    \$env.CJVS_MULTISHELL_PATH = \$root
    \$env.PATH = ([
        (\$root | path join 'bin')
        (\$root | path join 'tools/bin')
        (\$root | path join 'tools/lib')
    ] | append \$env.PATH | uniq)
${ldLibraryBlock}
${stdxLine}
}
""")
        case "elvish" =>
            // LD_LIBRARY_PATH 路径配置
            let libPath = "\$E:CANGJIE_HOME\"/runtime/lib/${os}_\"(uname -m)\"_llvm\":\$E:CANGJIE_HOME\"/runtime/lib/${os}_\"(uname -m)\"_cjnative\":\$E:CANGJIE_HOME\"/lib/${os}_x86_64_jet\":\$E:CANGJIE_HOME\"/tools/lib\":\$E:CANGJIE_HOME\"/debugger/third_party/lldb/lib"

            let ldLibraryPathLine = if (appendLdLibraryPath) {
                "set-env LD_LIBRARY_PATH ${libPath}:\$E:LD_LIBRARY_PATH"
            } else {
                ""
            }

            let stdxPathLine = if (stdxPath.size > 0) {
                "set-env CANGJIE_STDX_PATH \"${stdxPath}\""
            } else {
                ""
            }

            println(
                """
set-env CANGJIE_HOME "${shellpath}"
set-env CJVS_MULTISHELL_PATH "${shellpath}"
set-env PATH \$E:CJVS_MULTISHELL_PATH"/bin"":\$E:CJVS_MULTISHELL_PATH"/tools/bin"":\$E:CJVS_MULTISHELL_PATH"/debugger/bin"":\$E:PATH:\$E:HOME"/.cjpm/bin"
${ldLibraryPathLine}
${stdxPathLine}

# Function to quickly set LD_LIBRARY_PATH for Cangjie
fn cjenv {
    set-env LD_LIBRARY_PATH ${libPath}:\$E:LD_LIBRARY_PATH
}
""")
        case _ => println("unsupport shell")
    }
}

@When[os == "Windows"]
func genenv(args: Array<String>) {
    if (args.size < 2) {
        println("cjvs env :shell")
        return
    }

    // 解析参数
    let enableStdx = args.containsAny(["-stdx"])

    let dir = Path(getCommand()).parent.toString()
    let pid = getProcessId()
    let unix = DateTime.now().toUnixTimeStamp().toMilliseconds()
    let shellpath = Path(dir).join("cjvs_multishells").join("${pid}_${unix}")
    // 创建目录
    if (!exists(shellpath.parent)) {
        Directory.create(shellpath.parent, recursive: true)
    }
    if (let Some(v) <- config.default) {
        let defaultV = Path(config.storeDir).join(v)
        SymbolicLink.create(shellpath, to: defaultV)
    }

    // 创建 stdx 符号链接
    var stdxPath = ""
    if (enableStdx && let Some(v) <- config.stdxDefault) {
        let libType = config.stdxType
        let stdxRealPath = Path("${config.stdxDir}\\${v}\\windows_x86_64_llvm\\${libType}\\stdx")
        let stdxLinkPath = Path(dir).join("cjvs_multishells").join("stdx_${pid}_${unix}")

        // 目录已经在上面创建过了
        SymbolicLink.create(stdxLinkPath, to: stdxRealPath)
        stdxPath = stdxLinkPath.toString()
    }

    let shell = args[1]
    let path = getVariable("PATH") ?? ""
    match (shell) {
        case "powershell" =>
            println('$env:CANGJIE_HOME = \"${shellpath}\"')
            println('$env:CJVS_MULTISHELL_PATH = \"${shellpath}\"')
            println(
                '$env:PATH = \"${shellpath}\\bin;${shellpath}\\tools\\bin;${shellpath}\\tools\\lib;${shellpath}\\debugger\\bin;${shellpath}\\runtime\\lib\\windows_x86_64_llvm;${shellpath}\\runtime\\lib\\windows_x86_64_cjnative;${path}\"')
            if (stdxPath.size > 0) {
                println("\$env:CANGJIE_STDX_PATH = \"${stdxPath}\"")
            }
        case "nushell" =>
            let stdxLine = if (stdxPath.size > 0) {
                "    \$env.CANGJIE_STDX_PATH = '${stdxPath}'"
            } else {
                ""
            }

            println(
                """
export-env {
let root = '${shellpath}'
\$env.CANGJIE_HOME = \$root
\$env.CJVS_MULTISHELL_PATH = \$root
\$env.PATH = ([
    (\$root | path join 'bin')
    (\$root | path join 'tools/bin')
    (\$root | path join 'tools/lib')
    (\$root | path join 'debugger/bin')
    (\$root | path join 'runtime/lib/windows_x86_64_llvm')
    (\$root | path join 'runtime/lib/windows_x86_64_cjnative')
] | append \$env.PATH | uniq)
${stdxLine}
}
""")
        case "elvish" =>
            let stdxLine = if (stdxPath.size > 0) {
                "set-env CANGJIE_STDX_PATH \"${stdxPath}\""
            } else {
                ""
            }

            println(
                """
set-env CJVS_MULTISHELL_PATH "${shellpath}"
set-env CANGJIE_HOME "${shellpath}"
set-env PATH \$E:CJVS_MULTISHELL_PATH"\\bin"":\$E:CJVS_MULTISHELL_PATH"\\tools\\bin"":\$E:CJVS_MULTISHELL_PATH"\\debugger\\bin"":\$E:PATH:\$E:HOME"\\.cjpm\\bin"
${stdxLine}

# Function to quickly set environment for Cangjie (Windows doesn't use LD_LIBRARY_PATH)
fn cjenv {
    # Windows doesn't use LD_LIBRARY_PATH
}
""")
        case _ => println("unsupport shell")
    }
}
