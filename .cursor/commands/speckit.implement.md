---
description: 按照 tasks.md 定义的任务执行实现计划。
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前（若不为空），你必须考虑用户输入。

## 概述

1. 在仓库根目录运行 `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks`，解析 FEATURE_DIR 与 AVAILABLE_DOCS。所有路径需为绝对路径。参数含单引号时转义：'I'\''m Groot'（或使用双引号）。

2. 检查清单状态（若存在 `FEATURE_DIR/checklists/`）：
   - 扫描目录内所有清单文件
   - 统计：总条目（`- [ ]`/`- [X]`/`- [x]`）、已完成（`- [X]`/`- [x]`）、未完成（`- [ ]`）
   - 生成状态表：

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - 总体判定：所有清单未完成数为 0 → PASS；否则 FAIL
   - 若存在未完成：展示表并询问“清单未完成，是否仍要继续实现？（yes/no）”；根据回答继续或停止
   - 若全部完成：展示通过表并自动进入下一步

3. 加载并分析实现上下文：
   - 必需：读取 tasks.md（完整任务与执行计划）
   - 必需：读取 plan.md（技术栈、架构、文件结构）
   - 若存在：读取 data-model.md、contracts/、research.md、quickstart.md

4. 项目设置校验（按实际项目生成/校验忽略文件）：
   - 使用 `git rev-parse --git-dir 2>/dev/null` 判断是否 git 仓库（若是则校验/创建 .gitignore）
   - 若存在 Dockerfile* 或 plan.md 有 Docker → .dockerignore
   - 若存在 .eslintrc*/eslint.config.* → .eslintignore
   - 若存在 .prettierrc* → .prettierignore
   - 若存在 .npmrc 或 package.json → .npmignore（发布时）
   - 若存在 *.tf → .terraformignore
   - 若存在 helm charts → .helmignore
   - 已有忽略文件：追加关键缺失规则；缺失则按技术栈创建常用规则

   常见技术模式（示例）：
   - Node/TS：node_modules/、dist/、build/、*.log、.env*
   - Python：__pycache__/、*.pyc、.venv/、venv/、dist/、*.egg-info/
   - Java：target/、*.class、*.jar、.gradle/、build/
   - .NET：bin/、obj/、*.user、*.suo、packages/
   - Go：*.exe、*.test、vendor/、*.out
   - Ruby：.bundle/、log/、tmp/、*.gem、vendor/bundle/
   - PHP：vendor/、*.log、*.cache、*.env
   - Rust：target/、debug/、release/、*.rs.bk、*.rlib、*.prof*、.idea/、*.log、.env*
   - Kotlin：build/、out/、.gradle/、.idea/、*.class、*.jar、*.iml、*.log、.env*
   - C/C++：build/、bin/、obj/、out/、*.o、*.so、*.a、*.exe、*.dll、.idea/、*.log、.env*
   - Swift：.build/、DerivedData/、*.swiftpm/、Packages/
   - R：.Rproj.user/、.Rhistory、.RData、.Ruserdata、*.Rproj、packrat/、renv/
   - 通用：.DS_Store、Thumbs.db、*.tmp、*.swp、.vscode/、.idea/

   工具特定（示例）：
   - Docker、ESLint、Prettier、Terraform、Kubernetes 等（参照对应常见忽略模式）

5. 解析 tasks.md：
   - 任务阶段：Setup、Tests、Core、Integration、Polish
   - 依赖：串行与并行规则
   - 细节：ID、描述、文件路径、并行标记 [P]
   - 执行流：顺序与依赖要求

6. 按计划执行实现：
   - 分阶段推进：完成一阶段再进入下一阶段
   - 尊重依赖：串行任务按序；带 [P] 的可并行
   - 测试优先：按 TDD 要求先执行测试相关任务
   - 文件级协调：影响同一文件的任务需串行
   - 校验检查点：每阶段结束时做最小验证

7. 实施执行规则：
   - 先 Setup：初始化结构、依赖、配置
   - 测试先于代码（若要求编写合约/实体/集成测试）
   - 核心开发：实现模型、服务、命令、端点
   - 集成工作：数据库、Middleware、日志、外部服务
   - 打磨与验证：单测、性能、文档

8. 进度与错误处理：
   - 每完成一个任务汇报进度
   - 非并行任务失败则停止
   - 并行任务：继续成功项并报告失败项
   - 提供清晰错误上下文与建议下一步
   - 重要：已完成的任务在 tasks 中标记为 [X]

9. 完成校验：
   - 所有必需任务均已完成
   - 实现与原规范一致
   - 测试通过且覆盖率达标
   - 符合技术计划
   - 输出最终状态与完成摘要

说明：假设 tasks.md 已完整。若不完整，建议先运行 `/speckit.tasks` 生成任务列表。
