#!/usr/bin/env pwsh
# 创建一个新特性
[CmdletBinding()]
param(
    [switch]$Json,
    [string]$ShortName,
    [int]$Number = 0,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FeatureDescription
)
$ErrorActionPreference = 'Stop'

# 显示帮助
if ($Help) {
    Write-Host "用法：./create-new-feature.ps1 [-Json] [-ShortName <name>] [-Number N] <feature description>"
    Write-Host ""
    Write-Host "选项："
    Write-Host "  -Json               以 JSON 格式输出"
    Write-Host "  -ShortName <name>   为分支提供自定义短名（2–4 个词）"
    Write-Host "  -Number N           手动指定分支编号（覆盖自动检测）"
    Write-Host "  -Help               显示帮助"
    Write-Host ""
    Write-Host "示例："
    Write-Host "  ./create-new-feature.ps1 'Add user authentication system' -ShortName 'user-auth'"
    Write-Host "  ./create-new-feature.ps1 'Implement OAuth2 integration for API'"
    exit 0
}

# 必需：特性描述
if (-not $FeatureDescription -or $FeatureDescription.Count -eq 0) {
    Write-Error "用法：./create-new-feature.ps1 [-Json] [-ShortName <name>] <feature description>"
    exit 1
}

$featureDesc = ($FeatureDescription -join ' ').Trim()

# 解析仓库根：优先 git，回退为标记目录搜索（支持 --no-git 初始化的仓库）
function Find-RepositoryRoot {
    param(
        [string]$StartDir,
        [string[]]$Markers = @('.git', '.specify')
    )
    $current = Resolve-Path $StartDir
    while ($true) {
        foreach ($marker in $Markers) {
            if (Test-Path (Join-Path $current $marker)) {
                return $current
            }
        }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) {
            # 到达文件系统根仍未找到
            return $null
        }
        $current = $parent
    }
}

function Get-NextBranchNumber {
    param(
        [string]$ShortName,
        [string]$SpecsDir
    )
    
    # 获取远端分支（无远端时忽略错误）
    try {
        git fetch --all --prune 2>$null | Out-Null
    } catch {
        # 忽略
    }
    
    # 远端分支匹配
    $remoteBranches = @()
    try {
        $remoteRefs = git ls-remote --heads origin 2>$null
        if ($remoteRefs) {
            $remoteBranches = $remoteRefs | Where-Object { $_ -match "refs/heads/(\d+)-$([regex]::Escape($ShortName))$" } | ForEach-Object {
                if ($_ -match "refs/heads/(\d+)-") { [int]$matches[1] }
            }
        }
    } catch { }
    
    # 本地分支匹配
    $localBranches = @()
    try {
        $allBranches = git branch 2>$null
        if ($allBranches) {
            $localBranches = $allBranches | Where-Object { $_ -match "^\*?\s*(\d+)-$([regex]::Escape($ShortName))$" } | ForEach-Object {
                if ($_ -match "(\d+)-") { [int]$matches[1] }
            }
        }
    } catch { }
    
    # 规格目录匹配
    $specDirs = @()
    if (Test-Path $SpecsDir) {
        try {
            $specDirs = Get-ChildItem -Path $SpecsDir -Directory | Where-Object { $_.Name -match "^(\d+)-$([regex]::Escape($ShortName))$" } | ForEach-Object {
                if ($_.Name -match "^(\d+)-") { [int]$matches[1] }
            }
        } catch { }
    }
    
    # 取最大编号
    $maxNum = 0
    foreach ($num in ($remoteBranches + $localBranches + $specDirs)) {
        if ($num -gt $maxNum) { $maxNum = $num }
    }
    
    return $maxNum + 1
}
$fallbackRoot = (Find-RepositoryRoot -StartDir $PSScriptRoot)
if (-not $fallbackRoot) {
    Write-Error "错误：无法确定仓库根目录，请在仓库内运行此脚本。"
    exit 1
}

try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0) {
        $hasGit = $true
    } else { throw "Git not available" }
} catch {
    $repoRoot = $fallbackRoot
    $hasGit = $false
}

Set-Location $repoRoot

$specsDir = Join-Path $repoRoot 'specs'
New-Item -ItemType Directory -Path $specsDir -Force | Out-Null

# 生成分支短名（停用词过滤与长度限制）
function Get-BranchName {
    param([string]$Description)
    
    # 常见停用词
    $stopWords = @(
        'i','a','an','the','to','for','of','in','on','at','by','with','from',
        'is','are','was','were','be','been','being','have','has','had',
        'do','does','did','will','would','should','could','can','may','might','must','shall',
        'this','that','these','those','my','your','our','their',
        'want','need','add','get','set'
    )
    
    # 小写化并提取单词
    $cleanName = $Description.ToLower() -replace '[^a-z0-9\s]', ' '
    $words = $cleanName -split '\s+' | Where-Object { $_ }
    
    # 过滤：去停用词与 <3 的词（若原文为大写缩写则保留）
    $meaningfulWords = @()
    foreach ($word in $words) {
        if ($stopWords -contains $word) { continue }
        if ($word.Length -ge 3) { $meaningfulWords += $word }
        elseif ($Description -match "\b$($word.ToUpper())\b") { $meaningfulWords += $word }
    }
    
    if ($meaningfulWords.Count -gt 0) {
        $maxWords = if ($meaningfulWords.Count -eq 4) { 4 } else { 3 }
        $result = ($meaningfulWords | Select-Object -First $maxWords) -join '-'
        return $result
    } else {
        $result = $Description.ToLower() -replace '[^a-z0-9]', '-' -replace '-{2,}', '-' -replace '^-', '' -replace '-$', ''
        $fallbackWords = ($result -split '-') | Where-Object { $_ } | Select-Object -First 3
        return [string]::Join('-', $fallbackWords)
    }
}

# 分支名后缀
if ($ShortName) {
    $branchSuffix = $ShortName.ToLower() -replace '[^a-z0-9]', '-' -replace '-{2,}', '-' -replace '^-', '' -replace '-$', ''
} else {
    $branchSuffix = Get-BranchName -Description $featureDesc
}

# 分支编号
if ($Number -eq 0) {
    if ($hasGit) {
        $Number = Get-NextBranchNumber -ShortName $branchSuffix -SpecsDir $specsDir
    } else {
        $highest = 0
        if (Test-Path $specsDir) {
            Get-ChildItem -Path $specsDir -Directory | ForEach-Object {
                if ($_.Name -match '^(\d{3})') {
                    $num = [int]$matches[1]
                    if ($num -gt $highest) { $highest = $num }
                }
            }
        }
        $Number = $highest + 1
    }
}

$featureNum = ('{0:000}' -f $Number)
$branchName = "$featureNum-$branchSuffix"

# GitHub 分支名 244 字节上限
$maxBranchLength = 244
if ($branchName.Length -gt $maxBranchLength) {
    $maxSuffixLength = $maxBranchLength - 4  # 3 位编号 + 连字符
    $truncatedSuffix = $branchSuffix.Substring(0, [Math]::Min($branchSuffix.Length, $maxSuffixLength))
    $truncatedSuffix = $truncatedSuffix -replace '-$', ''
    $originalBranchName = $branchName
    $branchName = "$featureNum-$truncatedSuffix"
    Write-Warning "[specify] 分支名超过 GitHub 244 字节上限"
    Write-Warning "[specify] 原始：$originalBranchName ($($originalBranchName.Length) bytes)"
    Write-Warning "[specify] 截断为：$branchName ($($branchName.Length) bytes)"
}

if ($hasGit) {
    try { git checkout -b $branchName | Out-Null }
    catch { Write-Warning "创建 git 分支失败：$branchName" }
} else {
    Write-Warning "[specify] 警告：未检测到 Git 仓库；已跳过创建分支 $branchName"
}

$featureDir = Join-Path $specsDir $branchName
New-Item -ItemType Directory -Path $featureDir -Force | Out-Null

$template = Join-Path $repoRoot '.specify/templates/spec-template.md'
$specFile = Join-Path $featureDir 'spec.md'
if (Test-Path $template) { Copy-Item $template $specFile -Force } else { New-Item -ItemType File -Path $specFile | Out-Null }

# 设置当前会话的 SPECIFY_FEATURE 环境变量
$env:SPECIFY_FEATURE = $branchName

if ($Json) {
    $obj = [PSCustomObject]@{ 
        BRANCH_NAME = $branchName
        SPEC_FILE = $specFile
        FEATURE_NUM = $featureNum
        HAS_GIT = $hasGit
    }
    $obj | ConvertTo-Json -Compress
} else {
    Write-Output "BRANCH_NAME: $branchName"
    Write-Output "SPEC_FILE: $specFile"
    Write-Output "FEATURE_NUM: $featureNum"
    Write-Output "HAS_GIT: $hasGit"
    Write-Output "SPECIFY_FEATURE 环境变量已设置为：$branchName"
}

