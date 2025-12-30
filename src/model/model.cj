package cjvs.model

import stdx.encoding.json.stream.*
import std.fs.{Path, File, OpenMode}
import std.deriving.*

@Derive[ToString]
public class Config <: JsonSerializable & JsonDeserializable<Config> {
    public var index: String
    public var default: ?String = None
    public var stdxDefault: ?String = None
    public var stdxType: String = "dynamic"
    public var storeDir: String = ""
    public var cacheDir: String = ""
    public var stdxDir: String = ""
    public init() {
        this.index = "https://dll.ystyle.top/images/cjvs-index.json"
    }

    public func initPaths(baseDir: String): Unit {
        this.storeDir = Path(baseDir).join("store").toString()
        this.cacheDir = Path(baseDir).join("cache").toString()
        this.stdxDir = Path(baseDir).join("stdx").toString()
    }
    public static func fromJson(r: JsonReader): Config {
        var res = Config()
        while (let Some(v) <- r.peek()) {
            match (v) {
                case BeginObject =>
                    r.startObject()
                    while (r.peek() != EndObject) {
                        let n = r.readName()
                        match (n) {
                            case "index" => res.index = r.readValue<String>()
                            case "default" => res.default = r.readValue<Option<String>>()
                            case "stdxDefault" => res.stdxDefault = r.readValue<Option<String>>()
                            case "stdxType" => res.stdxType = r.readValue<String>()
                            case _ => r.skip()
                        }
                    }
                    r.endObject()
                    break
                case _ => throw Exception()
            }
        }
        return res
    }

    public func toJson(w: JsonWriter): Unit {
        w.startObject() // start encoding an object
        w.writeName("default").writeValue(this.default)
        w.writeName("index").writeValue(this.index)
        w.writeName("stdxDefault").writeValue(this.stdxDefault)
        w.writeName("stdxType").writeValue(this.stdxType)
        w.endObject() // end current object
    }

    public func save(configFile: Path): Unit {
        let ff: File = File(configFile, OpenMode.Write)
        let jr = JsonWriter(ff)
        this.toJson(jr)
        jr.flush()
        ff.flush()
    }
}

@Derive[ToString]
public class Version <: JsonSerializable & JsonDeserializable<Version> {
    public var channel: String = ""
    public var os: String = ""
    public var arch: String = ""
    public var version: String = ""
    public var url: String = ""
    public var ext: String = ""
    public var sha256sum: String = ""
    public init() {
    }
    public static func fromJson(r: JsonReader): Version {
        var res = Version()
        while (let Some(v) <- r.peek()) {
            match (v) {
                case BeginObject =>
                    r.startObject()
                    while (r.peek() != EndObject) {
                        let n = r.readName()
                        match (n) {
                            case "channel" => res.channel = r.readValue<String>()
                            case "os" => res.os = r.readValue<String>()
                            case "arch" => res.arch = r.readValue<String>()
                            case "version" => res.version = r.readValue<String>()
                            case "url" => res.url = r.readValue<String>()
                            case "ext" => res.ext = r.readValue<String>()
                            case "sha256sum" => res.sha256sum = r.readValue<String>()
                            case _ => r.skip()
                        }
                    }
                    r.endObject()
                    break
                case _ => throw Exception()
            }
        }
        return res
    }

    public func toJson(w: JsonWriter): Unit {
        w.startObject() // start encoding an object
        w.writeName("channel").writeValue(channel) // write name and value pair in current object
        w.writeName("os").writeValue(os)
        w.writeName("arch").writeValue(arch)
        w.writeName("version").writeValue(version)
        w.writeName("url").writeValue(url)
        w.writeName("ext").writeValue(ext)
        w.writeName("sha256sum").writeValue(sha256sum)
        w.endObject() // end current object
    }
}

@Derive[ToString]
public class StdxVersion <: JsonSerializable & JsonDeserializable<StdxVersion> {
    public var channel: String = ""
    public var os: String = ""
    public var arch: String = ""
    public var version: String = ""
    public var cjcVersion: String = ""
    public var url: String = ""
    public var sha256sum: String = ""
    public init() {
    }
    public static func fromJson(r: JsonReader): StdxVersion {
        var res = StdxVersion()
        while (let Some(v) <- r.peek()) {
            match (v) {
                case BeginObject =>
                    r.startObject()
                    while (r.peek() != EndObject) {
                        let n = r.readName()
                        match (n) {
                            case "channel" => res.channel = r.readValue<String>()
                            case "os" => res.os = r.readValue<String>()
                            case "arch" => res.arch = r.readValue<String>()
                            case "version" => res.version = r.readValue<String>()
                            case "cjcVersion" => res.cjcVersion = r.readValue<String>()
                            case "url" => res.url = r.readValue<String>()
                            case "sha256sum" => res.sha256sum = r.readValue<String>()
                            case _ => r.skip()
                        }
                    }
                    r.endObject()
                    break
                case _ => throw Exception()
            }
        }
        return res
    }

    public func toJson(w: JsonWriter): Unit {
        w.startObject()
        w.writeName("channel").writeValue(channel)
        w.writeName("os").writeValue(os)
        w.writeName("arch").writeValue(arch)
        w.writeName("version").writeValue(version)
        w.writeName("cjcVersion").writeValue(cjcVersion)
        w.writeName("url").writeValue(url)
        w.writeName("sha256sum").writeValue(sha256sum)
        w.endObject()
    }
}
