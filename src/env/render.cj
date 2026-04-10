package cjvs.env

import std.collection.ArrayList
import std.env.getVariable

// 主渲染函数
public func renderEnvScript(shell: String, shellpath: String, stdxPath: String, appendLdLibraryPath: Bool, os: String): String {
    match (shell) {
        case "bash" | "zsh" => renderBashZsh(shellpath, stdxPath, appendLdLibraryPath, os)
        case "fish" => renderFish(shellpath, stdxPath, appendLdLibraryPath, os)
        case "nushell" => renderNushell(shellpath, stdxPath, appendLdLibraryPath, os)
        case "elvish" => renderElvish(shellpath, stdxPath, appendLdLibraryPath, os)
        case "powershell" => renderPowershell(shellpath, stdxPath)
        case _ => "unsupport shell"
    }
}

// stdx-env 渲染函数
public func renderStdxEnv(shell: String, stdxPath: String): String {
    match (shell) {
        case "bash" | "zsh" => "export CANGJIE_STDX_PATH=\"${stdxPath}\""
        case "fish" => "set -x CANGJIE_STDX_PATH ${stdxPath}"
        case "nushell" => "\$env.CANGJIE_STDX_PATH = '${stdxPath}'"
        case "elvish" => "set-env CANGJIE_STDX_PATH \"${stdxPath}\""
        case "powershell" => "\$env:CANGJIE_STDX_PATH = \"${stdxPath}\""
        case _ => "unsupport shell: ${shell}"
    }
}

// ==================== Bash/Zsh 渲染方法 ====================

func renderBashZsh(shellpath: String, stdxPath: String, appendLdLibraryPath: Bool, os: String): String {
    let archExpr = "$(uname -m)"
    let homeVar = "\$CANGJIE_HOME"
    
    let paths = ArrayList<String>()
    paths.add("\$CJVS_MULTISHELL_PATH/${BIN_PATH}")
    paths.add("\$CJVS_MULTISHELL_PATH/${TOOLS_BIN_PATH}")
    paths.add("\$CJVS_MULTISHELL_PATH/${DEBUGGER_BIN_PATH}")
    
    let ldLibraryPathLine = if (appendLdLibraryPath) {
        let libPaths = buildRuntimeLibPaths(homeVar, os, archExpr)
        "export LD_LIBRARY_PATH=${joinStrings(libPaths, ":")}:\$LD_LIBRARY_PATH"
    } else {
        ""
    }
    
    let stdxLine = if (stdxPath.size > 0) {
        "export CANGJIE_STDX_PATH=\"${stdxPath}\""
    } else {
        ""
    }
    
    let cjenvLibPaths = buildRuntimeLibPaths(homeVar, os, archExpr)

    """
export CJVS_MULTISHELL_PATH="${shellpath}"
export CANGJIE_HOME="${shellpath}"
export PATH=${joinStrings(paths, ":")}:\$PATH:\$HOME/.cjpm/bin
${ldLibraryPathLine}
${stdxLine}

# Function to quickly set LD_LIBRARY_PATH for Cangjie
function cjenv() {
    export LD_LIBRARY_PATH=${joinStrings(cjenvLibPaths, ":")}:\$LD_LIBRARY_PATH
}
"""
}

// ==================== Fish 渲染方法 ====================

func renderFish(shellpath: String, stdxPath: String, appendLdLibraryPath: Bool, os: String): String {
    let archExpr = "(uname -m)"
    let homeVar = "\$CANGJIE_HOME"
    
    let paths = ArrayList<String>()
    paths.add("\$CJVS_MULTISHELL_PATH/${BIN_PATH}")
    paths.add("\$CJVS_MULTISHELL_PATH/${TOOLS_BIN_PATH}")
    paths.add("\$CJVS_MULTISHELL_PATH/${DEBUGGER_BIN_PATH}")
    
    let ldLibraryPathLine = if (appendLdLibraryPath) {
        let libPaths = buildRuntimeLibPaths(homeVar, os, archExpr)
        "set -x LD_LIBRARY_PATH ${joinStrings(libPaths, " ")} \$LD_LIBRARY_PATH"
    } else {
        ""
    }
    
    let stdxLine = if (stdxPath.size > 0) {
        "set -x CANGJIE_STDX_PATH ${stdxPath}"
    } else {
        ""
    }
    
    let cjenvLibPaths = buildRuntimeLibPaths(homeVar, os, archExpr)

    """
set -x CJVS_MULTISHELL_PATH "${shellpath}"
set -x CANGJIE_HOME "${shellpath}"
set -x PATH ${joinStrings(paths, " ")} \$PATH \$HOME/.cjpm/bin
${ldLibraryPathLine}
${stdxLine}

# Function to quickly set LD_LIBRARY_PATH for Cangjie
function cjenv
    set -x LD_LIBRARY_PATH ${joinStrings(cjenvLibPaths, " ")} \$LD_LIBRARY_PATH
end
"""
}

// ==================== Nushell 渲染方法 ====================

func renderNushell(shellpath: String, stdxPath: String, appendLdLibraryPath: Bool, os: String): String {
    let ldLibraryBlock = if (appendLdLibraryPath) {
        """
    \$env.LD_LIBRARY_PATH = ([
        (\$root | path join 'runtime/lib/${os}_' + \$nu.os-info.arch + '_llvm')
        (\$root | path join 'runtime/lib/${os}_' + \$nu.os-info.arch + '_cjnative')
        (\$root | path join 'lib/${os}_x86_64_jet')
        (\$root | path join '${TOOLS_LIB_PATH}')
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

    """
export-env {
    let root = '${shellpath}'
    \$env.CANGJIE_HOME = \$root
    \$env.CJVS_MULTISHELL_PATH = \$root
    \$env.PATH = ([
        (\$root | path join '${BIN_PATH}')
        (\$root | path join '${TOOLS_BIN_PATH}')
        (\$root | path join '${TOOLS_LIB_PATH}')
    ] | append \$env.PATH | uniq)
${ldLibraryBlock}${stdxLine}
}
"""
}

// ==================== Elvish 渲染方法 ====================

func renderElvish(shellpath: String, stdxPath: String, appendLdLibraryPath: Bool, os: String): String {
    let archExpr = "(uname -m)"
    let homeVar = "\$E:CANGJIE_HOME"
    
    let paths = ArrayList<String>()
    paths.add("\$E:CJVS_MULTISHELL_PATH\"/${BIN_PATH}\"")
    paths.add("\$E:CJVS_MULTISHELL_PATH\"/${TOOLS_BIN_PATH}\"")
    paths.add("\$E:CJVS_MULTISHELL_PATH\"/${DEBUGGER_BIN_PATH}\"")
    
    let ldLibraryPathLine = if (appendLdLibraryPath) {
        let libPaths = buildRuntimeLibPaths(homeVar, os, archExpr)
        "set-env LD_LIBRARY_PATH ${joinStrings(libPaths, ":")}:\$E:LD_LIBRARY_PATH"
    } else {
        ""
    }
    
    let stdxLine = if (stdxPath.size > 0) {
        "set-env CANGJIE_STDX_PATH \"${stdxPath}\""
    } else {
        ""
    }
    
    let cjenvLibPaths = buildRuntimeLibPaths(homeVar, os, archExpr)

    """
set-env CANGJIE_HOME "${shellpath}"
set-env CJVS_MULTISHELL_PATH "${shellpath}"
set-env PATH ${joinStrings(paths, ":")}:\$E:PATH:\$E:HOME"/.cjpm/bin"
${ldLibraryPathLine}
${stdxLine}

# Function to quickly set LD_LIBRARY_PATH for Cangjie
fn cjenv {
    set-env LD_LIBRARY_PATH ${joinStrings(cjenvLibPaths, ":")}:\$E:LD_LIBRARY_PATH
}
"""
}

// ==================== PowerShell 渲染方法 ====================

func renderPowershell(shellpath: String, stdxPath: String): String {
    let path = getVariable("PATH") ?? ""
    
    let allPaths = ArrayList<String>()
    allPaths.add("${shellpath}\\${BIN_PATH}")
    allPaths.add("${shellpath}\\${TOOLS_BIN_PATH}")
    allPaths.add("${shellpath}\\${TOOLS_LIB_PATH}")
    allPaths.add("${shellpath}\\${DEBUGGER_BIN_PATH}")
    allPaths.add("${shellpath}\\runtime\\lib\\windows_x86_64_llvm")
    allPaths.add("${shellpath}\\runtime\\lib\\windows_x86_64_cjnative")
    allPaths.add(path)
    
    let stdxLine = if (stdxPath.size > 0) {
        "\$env:CANGJIE_STDX_PATH = \"${stdxPath}\""
    } else {
        ""
    }

    """
\$env:CANGJIE_HOME = "${shellpath}"
\$env:CJVS_MULTISHELL_PATH = "${shellpath}"
\$env:PATH = "${joinStrings(allPaths, ";")}"
${stdxLine}

# Function to quickly set environment for Cangjie (Windows doesn't use LD_LIBRARY_PATH)
function cjenv {
    # Windows doesn't use LD_LIBRARY_PATH
}
"""
}