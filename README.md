## Git Sync
> 持久化 git 多远程配置到仓库

[![lint](https://github.com/dongfg/git-sync/actions/workflows/lint.yaml/badge.svg)](https://github.com/dongfg/git-sync/actions/workflows/lint.yaml)
![GitHub Release](https://img.shields.io/github/v/release/dongfg/git-sync)


## 安装

go install

```shell
go install github.com/dongfg/git-sync@latest
```
or [download binary](https://github.com/dongfg/git-sync/releases)

## 使用
```shell
# 可选, git alias 配置
# git config --global alias.sync "!git-sync"

# 从仓库读取配置应用
git-sync

# 保存 git 配置到当前仓库
git-sync save
```