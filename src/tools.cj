package cjvs

import std.fs.{Path, Directory}
import std.collection.ArrayList

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
                dirs.append(fileinfo.path)
            }
            if (let Some(v) <- fileinfo.parentDirectory?.path) {
                return path == v
            }
            return true
        }
    )
    return dirs
}

@When[arch == "aarch64"]
var arch = "aarch64"
@When[arch == "x86_64"]
var arch = "x86_64"
@When[os == "Linux"]
var CurrentOS = "linux"
@When[os == "Windows"]
var CurrentOS = "windows"
