package cjvs

import std.sort.sort
import cjvs.tools.getVersions

// 在控制台列出所有的可用版本
func remote(args: Array<String>) {
    var showChannel = if (args.size >= 2 && ["beta", "lts"].contains(args[1])) {
        args[1]
    } else {
        "all"
    }
    let groups = getVersions()
    for ((channel, versions) in groups) {
        if (showChannel != "all" && channel != showChannel) {
            continue
        }
        sort(versions, key: {v => v.version})
        println("Channel: ${channel}")
        for (version in versions) {
            println("\t${version.version}")
        }
    }
}