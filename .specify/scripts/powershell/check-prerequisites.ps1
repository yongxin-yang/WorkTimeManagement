#!/usr/bin/env pwsh

# 前置条件统一检查脚本（PowerShell）
#
# 该脚本为基于规范驱动的开发流程提供统一的前置检查，
# 替代分散在多个脚本中的功能。
#
# 用法：./check-prerequisites.ps1 [OPTIONS]
#
# 选项：
#   -Json               以 JSON 格式输出
#   -RequireTasks       要求存在 tasks.md（实施阶段使用）
#   -IncludeTasks       在 AVAILABLE_DOCS 中包含 tasks.md
#   -PathsOnly          仅输出路径变量（不做校验）
#   -Help, -h           显示帮助

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$RequireTasks,
    [switch]$IncludeTasks,
    [switch]$PathsOnly,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# 显示帮助
if ($Help) {
    Write-Output @"
用法：check-prerequisites.ps1 [OPTIONS]

为规范驱动开发流程提供统一的前置条件检查。

选项：
  -Json               以 JSON 格式输出
  -RequireTasks       要求存在 tasks.md（实施阶段）
  -IncludeTasks       在 AVAILABLE_DOCS 中包含 tasks.md
  -PathsOnly          仅输出路径变量（不做前置校验）
  -Help, -h           显示帮助

示例：
  # 任务前置检查（要求 plan.md）
  .\check-prerequisites.ps1 -Json
  
  # 实施前置检查（要求 plan.md + tasks.md）
  .\check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
  
  # 仅获取特性路径（不校验）
  .\check-prerequisites.ps1 -PathsOnly

"@
    exit 0
}

# 引入通用函数
. "$PSScriptRoot/common.ps1"

# 获取特性路径并校验分支
$paths = Get-FeaturePathsEnv

if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit:$paths.HAS_GIT)) { 
    exit 1 
}

# 仅输出路径并退出（支持 -Json -PathsOnly 组合）
if ($PathsOnly) {
    if ($Json) {
        [PSCustomObject]@{
            REPO_ROOT    = $paths.REPO_ROOT
            BRANCH       = $paths.CURRENT_BRANCH
            FEATURE_DIR  = $paths.FEATURE_DIR
            FEATURE_SPEC = $paths.FEATURE_SPEC
            IMPL_PLAN    = $paths.IMPL_PLAN
            TASKS        = $paths.TASKS
        } | ConvertTo-Json -Compress
    } else {
        Write-Output "REPO_ROOT: $($paths.REPO_ROOT)"
        Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
        Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
        Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
        Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
        Write-Output "TASKS: $($paths.TASKS)"
    }
    exit 0
}

# 校验必需目录与文件
if (-not (Test-Path $paths.FEATURE_DIR -PathType Container)) {
    Write-Output "ERROR: 未找到特性目录：$($paths.FEATURE_DIR)"
    Write-Output "请先运行 /speckit.specify 创建特性结构。"
    exit 1
}

if (-not (Test-Path $paths.IMPL_PLAN -PathType Leaf)) {
    Write-Output "ERROR: 未在 $($paths.FEATURE_DIR) 找到 plan.md"
    Write-Output "请先运行 /speckit.plan 生成实施计划。"
    exit 1
}

# 若要求 tasks.md，则检查
if ($RequireTasks -and -not (Test-Path $paths.TASKS -PathType Leaf)) {
    Write-Output "ERROR: 未在 $($paths.FEATURE_DIR) 找到 tasks.md"
    Write-Output "请先运行 /speckit.tasks 生成任务列表。"
    exit 1
}

# 构建可用文档列表
$docs = @()

# 可选文档
if (Test-Path $paths.RESEARCH) { $docs += 'research.md' }
if (Test-Path $paths.DATA_MODEL) { $docs += 'data-model.md' }

# contracts 目录（存在且非空）
if ((Test-Path $paths.CONTRACTS_DIR) -and (Get-ChildItem -Path $paths.CONTRACTS_DIR -ErrorAction SilentlyContinue | Select-Object -First 1)) { 
    $docs += 'contracts/' 
}

if (Test-Path $paths.QUICKSTART) { $docs += 'quickstart.md' }

# 按需包含 tasks.md
if ($IncludeTasks -and (Test-Path $paths.TASKS)) { 
    $docs += 'tasks.md' 
}

# 输出结果
if ($Json) {
    [PSCustomObject]@{ 
        FEATURE_DIR = $paths.FEATURE_DIR
        AVAILABLE_DOCS = $docs 
    } | ConvertTo-Json -Compress
} else {
    Write-Output "FEATURE_DIR:$($paths.FEATURE_DIR)"
    Write-Output "AVAILABLE_DOCS:"
    
    # 展示每个潜在文档的状态
    Test-FileExists -Path $paths.RESEARCH -Description 'research.md' | Out-Null
    Test-FileExists -Path $paths.DATA_MODEL -Description 'data-model.md' | Out-Null
    Test-DirHasFiles -Path $paths.CONTRACTS_DIR -Description 'contracts/' | Out-Null
    Test-FileExists -Path $paths.QUICKSTART -Description 'quickstart.md' | Out-Null
    
    if ($IncludeTasks) {
        Test-FileExists -Path $paths.TASKS -Description 'tasks.md' | Out-Null
    }
}
