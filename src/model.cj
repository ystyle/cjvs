package cjvs

import encoding.json.stream.*
import std.fs.{Path, File, OpenMode}
import std.deriving.*
import std.env.{ getCommand }

@Derive[ToString]
class Config <: JsonSerializable & JsonDeserializable<Config> {
    var channel: String
    var _storeDir: String
    var _cacheDir: String
    var index: String
    var default:?String = None
    init() {
        this.channel = "beta"
        this._storeDir = "store"
        this._cacheDir = "cache"
        if (CurrentOS == "windows") {
            let binpath = Path(getCommand()).parent
            this._storeDir = binpath.join("store").toString()
            this._cacheDir = binpath.join("cache").toString()
        }
        this.index = "https://dll.ystyle.top/images/cjvs-index.json"
    }

    public mut prop storeDir: String {
        get() {
            if (CurrentOS == "windows") {
                _storeDir
            } else if (_storeDir.startsWith("/")) {
                _storeDir
            } else {
                Path(getAppConfigDir()).join(_storeDir).toString()
            }
        }
        set(storeDir) {
            _storeDir = storeDir
        }
    }
    public mut prop cacheDir: String {
        get() {
            if (CurrentOS == "windows") {
                _cacheDir
            } else if (_cacheDir.startsWith("/")) {
                _cacheDir
            } else {
                Path(getAppConfigDir()).join(_cacheDir).toString()
            }
        }
        set(cacheDir) {
            _cacheDir = cacheDir
        }
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
                            case "channel" => res.channel = r.readValue<String>()
                            case "storeDir" => res._storeDir = r.readValue<String>()
                            case "cacheDir" => res._cacheDir = r.readValue<String>()
                            case "index" => res.index = r.readValue<String>()
                            case "default" => res.default = r.readValue<Option<String>>()
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
        w.writeName("channel").writeValue(this.channel) // write name and value pair in current object
        w.writeName("storeDir").writeValue(this._storeDir)
        w.writeName("cacheDir").writeValue(this._cacheDir)
        w.writeName("default").writeValue(this.default)
        w.writeName("index").writeValue(this.index)
        w.endObject() // end current object
    }

    public func save(): Unit {
        let ff: File = File(getAppConfigFile(), OpenMode.Write)
        let jr = JsonWriter(ff)
        this.toJson(jr)
        jr.flush()
        ff.flush()
    }
}

@Derive[ToString]
class Version <: JsonSerializable & JsonDeserializable<Version> {
    var channel: String = ""
    var os: String = ""
    var arch: String = ""
    var version: String = ""
    var url: String = ""
    var ext:String = ""
    var sha256sum:String = ""
    init() {
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
