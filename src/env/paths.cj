package cjvs.env

import std.fs.Path
import std.collection.ArrayList
import cjvs.tools.CurrentOS
import cjvs.tools.arch

// ==================== 路径模板字符串常量 ====================

// PATH 环境变量相对路径
public let BIN_PATH: String = "bin"
public let TOOLS_BIN_PATH: String = "tools/bin"
public let TOOLS_LIB_PATH: String = "tools/lib"
public let DEBUGGER_BIN_PATH: String = "debugger/bin"
public let DEBUGGER_LIB_PATH: String = "debugger/third_party/lldb/lib"

// ==================== 实际路径（用于文件操作）====================

public func binPath(home: Path): Path { home.join(BIN_PATH) }
public func toolsBinPath(home: Path): Path { home.join(TOOLS_BIN_PATH) }
public func toolsLibPath(home: Path): Path { home.join(TOOLS_LIB_PATH) }
public func debuggerBinPath(home: Path): Path { home.join(DEBUGGER_BIN_PATH) }
public func debuggerLibPath(home: Path): Path { home.join(DEBUGGER_LIB_PATH) }

@When[os == "Linux" || os == "macOS"]
public func runtimeLibPaths(home: Path): ArrayList<Path> {
    let osName = CurrentOS
    ArrayList<Path>([
        home.join("runtime/lib/${osName}_${arch}_llvm"),
        home.join("runtime/lib/${osName}_${arch}_cjnative"),
        home.join("lib/${osName}_x86_64_jet"),
    ])
}

@When[os == "Windows"]
public func runtimeLibPaths(home: Path): ArrayList<Path> {
    ArrayList<Path>([
        home.join("runtime/lib/windows_x86_64_llvm"),
        home.join("runtime/lib/windows_x86_64_cjnative"),
    ])
}

// 字符串列表连接
public func joinStrings(list: ArrayList<String>, sep: String): String {
    var result = ""
    var first = true
    for (s in list) {
        if (!first) {
            result += sep
        }
        result += s
        first = false
    }
    result
}

// 构建运行时库路径列表
public func buildRuntimeLibPaths(homeVar: String, os: String, archExpr: String): ArrayList<String> {
    let paths = ArrayList<String>()
    paths.add("${homeVar}/runtime/lib/${os}_${archExpr}_llvm")
    paths.add("${homeVar}/runtime/lib/${os}_${archExpr}_cjnative")
    paths.add("${homeVar}/lib/${os}_x86_64_jet")
    paths.add("${homeVar}/${TOOLS_LIB_PATH}")
    paths.add("${homeVar}/${DEBUGGER_LIB_PATH}")
    paths
}