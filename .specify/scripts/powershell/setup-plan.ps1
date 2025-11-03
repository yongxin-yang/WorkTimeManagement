#!/usr/bin/env pwsh
# 为特性准备实施计划

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# 显示帮助
if ($Help) {
    Write-Output "用法：./setup-plan.ps1 [-Json] [-Help]"
    Write-Output "  -Json     以 JSON 格式输出结果"
    Write-Output "  -Help     显示帮助"
    exit 0
}

# 加载通用函数
. "$PSScriptRoot/common.ps1"

# 获取路径环境
$paths = Get-FeaturePathsEnv

# 仅对 git 仓库校验分支命名
if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit $paths.HAS_GIT)) { 
    exit 1 
}

# 确保特性目录存在
New-Item -ItemType Directory -Path $paths.FEATURE_DIR -Force | Out-Null

# 复制计划模板（如存在），否则创建空文件
$template = Join-Path $paths.REPO_ROOT '.specify/templates/plan-template.md'
if (Test-Path $template) { 
    Copy-Item $template $paths.IMPL_PLAN -Force
    Write-Output "已复制计划模板至 $($paths.IMPL_PLAN)"
} else {
    Write-Warning "未在 $template 找到计划模板"
    New-Item -ItemType File -Path $paths.IMPL_PLAN -Force | Out-Null
}

# 输出
if ($Json) {
    $result = [PSCustomObject]@{ 
        FEATURE_SPEC = $paths.FEATURE_SPEC
        IMPL_PLAN = $paths.IMPL_PLAN
        SPECS_DIR = $paths.FEATURE_DIR
        BRANCH = $paths.CURRENT_BRANCH
        HAS_GIT = $paths.HAS_GIT
    }
    $result | ConvertTo-Json -Compress
} else {
    Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
    Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
    Write-Output "SPECS_DIR: $($paths.FEATURE_DIR)"
    Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
    Write-Output "HAS_GIT: $($paths.HAS_GIT)"
}

