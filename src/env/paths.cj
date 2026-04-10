package cjvs.env

import std.fs.{Path, exists}
import std.collection.ArrayList
import cjvs.tools.{CurrentOS, arch}
import cjvs.config.config

// ==================== 路径模板字符串常量 ====================

// PATH 环境变量相对路径
public let BIN_PATH = "bin"
public let TOOLS_BIN_PATH = "tools/bin"
public let TOOLS_LIB_PATH = "tools/lib"
public let DEBUGGER_BIN_PATH = "debugger/bin"
public let DEBUGGER_LIB_PATH = "debugger/third_party/lldb/lib"

// 运行时库路径模板 (os 和 arch 是占位符，由 render 替换)
public let RUNTIME_LIB_LLVM = "runtime/lib/%s_%s_llvm"
public let RUNTIME_LIB_CJNATIVE = "runtime/lib/%s_%s_cjnative"
public let LIB_JET = "lib/%s_x86_64_jet"

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

// stdx 路径生成（支持新旧目录结构）
public func getStdxPath(version: String, libType: String): String {
    let osName = if (CurrentOS == "macos") { "macos" } else if (CurrentOS == "windows") { "windows" } else { "linux" }
    let versionBasePath = Path("${config.stdxDir}/${version}")
    
    let runtimeTypes = ["llvm", "cjnative"]
    for (runtimeType in runtimeTypes) {
        let testPath = versionBasePath.join("${osName}_${arch}_${runtimeType}").join(libType).join("stdx")
        if (exists(testPath)) {
            return testPath.toString()
        }
    }
    
    versionBasePath.join("${osName}_x86_64_llvm").join(libType).join("stdx").toString()
}

// 获取 PATH 环境变量路径列表
public func getEnvPaths(home: Path): ArrayList<Path> {
    ArrayList<Path>([
        binPath(home),
        toolsBinPath(home),
        debuggerBinPath(home),
    ])
}

// 获取 LD_LIBRARY_PATH 路径列表
public func getLibPaths(home: Path): ArrayList<Path> {
    let paths = runtimeLibPaths(home)
    paths.add(all: [toolsLibPath(home), debuggerLibPath(home)])
    paths
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