## Git Sync
> 持久化 git 多远程配置到仓库

[![lint](https://github.com/dongfg/git-sync/actions/workflows/lint.yaml/badge.svg)](https://github.com/dongfg/git-sync/actions/workflows/lint.yaml)
![GitHub Release](https://img.shields.io/github/v/release/dongfg/git-sync)

## 介绍
git 仓库需要推送到多个远程地址时每次新 clone 都需要执行 git remote 相关命令，这个工具的作用是把远程地址写入当前仓库的 .gitconfig 文件

```shell
$ cat .gitconfig
[remote "origin"]
url = git@github.com:dongfg/git-sync.git
url = git@gitlab.com:dongfg/git-sync.git

$ git sync # 应用当前配置
origin  git@github.com:dongfg/git-sync.git (fetch)
origin  git@github.com:dongfg/git-sync.git (push)
origin  git@gitlab.com:dongfg/git-sync.git (push)

```

## 安装

go install

```shell
go install github.com/dongfg/git-sync@latest
```

shell install on unix
```shell
curl -sSL https://raw.githubusercontent.com/dongfg/git-sync/refs/heads/master/scripts/install.sh | bash
```

powershell install on windows
```pwsh
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
irm https://raw.githubusercontent.com/dongfg/git-sync/refs/heads/master/scripts/install.ps1 | iex
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