<#
.SYNOPSIS
    git-sync Windows 安装脚本
.DESCRIPTION
    从 GitHub Release 下载、校验并安装 git-sync 到指定目录。
.PARAMETER Version
    指定安装的版本号 (例如: v1.0.0)，默认为 "latest"。
#>
param(
    [string]$Version = "latest"
)

# --- 配置参数 ---
$RepoOwner = "dongfg"
$RepoName = "git-sync"
$BinName = "git-sync.exe" # Windows 可执行文件通常带 .exe
$InstallDir = "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps" 

# 确保 PowerShell 使用 TLS 1.2 (GitHub API 需要)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- 1. 系统信息检测 ---
Write-Host "正在检测系统架构..." -ForegroundColor Cyan

# Windows 环境变量 PROCESSOR_ARCHITECTURE 通常返回 AMD64, ARM64, x86
switch -Regex ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64"   { $Arch = "amd64" }
    "ARM64"   { $Arch = "arm64" }
    "ARM"     { $Arch = "armv7" } # 较少见的 Windows on ARM 32-bit
    Default   { 
        Write-Error "不支持的架构: $env:PROCESSOR_ARCHITECTURE"
        exit 1
    }
}
Write-Host "检测到架构: Windows / $Arch" -ForegroundColor Green

# --- 2. 获取 Release 信息 ---
if ($Version -eq "latest") {
    $ApiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases/latest"
} else {
    $ApiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases/tags/$Version"
}

try {
    Write-Host "正在获取版本信息 ($Version)..."
    $ReleaseInfo = Invoke-RestMethod -Uri $ApiUrl -Method Get
} catch {
    Write-Error "获取 Release 信息失败: $_"
    exit 1
}

# --- 3. 匹配下载链接 ---
# 目标文件名模式: git-sync_Windows_amd64.zip
$FilePattern = "${RepoName}_Windows_${Arch}.zip"

# 从 Assets 中查找匹配的文件
$Asset = $ReleaseInfo.assets | Where-Object { $_.name -eq $FilePattern } | Select-Object -First 1

if ($null -eq $Asset) {
    Write-Error "错误：未在版本 $($ReleaseInfo.tag_name) 中找到适用于 Windows/${Arch} 的文件 ($FilePattern)。"
    exit 1
}

$DownloadUrl = $Asset.browser_download_url
$FileName = $Asset.name

# --- 4. 下载文件 ---
Write-Host "正在下载: $FileName" -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $FileName -UseBasicParsing
} catch {
    Write-Error "下载失败: $_"
    exit 1
}

# --- 5. 校验和验证 ---
# 查找 checksums.txt
$ChecksumAsset = $ReleaseInfo.assets | Where-Object { $_.name -like "*checksums.txt" } | Select-Object -First 1

if ($ChecksumAsset) {
    Write-Host "正在下载校验文件..."
    Invoke-WebRequest -Uri $ChecksumAsset.browser_download_url -OutFile "checksums.txt" -UseBasicParsing
    
    # 计算本地文件哈希
    $FileHash = (Get-FileHash -Path $FileName -Algorithm SHA256).Hash.ToLower()
    
    # 在 checksums.txt 中查找哈希值
    # 格式通常是:  <hash>  <filename>
    $CheckContent = Get-Content "checksums.txt"
    if ($CheckContent -match "$FileHash") {
        Write-Host "校验成功！文件完整。" -ForegroundColor Green
    } else {
        Write-Error "校验失败！下载的文件可能已损坏。"
        Remove-Item $FileName, "checksums.txt" -ErrorAction SilentlyContinue
        exit 1
    }
} else {
    Write-Warning "未找到 checksums.txt，跳过校验。"
}

# --- 6. 解压处理 ---
Write-Host "正在解压: $FileName"
# Windows 自带解压命令
Expand-Archive -Path $FileName -DestinationPath "." -Force

# --- 7. 安装 (移动文件) ---
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

$SourceBin = ".\$BinName" # 假设解压后 exe 在根目录，如果在子目录需调整
if (-not (Test-Path $SourceBin)) {
    # 尝试在解压后的同名文件夹中查找（防止解压出文件夹）
    $SourceBin = Get-ChildItem -Path . -Filter $BinName -Recurse | Select-Object -First 1 -ExpandProperty FullName
}

if ($SourceBin -and (Test-Path $SourceBin)) {
    Write-Host "正在安装到 $InstallDir ..."
    try {
        Move-Item -Path $SourceBin -Destination "$InstallDir\$BinName" -Force
        Write-Host "安装完成: $InstallDir\$BinName" -ForegroundColor Green
        
        # 检查 PATH 环境变量
        if ($env:PATH -notlike "*$InstallDir*") {
            Write-Warning "注意: '$InstallDir' 不在你的 PATH 环境变量中。"
            Write-Warning "请手动添加，或使用完整路径运行程序。"
        }
    } catch {
        Write-Error "移动文件失败，请确保你有权限写入 $InstallDir，或尝试以管理员身份运行。"
        exit 1
    }
} else {
    Write-Error "解压后未找到 $BinName"
    exit 1
}

# --- 8. 清理 ---
Remove-Item $FileName, "checksums.txt" -ErrorAction SilentlyContinue
Write-Host "清理完成。"