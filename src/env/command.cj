package cjvs.env

import std.env.{getProcessId, getVariable, getCommand}
import std.fs.{Directory, Path, SymbolicLink, exists}
import std.time.DateTime
import cjvs.config.config
import cjvs.tools.ContainsArray
import cjvs.tools.CurrentOS

@When[os == "Linux"]
public func genenv(args: Array<String>) {
    genenvUnix(args, "linux")
}

@When[os == "macOS"]
public func genenv(args: Array<String>) {
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

    // 创建目录和符号链接
    createMultishellPath(shellpath)
    
    // 创建 stdx 符号链接
    let stdxPath = createStdxLink(enableStdx, "/tmp/cjvs_multishells", pid, unix)

    let shell = args[1]
    println(renderEnvScript(shell, shellpath, stdxPath, appendLdLibraryPath, os))
}

@When[os == "Windows"]
public func genenv(args: Array<String>) {
    if (args.size < 2) {
        println("cjvs env :shell")
        return
    }

    // 解析参数
    let enableStdx = args.containsAny(["-stdx"])

    let dir = Path(getCommand()).parent.toString()
    let pid = getProcessId()
    let unix = DateTime.now().toUnixTimeStamp().toMilliseconds()
    let shellpath = Path(dir).join("cjvs_multishells").join("${pid}_${unix}").toString()
    
    // 创建目录和符号链接
    createMultishellPathWindows(shellpath)
    
    // 创建 stdx 符号链接
    let stdxPath = createStdxLinkWindows(enableStdx, dir, pid, unix)

    let shell = args[1]
    println(renderEnvScript(shell, shellpath, stdxPath, true, "windows"))
}

// 创建多 shell 符号链接路径
func createMultishellPath(shellpath: String) {
    if (!exists(Path(shellpath).parent)) {
        Directory.create(Path(shellpath).parent, recursive: true)
    }
    if (let Some(v) <- config.default) {
        let defaultV = Path(config.storeDir).join(v)
        SymbolicLink.create(Path(shellpath), to: defaultV)
    }
}

// Windows 创建多 shell 符号链接路径
func createMultishellPathWindows(shellpath: String) {
    if (!exists(Path(shellpath).parent)) {
        Directory.create(Path(shellpath).parent, recursive: true)
    }
    if (let Some(v) <- config.default) {
        let defaultV = Path(config.storeDir).join(v)
        SymbolicLink.create(Path(shellpath), to: defaultV)
    }
}

// 创建 stdx 符号链接
func createStdxLink(enableStdx: Bool, baseDir: String, pid: Int64, unix: Int64): String {
    if (!enableStdx || config.stdxDefault.isNone()) {
        return ""
    }
    
    let version = config.stdxDefault ?? ""
    let libType = config.stdxType
    let stdxRealPath = Path(getStdxPath(version, libType))
    let stdxLinkPath = Path("${baseDir}/stdx_${pid}_${unix}")
    
    SymbolicLink.create(stdxLinkPath, to: stdxRealPath)
    stdxLinkPath.toString()
}

// Windows 创建 stdx 符号链接
func createStdxLinkWindows(enableStdx: Bool, dir: String, pid: Int64, unix: Int64): String {
    if (!enableStdx || config.stdxDefault.isNone()) {
        return ""
    }
    
    let version = config.stdxDefault ?? ""
    let libType = config.stdxType
    let stdxRealPath = Path("${config.stdxDir}\\${version}\\windows_x86_64_llvm\\${libType}\\stdx")
    let stdxLinkPath = Path(dir).join("cjvs_multishells").join("stdx_${pid}_${unix}")
    
    SymbolicLink.create(stdxLinkPath, to: stdxRealPath)
    stdxLinkPath.toString()
}