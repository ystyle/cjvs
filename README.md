### cjvs
> 2025-03-30 初步支持了windows(powershell), 可以自己手工编译试用


仓颉版本管理工具，类似nvm，目前只支持linux平台, 解压依赖tar和unzip


### 安装
- 先克隆仓库: `git clone https://github.com/ystyle/cjvs`  
- 使用0.59.6版本的仓颉编译: `cjpm build`
- 如果使用`Archlinux`可以使用`paru -S cjvs`安装
  >本仓库Release里的linux-amd64版本是在archlinux构建的，在较老的linux发行版可能不支持。

### 设置

#### Linux
需要安装[OpenSsl](https://cangjie-lang.cn/docs?url=%2F0.53.18%2Fuser_manual%2Fsource_zh_cn%2FAppendix%2Flinux_toolchain_install.html)    
在`~/.bashrc`或`~/.zshrc`添加以下环境变量， 要求`$HOME/.cangjie`目录不存在， 工具会自动创建
```shell
export CJVS_CANGJIE_HOME="$HOME/.cangjie"
export CANGJIE_HOME="$CJVS_CANGJIE_HOME"
export PATH=$CANGJIE_HOME/bin:$CANGJIE_HOME/tools/bin:$CANGJIE_HOME/debugger/bin:$PATH:${HOME}/.cjpm/bin
export LD_LIBRARY_PATH=${CANGJIE_HOME}/runtime/lib/linux_${uname -m}_llvm:${CANGJIE_HOME}/tools/lib:${LD_LIBRARY_PATH}  
```
>因为自带的`envsetup.sh`会读取软件连接的原始目录，所以用自己写的环境变量2

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
  switch, use     Switch to use the specified version.
  ls-remote, rls  List all remote Cangjie versions.
  install, i      Install a new Cangjie version. 
                    eg: 
                      cjvs install 0.53.13 # install online
                      cjvs install 0.59.6 ~/Downloads/cangjie-0.59.6-linux_x64.tar.gz # install a local version
  remove, rm      Remove a specific version.

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
  ```
- 在线安装版本
  ```shell
  $ cjvs install 0.53.13
  installing 0.53.13...
  installed.
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

