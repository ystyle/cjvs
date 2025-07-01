### cjvs
仓颉版本管理工具，类似nvm，目前只支持linux平台, 解压依赖tar和unzip

更新日志: 
> - 2025-03-30 初步支持了windows(powershell), 可以自己手工编译试用
> - 2025-07-04 因为添加了不同的shell进程，可切换不同版本的功能，当前widnows 版本暂时不可用

### 功能
- 列出可在线安装的公测版本
- 在线安装公测的仓颉版本
- 离线安装zip/tar.gz版本(需要按官方的目录结构，可离线安装内测版本)
- 列出已安装的版本
- 在每个shell/或者终端模拟器页签中切换并使用不同的仓颉版本
- 设置默认的仓颉版本
- 删除cjvs安装的版本

### 安装
- 先克隆仓库: `git clone https://github.com/ystyle/cjvs`  
- 使用0.59.6版本的仓颉编译: `cjpm build`
- 如果使用`Archlinux`可以使用`paru -S cjvs`安装
  >本仓库Release里的linux-amd64版本是在archlinux构建的，在较老的linux发行版可能不支持。

### 设置

#### Linux
>linux下默认会安装仓颉版本到`~/.config/cjvs`目录

需要安装[OpenSsl](https://cangjie-lang.cn/docs?url=%2F0.53.18%2Fuser_manual%2Fsource_zh_cn%2FAppendix%2Flinux_toolchain_install.html) ，仓颉网络库依赖openssl

1. 手动安装时需要把cjvs放path环境变量里
  ```shell
  export PATH=$PATH:/path/to/cjvs
  ```
2. 添加shell配置，按使用的bash或zsh添加以下配置
  ```shell
  # zsh添加这个
  eval "$(cjvs env zsh)"
  # bash 添加这个
  eval "$(cjvs env bash)"
  ```


#### Windows
- 设置一个`CJVS_CANGJIE_HOME`环境变量, 如`%USERPROFILE%/.cangjie`， 要求目录不存在， 工具会自动创建
- 然后在PATH添加以下内容
  - `%CANGJIE_HOME%\bin`
  - `%CANGJIE_HOME%\tools\bin`
  - `%CANGJIE_HOME%\tools\lib`
  - `%CANGJIE_HOME%\runtime\lib\windows_x86_64_llvm`
- 设置后要重启powershell(如果已经打开了）
- 执行cjvs需要以管理员身份运行powershell


### 使用
```shell
$ cjvs
Usage: cjvs [options...]
  list, ls        List Cangjie installations.
  ls-remote, rls  List all remote Cangjie versions.
  install, i      Install a new Cangjie version. 
                    eg: 
                      cjvs install 0.53.13 # install online
                      cjvs install 0.59.6 ~/Downloads/cangjie-0.59.6-linux_x64.tar.gz # install a local version
  switch, use     Switch to use the specified version.
  default         Set the default Cangjie version.
  remove, rm      Remove a specific version.
  env             Print and set up required environment variables for cjvs

GLOBAL OPTIONS:
  --help, -h     show help
  --version, -v  print the version
```

示例
- 检查设置
  - 检查`CJVS_CANGJIE_HOME`环境变量，是否已经设置，指向的目录必需不存在或者是个软件连接
  - 检查通过会打印帮助
- 显示可用公测版本
  ```shell
  $ cjvs rls            
  Channel: beta
        0.53.13
        0.53.18
  ```
- 在线安装版本
  ```shell
  $ cjvs install 0.53.13
  installing 0.53.13...
  installed.
  0.53.13 is set as default.
  ```
- 安装本地压缩版本（zip/tar.gz的目录结构需要和官方提供的一致）
  ```shell
  $ cjvs install 0.59.6 ~/Downloads/cangjie-0.59.6-linux_x64.tar.gz
  installing 0.59.6...
  installed.
  ```
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
- 手动添加版本: 
  - 把仓颉编译器版本复制到`$HOME/.config/cjvs/store`目录
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

