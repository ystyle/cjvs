### cjvs
仓颉版本管理工具(远程安装开发中...)

### 安装
- 先克隆仓库: `git clone https://github.com/ystyle/cjvs`
- 使用0.57.3版本的仓颉编译: `cjpm build`

### 使用
```shell
$ cjvs
Usage: cjvs [options...]
  list, ls        List Cangjie installations.
  switch, use     Switch to use the specified version.
  ls-remote, rls  List all remote Cangjie versions.
  install, i      Install a new Cangjie version.
  remove, rm      Remove a specific version.

GLOBAL OPTIONS:
  --help, -h     show help
  --version, -v  print the version
```

示例
- 检查设置
  - 检查`CANGJIE_HOME`环境变量，是否已经设置，指向的目录必需不存在或者是个软件连接
  - 检查通过会打印帮助
- 安装版本: 
  - 自行把仓颉编译器版本复制到`$HOME/.config/cjvs/store`目录
    - 如 `$HOME/.config/cjvs/store/std_0.33.3`， 该目录直接包含`bin、lib、runtime、tools、modules`等目录 
    ```shell
    ~/.config/cjvs$ tree -L 3
    .
    └── store
        └── cangjie_0.33.3
            ├── bin
            ├── debugger
            ├── docs
            ├── envsetup.sh
            ├── lib
            ├── modules
            ├── runtime
            ├── third_party
            └── tools

    10 directories, 1 file
    ```
  - 在线下载将在仓颉发布后提供（正在开发中...）
- 显示本地已经安装的仓颉版本
    ```shell
    $ cjvs ls
    Installed Cangjie versions(makr up * is in used):
    	  std_0.31.4
    	  jet_0.33.3
    	  std_0.32.5
    	* std_0.33.3
    ``` 
- 切换版本
    ```shell
    $ cjvs switch std_0.33.3
    Switch success
    Now using version: std_0.33.3
    ```
