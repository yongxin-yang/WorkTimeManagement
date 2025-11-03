---
description: 使用规划模板执行实现规划工作流并生成设计制品。
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前（若不为空），你必须考虑用户输入。

## 概述

1. 设置：在仓库根目录运行 `.specify/scripts/powershell/setup-plan.ps1 -Json`，解析 FEATURE_SPEC、IMPL_PLAN、SPECS_DIR、BRANCH。参数含单引号时转义：'I'\''m Groot'（或使用双引号）。

2. 加载上下文：读取 FEATURE_SPEC 与 `.specify/memory/constitution.md`；加载已复制的 IMPL_PLAN 模板。

3. 执行规划流程（按 IMPL_PLAN 模板结构）：
   - 填写“技术上下文”（未知项标记为 “NEEDS CLARIFICATION”）
   - 从宪章填充“宪章检查”
   - 评估门禁（如违规且无正当理由 → 报错）
   - 阶段 0：生成 research.md（解决所有 NEEDS CLARIFICATION）
   - 阶段 1：生成 data-model.md、contracts/、quickstart.md
   - 阶段 1：运行代理脚本更新代理上下文
   - 再次评估“宪章检查”（设计后）

4. 停止并报告：命令在阶段 2 规划后结束。报告分支、IMPL_PLAN 路径与生成的制品。

## 阶段

### 阶段 0：纲要与调研

1. 从“技术上下文”提取未知项：
   - 每个 NEEDS CLARIFICATION → 调研任务
   - 每个依赖 → 最佳实践任务
   - 每个集成 → 模式任务

2. 生成并派发调研代理：

   ```text
   对每个未知：Task: "Research {unknown} for {feature context}"
   对每个技术选择：Task: "Find best practices for {tech} in {domain}"
   ```

3. 在 `research.md` 中整合发现：
   - Decision：选择
   - Rationale：理由
   - Alternatives：备选

输出：`research.md` 完成且清除所有 NEEDS CLARIFICATION。

### 阶段 1：设计与合约

前提：`research.md` 已完成。

1. 从特性规范提取实体 → `data-model.md`：
   - 实体名、字段、关系
   - 来自需求的校验规则
   - 如适用，状态转移

2. 从功能需求生成 API 合约：
   - 每个用户动作 → 一个端点
   - 使用标准 REST/GraphQL 模式
   - 输出 OpenAPI/GraphQL 至 `/contracts/`

3. 更新代理上下文：
   - 运行 `.specify/scripts/powershell/update-agent-context.ps1 -AgentType cursor-agent`
   - 脚本会检测当前所用 AI 代理
   - 更新对应代理的上下文文件
   - 仅追加本次规划新增技术；保留标记间的手动添加

输出：`data-model.md`、`/contracts/*`、`quickstart.md`、代理特定文件。

## 关键规则

- 使用绝对路径
- 门禁失败或澄清未解决时报错
