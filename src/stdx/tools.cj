package cjvs.stdx

import std.fs.{Path, exists}
import std.collection.{ArrayList, HashMap}
import std.env.getVariable
import cjvs.config.defaultConfig
import cjvs.model.StdxVersion
import cjvs.tools.{getHttpClient, CurrentOS, arch, getStdxPath}
import stdx.encoding.json.stream.*

// ==================== stdx 工具函数 ====================

// 获取远程 stdx 版本列表
func getStdxVersions(): HashMap<String, ArrayList<StdxVersion>> {
    let client = getHttpClient()
    let res = client.get(defaultConfig.index)
    let reader = JsonReader(res.body)
    var stdxVersions = ArrayList<StdxVersion>()

    while (let Some(v) <- reader.peek()) {
        match (v) {
            case BeginObject =>
                reader.startObject()
                while (reader.peek() != EndObject) {
                    let name = reader.readName()
                    if (name == "stdx") {
                        stdxVersions = ArrayList<StdxVersion>.fromJson(reader)
                    } else {
                        reader.skip()
                    }
                }
                reader.endObject()
                break
            case _ => reader.skip()
        }
    }

    let groups = HashMap<String, ArrayList<StdxVersion>>()
    for (version in stdxVersions) {
        if (version.os == CurrentOS && version.arch == arch) {
            if (groups.contains(version.channel)) {
                groups[version.channel].add(version)
            } else {
                groups[version.channel] = ArrayList<StdxVersion>([version])
            }
        }
    }
    return groups
}

// 检查 stdx 版本是否已安装
func isStdxInstalled(version: String): Bool {
    let dynamicPath = getStdxPath(version, "dynamic")
    let staticPath = getStdxPath(version, "static")
    return exists(Path(dynamicPath)) || exists(Path(staticPath))
}

// 获取多 shell 环境下的 stdx 符号链接路径
public func getStdxLinkPath(): ?String {
    if (let Some(multishellPath) <- getVariable("CJVS_MULTISHELL_PATH")) {
        let pathParts = multishellPath.split("/")
        if (pathParts.size > 0) {
            let pidUnix = pathParts[pathParts.size - 1]
            return Some("/tmp/cjvs_multishells/stdx_${pidUnix}")
        }
    }
    return None
}
