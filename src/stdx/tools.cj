package cjvs.stdx

import std.fs.{Path, exists}
import std.collection.{ArrayList, HashMap}
import cjvs.config.config
import cjvs.model.StdxVersion
import cjvs.tools.{getHttpClient, CurrentOS, arch}
import stdx.encoding.json.stream.*

// ==================== stdx 工具函数 ====================

// 获取远程 stdx 版本列表
func getStdxVersions(): HashMap<String, ArrayList<StdxVersion>> {
    let client = getHttpClient()
    let res = client.get(config.index)
    // 假设 index.json 中有 stdx 字段
    let reader = JsonReader(res.body)
    var stdxVersions = ArrayList<StdxVersion>()

    // 解析 JSON，找到 stdx 数组
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

    // 按系统架构过滤
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

// 获取指定版本的 stdx 路径
func getStdxPath(version: String, libType: String): String {
    let osName = if (CurrentOS == "macos") { "macos" } else { "linux" }
    return Path(config.stdxDir).join(version).join("${osName}_x86_64_llvm").join(libType).join("stdx").toString()
}

// 检查 stdx 版本是否已安装
func isStdxInstalled(version: String): Bool {
    let dynamicPath = getStdxPath(version, "dynamic")
    let staticPath = getStdxPath(version, "static")
    return exists(Path(dynamicPath)) || exists(Path(staticPath))
}
