package cjvs.stdx

// 列出远程可用的 stdx 版本
func stdxRemote(_: Array<String>) {
    let groups = getStdxVersions()

    if (groups.size == 0) {
        println("No remote stdx versions available.")
        return
    }

    for ((channel, versions) in groups) {
        println("Channel: ${channel}")
        for (v in versions) {
            println("\t${v.version} (cjc: ${v.cjcVersion})")
        }
    }
}
