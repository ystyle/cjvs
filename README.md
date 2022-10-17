### cjvs
仓颉版本管理工具

### 编译安装说明
- 编译后安装需要在`.zshrc`或`.bashrc`最后一行添加以下内容(编译版本需要0.33.3以上)， 以下路径需要使用绝对路径
  ```shell
  export LD_LIBRARY_PATH=/home/ystyle/Cangjie_0.33.3/cangjie/runtime/lib/linux_x86_64_llvm:$LD_LIBRARY_PATH
  ```

### 使用
```shell
$ cjvs
Usage: cjvs [options...]
  list, ls     List Canjie installations.
  switch, s    Switch to use the specified version.
  remove, rm   Remove a specific version.

GLOBAL OPTIONS:
  --help, -h     show help
  --version, -v  print the version
```

示例
- 注意： 如果要切换标准版本和虚拟机版本，需要把两个版本的环境变量都整合在一起或者直接用`source $CANGJIE_HOME/envsetup.sh`
  - 目前不支持从虚拟机版本切回来
  - 直接使用`envsetup.sh`： 把以下配置文件放入`.zshrc`或`.bashrc`
    ```shell
    # 仓颉
    source source $CANGJIE_HOME/envsetup.sh
    ```
  - 整合版本：
    ```shell
    # 仓颉
    export CANGJIE_HOME="$HOME/cangjie"
    export PATH=${HOME}/.local/bin:$CANGJIE_HOME/bin:$CANGJIE_HOME/tools/bin:$CANGJIE_HOME/debugger/bin:$PATH
    export LD_LIBRARY_PATH=$CANGJIE_HOME/runtime/lib/linux_x86_64_llvm:${CANGJIE_HOME}/lib/linux_x86_64_jet:${CANGJIE_HOME}/debugger/third_party/lldb/lib:$LD_LIBRARY_PATH
    ```
- `cjvs list`: 显示本地已经安装的仓颉版本
  - 会自动创建`$HOME/.config/cjvs`缓存目录
  - 自行复制仓颉版本到`$HOME/.config/cjvs/store`目录下(在线下载将在仓颉发布后提供)
    - 如 `$HOME/.config/cjvs/store/cangjie_0.33.3`， 该目录直接包含`bin、lib、runtime、tools、modules`等目录 
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
  - 会检查`CANGJIE_HOME`环境变量，是否已经设置，指向的目录必需不存在或者是个软件连接
  ```shell
  $ cjvs ls
  Installed Cangjie versions(makr up * is in used):
        * cangjie_0.33.3
          cangjie_jet_ 0.33.3
  ``` 
- `cjvs switch cangjie_0.33.3` 切换版本
