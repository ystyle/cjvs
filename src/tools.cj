package cjvs

import std.fs.{Path, Directory, rename}
import std.collection.{ArrayList, HashMap}
import net.http.{ClientBuilder}
import net.tls.{TlsClientConfig, CertificateVerifyMode}
import std.process.{executeWithOutput}
import std.env.{getVariable, getCommand}
import encoding.json.stream.*

@When[arch == "aarch64"]
var arch = "aarch64"
@When[arch == "x86_64"]
var arch = "x86_64"
@When[os == "Linux"]
var CurrentOS = "linux"
@When[os == "Windows"]
var CurrentOS = "windows"

func getAppConfigDir():String {
    let home = if (CurrentOS == "windows") {
       Path(getCommand()).parent.toString()
    } else {
        getVariable("HOME")
    } ?? ""
    return Path(home).join(".config").join("cjvs").toString()
}

func getAppConfigFile():Path {
    return Path(getAppConfigDir()).join("config.json")
}

// 获取当前系统可所有的可用版本列表
func getVersions(): HashMap<String, ArrayList<Version>> {
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

extend Array<String> {
    public func containsAny(items: Array<String>): Bool {
        for (item in this) {
            if (items.contains(item)) {
                return true
            }
        }
        return false
    }
}

func listdir(path: Path): ArrayList<Path> {
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


func getHttpClient() {
    var tls = TlsClientConfig()
    if (CurrentOS == "windows" || (getVariable("NO_VERIFY_SSL") ?? "NO") == "YES" ) {
        println("Skip ssl verification")
        tls.verifyMode = CertificateVerifyMode.TrustAll
    }
    return ClientBuilder().readTimeout(Duration.minute).tlsConfig(tls).build()
}

@When[os == "Windows"]
func uncompress(ext: String, source: String, target: String) {
    match (ext) {
        case "zip" =>
            var sourcefile = source
            if (!source.endsWith(".zip")) {
                sourcefile = "${source}.zip"
                rename(source, to: sourcefile) // powershell 的解压看文件后缀名
            }
            let command = "Expand-Archive -Path '${sourcefile}' -DestinationPath '${target}'  -Force"
            println(command)
            let (status, out, outerr) = executeWithOutput("powershell.exe", ["-Command", command])
            if (status != 0) {
                println("Install failed: ")
                println(String.fromUtf8(out))
                println(String.fromUtf8(outerr))
                return
            }
            ()
        case _ => println("unsupport file format")
    }
}

@When[os == "Linux"]
func uncompress(ext: String, source: String, target: String) {
    match (ext) {
        case "zip" =>
            let (status, out, outerr) = executeWithOutput("unzip", [source, "-d", target])
            if (status != 0) {
                println("Install failed: ")
                println(String.fromUtf8(out))
                println(String.fromUtf8(outerr))
                return
            }
            ()
        case "tar.gz" =>
            let (status, out, outerr) = executeWithOutput("tar", ["-zxf", source, "-C", target])
            if (status != 0) {
                println("Install failed: ")
                println(String.fromUtf8(out))
                println(String.fromUtf8(outerr))
                return
            }
            ()
        case _ => println("unsupport file format")
    }
}
