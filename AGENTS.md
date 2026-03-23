# AGENTS.md - cjvs 项目开发指南

本文档为 AI 编码代理提供项目开发规范和命令参考。

## 项目概述

cjvs 是仓颉（Cangjie）语言版本管理工具，类似 nvm。支持 Linux、macOS、Windows 平台。

## 构建/测试/运行命令

### 构建项目

```bash
# 标准构建
cjpm build

# 发布构建（优化）
cjpm build -release

# 使用 Taskfile 构建（包含打包）
task build
```

### 运行项目

```bash
# 编译后运行
./target/release/bin/main

# 或复制后的可执行文件
./target/release/bin/cjvs
```

### 测试

项目当前无自动化测试。测试方式为手动运行验证：

```bash
# 构建后手动测试
./target/release/bin/cjvs --help
./target/release/bin/cjvs ls-remote
```

### 包管理

```bash
# 安装依赖
cjpm update
```

## 代码风格指南

### 文件结构

每个源文件应按以下顺序组织：

1. 包声明（必须放在第一行）
2. 导入语句（分组排列）
3. 类型定义
4. 函数定义

```cangjie
package cjvs

import std.fs.{Path, File, exists}
import std.env.getVariable
import cjvs.config.config

// 类型定义...
// 函数定义...
```

### 包命名规范

- 包名使用小写，与目录结构匹配
- 根包：`package cjvs`
- 子模块：`package cjvs.model`、`package cjvs.stdx`、`package cjvs.config`

### 导入规范

```cangjie
// 标准库导入
import std.fs.{Path, File, Directory, exists}
import std.env.{getVariable, getProcessId}
import std.collection.{ArrayList, HashMap}

// 扩展库导入（stdx）
import stdx.encoding.json.stream.*
import stdx.net.http.ClientBuilder

// 项目内部模块导入
import cjvs.config.config
import cjvs.model.Version
import cjvs.tools.{uncompress, getVersions}

// 第三方库导入
import zip4cj.*
import cjpminfo.*
```

### 命名约定

| 类型 | 命名风格 | 示例 |
|------|----------|------|
| 类/结构体 | PascalCase | `Config`, `Version`, `StdxVersion` |
| 函数 | camelCase | `getVersions()`, `switchVersion()` |
| 变量 | camelCase | `configDir`, `versionName` |
| 常量/全局变量 | camelCase | `CurrentOS`, `CJVS_MULTISHELL_PATH` |
| 接口 | PascalCase | `ContainsArray` |
| 成员变量 | camelCase | `storeDir`, `stdxDefault` |

### 函数定义

```cangjie
// 公开函数
public func getAppConfigDir(): String {
    // ...
}

// 包内私有函数
func doinstall(version: Version): Unit {
    // ...
}

// 带参数的函数
func install(args: Array<String>) {
    // ...
}
```

### 类型声明

```cangjie
// 类定义
@Derive[ToString]
public class Config <: JsonSerializable & JsonDeserializable<Config> {
    public var index: String
    public var default: ?String = None
    public var storeDir: String = ""
    
    init() {
        this.index = "https://example.com"
    }
}

// 接口定义
public interface ContainsArray {
    func containsAny(items: Array<String>): Bool
}

// 扩展现有类型
extend Array<String> <: ContainsArray {
    public func containsAny(items: Array<String>): Bool {
        for (item in this) {
            if (items.contains(item)) {
                return true
            }
        }
        return false
    }
}
```

### 可选类型处理

```cangjie
// 声明可选类型
public var default: ?String = None

// 条件解包
if (let Some(v) <- config.default) {
    // 使用 v
}

// 提供默认值
let value = option ?? "default"
```

### 模式匹配

```cangjie
// 命令分发
match (command) {
    case "list" | "ls" => listVersion(args)
    case "install" | "i" => install(args)
    case "switch" | "use" | "s" => switchVersion(args)
    case _ => println("unknown command.")
}

// JSON 解析
match (n) {
    case "index" => res.index = r.readValue<String>()
    case "default" => res.default = r.readValue<Option<String>>()
    case _ => r.skip()
}
```

### 平台条件编译

使用 `@When` 注解实现平台特定代码：

```cangjie
@When[os == "Linux"]
func genenv(args: Array<String>) {
    genenvUnix(args, "linux")
}

@When[os == "Windows"]
func genenv(args: Array<String>) {
    // Windows 特定实现
}

@When[arch == "x86_64"]
public var arch = "x86_64"
```

### 错误处理

```cangjie
// 使用 try-catch
try {
    SymbolicLink.create(Path(v), to: versiondir)
} catch (e: Exception) {
    println("Switch failed: create symbolic link failed")
    return
}

// 使用 try-finally 进行资源清理
try {
    // 执行操作
} finally {
    removeIfExists(config.cacheDir, recursive: true)
}

// 提前返回模式
if (!exists(versiondir)) {
    println("${version} is not found.")
    return
}
```

### 字符串处理

```cangjie
// 字符串插值
println("installing ${version.version}...")
println("stdx ${version} is already installed.")

// 多行字符串
println("""
export CJVS_MULTISHELL_PATH="${shellpath}"
export CANGJIE_HOME="${shellpath}"
""")
```

### 注释规范

代码注释使用中文：

```cangjie
// 获取当前系统可所有的可用版本列表
public func getVersions(): HashMap<String, ArrayList<Version>> {
    // ...
}

// 解析参数
let appendLdLibraryPath = !args.containsAny(["-no-ld-library-path"])
```

## 项目结构

```
cjvs/
├── cjpm.toml              # 项目配置和依赖
├── Taskfile.yaml          # 构建任务定义
├── src/
│   ├── main.cj            # 程序入口
│   ├── model/
│   │   └── model.cj       # 数据模型定义
│   ├── config/
│   │   └── config.cj      # 全局配置
│   ├── stdx/              # stdx 子命令实现
│   │   ├── command.cj     # 命令分发
│   │   ├── stdx_install.cj
│   │   ├── stdx_switch.cj
│   │   └── stdx_env.cj
│   ├── tools/
│   │   └── tools.cj       # 工具函数
│   └── command_*.cj       # 各命令实现
└── target/                # 构建输出
```

## 依赖说明

- `zip4cj`: ZIP 文件处理库
- `cjpminfo`: 包信息获取
- 标准库: `std.fs`, `std.env`, `std.collection`, `std.process`
- 扩展库: `stdx.encoding.json`, `stdx.net.http`

## 开发环境要求

- 仓颉编译器 1.1.0+
- 设置 `CANGJIE_STDX_PATH` 环境变量
- Linux 需要 OpenSSL 开发库