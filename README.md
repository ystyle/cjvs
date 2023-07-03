### cjvs
仓颉版本管理工具

### 安装
- [下载编译好的版本](https://gitee.com/HW-PLLab/cjvs/releases/latest)
- 解压到一个文件夹，在`～/.zshrc`或`～/.bashrc`添加环境变量，`/cjvs_amd64`要替换为解压目录
```shell
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/cjvs_amd64/lib
export CANGJIE_HOME="$HOME/cangjie" #指向的目录必需不存在或者是个软连接
```
### 注意
>如果要切换标准版本和虚拟机版本，需要把两个版本的环境变量都整合在一起
```shell
# 仓颉
export CANGJIE_HOME="$HOME/cangjie" #指向的目录必需不存在或者是个软连接
export PATH=${HOME}/.local/bin:$CANGJIE_HOME/bin:$CANGJIE_HOME/tools/bin:$CANGJIE_HOME/debugger/bin:$PATH
export LD_LIBRARY_PATH=$CANGJIE_HOME/runtime/lib/linux_x86_64_llvm:${CANGJIE_HOME}/lib/linux_x86_64_jet:${CANGJIE_HOME}/debugger/third_party/lldb/lib:$LD_LIBRARY_PATH
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
  - 在线下载将在仓颉发布后提供
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

### 编译说明
>自己编译后安装需要在`.zshrc`或`.bashrc`最后一行添加以下内容(编译版本需要0.39.4以上)，防止切换版本后因环境问题执行cjvs报错， 以下路径需要使用绝对路径

```shell
export LD_LIBRARY_PATH=/cangjie_0.39.4/runtime/lib/linux_x86_64_llvm:$LD_LIBRARY_PATH
```