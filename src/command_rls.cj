package cjvs

import std.collection.ArrayList
import std.sort.sort
import cjvs.tools.{getVersions, ContainsArray}
import cjvs.model.Version

// 在控制台列出所有的可用版本
func remote(args: Array<String>) {
    var showChannel = if (args.size >= 2 && ["sts", "lts"].contains(args[1])) {
        args[1]
    } else {
        "all"
    }
    let showBeta = args.containsAny(["--beta"])

    let groups = getVersions()
    for ((channel, versions) in groups) {
        if (showChannel != "all" && channel != showChannel) {
            continue
        }
        sort(versions, key: {v => v.version})

        var stables = ArrayList<Version>()
        var betas = ArrayList<Version>()
        for (v in versions) {
            if (v.version.contains("beta")) {
                betas.add(v)
            } else {
                stables.add(v)
            }
        }

        if (stables.size > 0) {
            println("Channel: ${channel}")
            for (version in stables) {
                println("\t${version.version}")
            }
        }
        if (showBeta && betas.size > 0) {
            println("\tbeta:")
            for (version in betas) {
                println("\t\t${version.version}")
            }
        }
    }
}
