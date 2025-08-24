package cjvs

import std.fs.{Path, Directory, rename}
import std.collection.{ArrayList, HashMap}
import net.http.{ClientBuilder}
import net.tls.{TlsClientConfig, CertificateVerifyMode}
import std.process.{executeWithOutput}
import std.env.{getVariable, getCommand}
import encoding.json.stream.*
import zip4cj.*

@When[arch == "aarch64"]
var arch = "aarch64"
@When[arch == "x86_64"]
var arch = "x86_64"
@When[os == "Linux"]
var CurrentOS = "linux"
@When[os == "Windows"]
var CurrentOS = "windows"

func getAppConfigDir(): String {
    if (CurrentOS == "windows") {
        return Path(getCommand()).parent.toString()
    } else {
        let home = getVariable("HOME") ?? ""
        return Path(home).join(".config").join("cjvs").toString()
    }
}

func getAppConfigFile(): Path {
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
    if (CurrentOS == "windows" || (getVariable("NO_VERIFY_SSL") ?? "NO") == "YES") {
        tls.verifyMode = CertificateVerifyMode.TrustAll
    }
    return ClientBuilder().readTimeout(Duration.minute).tlsConfig(tls).build()
}

@When[os == "Windows"]
func uncompress(ext: String, source: String, target: String) {
    match (ext) {
        case "zip" =>
            // var sourcefile = source
            // if (!source.endsWith(".zip")) {
            //     sourcefile = "${source}.zip"
            //     rename(source, to: sourcefile) // powershell 的解压看文件后缀名
            // }

            let zipFile = ZipFile(source)  // 创建ZipFile类
            zipFile.setRunInThread(false)                 // 设置是否用子线程运行任务
            zipFile.extractAll(target)                // 解压到 output 文件夹, 文件夹不存在则创建
            zipFile.close()                               // 资源关闭
            // // let command = "Expand-Archive -Path '${sourcefile}' -DestinationPath '${target}'  -Force"
            // let command = """
            //     Add-Type -AssemblyName System.IO.Compression.FileSystem
            //     try {
            //         Write-Host "start: $(Get-Date -Format 'HH:mm:ss')"
            //         [System.IO.Compression.ZipFile]::ExtractToDirectory('${sourcefile}', '${target}')
            //         Write-Host "start: $(Get-Date -Format 'HH:mm:ss')"
            //         Write-Host "uncompress success"
            //     } catch {
            //         $errorMsg = $_.Exception.Message
            //         $base64Error = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($errorMsg))
            //         Write-Error "uncompress failed $($_.Exception.Message)"
            //         exit 1
            //     }
            // """
            // println(command)
            // let (status, out, outerr) = executeWithOutput("powershell.exe", ["-Command", command])
            // if (status != 0) {
            //     println("Install failed: ")
            //     println(String.fromUtf8(out))
            //     println(String.fromUtf8(outerr))
            //     return
            // }
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
