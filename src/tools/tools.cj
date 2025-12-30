package cjvs.tools

import std.fs.{Path, Directory}
import std.collection.{ArrayList, HashMap}
import std.process.{executeWithOutput}
import std.env.{getVariable, getCommand}
import stdx.encoding.json.stream.*
import stdx.net.http.{ClientBuilder}
import stdx.net.tls.{TlsClientConfig, CertificateVerifyMode}
import zip4cj.*
import cjvs.model.Version
import cjvs.config.config

@When[arch == "aarch64"]
public var arch = "aarch64"
@When[arch == "x86_64"]
public var arch = "x86_64"
@When[os == "Linux"]
public var CurrentOS = "linux"
@When[os == "Windows"]
public var CurrentOS = "windows"
@When[os == "macOS"]
public var CurrentOS = "macos"

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
    let res = client.get(config.index)
    let versions = Array<Version>.fromJson(JsonReader(res.body))
    let groups = HashMap<String, ArrayList<Version>>()
    for (version in versions) {
        if (version.os == CurrentOS && version.arch == arch) {
            if (groups.contains(version.channel)) {
                groups[version.channel].add(version)
            } else {
                groups[version.channel] = ArrayList<Version>([version])
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

public func getHttpClient() {
    var tls = TlsClientConfig()
    if (CurrentOS == "windows" || (getVariable("NO_VERIFY_SSL") ?? "NO") == "YES") {
        tls.verifyMode = CertificateVerifyMode.TrustAll
    }
    return ClientBuilder().readTimeout(Duration.minute).tlsConfig(tls).build()
}

@When[os == "Windows"]
public func uncompress(ext: String, source: String, target: String) {
    match (ext) {
        case "zip" =>
            let zipFile = ZipFile(source) // 创建ZipFile类
            zipFile.setRunInThread(false) // 设置是否用子线程运行任务
            zipFile.extractAll(target) // 解压到 output 文件夹, 文件夹不存在则创建
            zipFile.close() // 资源关闭
            ()
        case _ => println("unsupport file format")
    }
}

@When[os == "Linux" || os == "macOS"]
public func uncompress(ext: String, source: String, target: String) {
    match (ext) {
        case "zip" =>
            // 使用 zip4cj 库解压 zip
            let zipFile = ZipFile(source)
            zipFile.setRunInThread(false)
            zipFile.extractAll(target)
            zipFile.close()
            ()
        case "tar.gz" =>
            // tar.gz 格式使用系统命令
            let (status, out, outerr) = executeWithOutput("tar", ["-zxf", source, "-C", target])
            if (status != 0) {
                println("Install failed: ")
                println(String.fromUtf8(out))
                println(String.fromUtf8(outerr))
                return
            }
            ()
        case _ => println("unsupported file format: ${ext}")
    }
}
