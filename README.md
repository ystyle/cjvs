### cjvs
仓颉版本管理工具，类似nvm，目前只支持linux平台, 解压依赖tar和unzip

### 安装
- 先克隆仓库: `git clone https://github.com/ystyle/cjvs`
- 使用0.57.3版本的仓颉编译: `cjpm build`

### 设置
- 设置一个`CJVS_CANGJIE_HOME`环境变量， 如在`~/.zshrc`或`~/.bashrc`添加`export CJVS_CANGJIE_HOME="$HOME/.cangjie"`, 要求`$HOME/.cangjie`目录不存在， 工具会自动创建
- 在`~/.zshrc`或`~/.bashrc`添加 `source ${CJVS_CANGJIE_HOME}/envsetup.sh`

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
- 安装内测版本: 
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

