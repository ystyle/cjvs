package cjvs.tools

import std.fs.{Path, Directory, exists}
import std.collection.{ArrayList, HashMap}
import std.process.{executeWithOutput}
import std.env.{getVariable, getCommand}
import stdx.encoding.json.stream.*
import stdx.net.http.{ClientBuilder, Client}
import stdx.net.tls.*
import stdx.net.tls.common.*
import ystyle::zip.*
import cjvs.model.Version
import cjvs.config.defaultConfig

@When[arch == "aarch64"]
public var arch: String = "aarch64"
@When[arch == "x86_64"]
public var arch: String = "x86_64"
@When[os == "Linux"]
public var CurrentOS: String = "linux"
@When[os == "Windows"]
public var CurrentOS: String = "windows"
@When[os == "macOS"]
public var CurrentOS: String = "macos"

public func getAppConfigDir(): String {
    if (CurrentOS == "windows") {
        return Path(getCommand()).parent.toString()
    } else {
        let home = getVariable("HOME") ?? ""
        return Path(home).join(".config").join("cjvs").toString()
    }
}

public func getAppConfigFile(): Path {
    return Path(getAppConfigDir()).join("config.json")
}

// 获取当前系统可所有的可用版本列表
public func getVersions(): HashMap<String, ArrayList<Version>> {
    let client = getHttpClient()
    let res = client.get(defaultConfig.index)
    let versions = Array<Version>.fromJson(JsonReader(res.body))
    let groups = HashMap<String, ArrayList<Version>>()
    for (version in versions) {
        if (version.os == CurrentOS && version.arch == arch) {
            if (groups.contains(version.channel)) {
                groups[version.channel].add(version)
            } else {
                let list = ArrayList<Version>()
                list.add(version)
                groups[version.channel] = list
            }
        }
    }
    return groups
}

// 定义 containsAny 接口
public interface ContainsArray {
    func containsAny(items: Array<String>): Bool
}

// 使用接口扩展为 Array<String> 添加 containsAny 方法
extend Array<String> <: ContainsArray {
    public func containsAny(items: Array<String>): Bool {
        for (item in this) {
            if (items.contains(item)) {
                return true
            }
        }
        return false
    }
}

public func listdir(path: Path): ArrayList<Path> {
    let dirs = ArrayList<Path>()
    Directory.walk(
        path,
        {
            fileinfo =>
                if (fileinfo.isDirectory()) {
                    dirs.add(fileinfo.path)
                }
                return true
        }
    )
    return dirs
}

public func getHttpClient(): Client {
    var tls = TlsClientConfig()
    if (CurrentOS == "windows" || (getVariable("NO_VERIFY_SSL") ?? "NO") == "YES") {
        tls.verifyMode = CertificateVerifyMode.TrustAll
    }
    return ClientBuilder().readTimeout(Duration.minute).tlsConfig(tls).build()
}

// 获取 stdx 路径（支持新旧目录结构）
public func getStdxPath(version: String, libType: String): String {
    let osName = if (CurrentOS == "macos") { "macos" } else if (CurrentOS == "windows") { "windows" } else { "linux" }
    let versionBasePath = Path(defaultConfig.stdxDir).join(version)
    
    let runtimeTypes = ["llvm", "cjnative"]
    for (runtimeType in runtimeTypes) {
        let testPath = versionBasePath.join("${osName}_${arch}_${runtimeType}").join(libType).join("stdx")
        if (exists(testPath)) {
            return testPath.toString()
        }
    }
    
    versionBasePath.join("${osName}_${arch}_llvm").join(libType).join("stdx").toString()
}

@When[os == "Windows"]
public func uncompress(ext: String, source: String, target: String): Unit {
    match (ext) {
        case "zip" =>
            let reader = Reader.open(source)
            reader.extractAll(target)
            reader.close()
        case _ => println("unsupport file format")
    }
}

@When[os == "Linux" || os == "macOS"]
public func uncompress(ext: String, source: String, target: String): Unit {
    match (ext) {
        case "zip" =>
            let reader = Reader.open(source)
            reader.extractAll(target)
            reader.close()
        case "tar.gz" =>
            let (status, out, outerr) = executeWithOutput("tar", ["-zxf", source, "-C", target])
            if (status != 0) {
                println("Install failed: ")
                println(String.fromUtf8(out))
                println(String.fromUtf8(outerr))
                return
            }
        case _ => println("unsupported file format: ${ext}")
    }
}
