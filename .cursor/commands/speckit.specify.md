---
description: 从自然语言的特性描述创建或更新特性规范。
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前（若不为空），你必须考虑用户输入。

## 概述

在触发消息中，`/speckit.specify` 之后的文字即为特性描述。即使下文显示 `$ARGUMENTS` 字面量，也视为你已在对话中获取该描述。除非命令为空，不要让用户重复输入。

基于该特性描述，执行：

1. 生成简短分支名（2–4 个词）：
   - 提取最有意义的关键词
   - 使用动词-名词格式（如 “add-user-auth”、“fix-payment-bug”）
   - 保留技术缩写（OAuth2、API、JWT 等）
   - 简洁但可读
   - 示例：
     - “I want to add user authentication” → “user-auth”
     - “Implement OAuth2 integration for the API” → “oauth2-api-integration”
     - “Create a dashboard for analytics” → “analytics-dashboard”
     - “Fix payment processing timeout bug” → “fix-payment-timeout”

2. 创建新分支前先检查是否已存在：
   a) 先拉取分支：
   ```bash
   git fetch --all --prune
   ```
   b) 在三处来源查找该短名的最高特性号：
   - 远端分支：`git ls-remote --heads origin | grep -E 'refs/heads/[0-9]+-<short-name>$'`
   - 本地分支：`git branch | grep -E '^[* ]*[0-9]+-<short-name>$'`
   - 规格目录：`specs/[0-9]+-<short-name>`
   c) 确定下一个可用编号：收集数字，取最大 N，使用 N+1
   d) 运行 `.specify/scripts/powershell/create-new-feature.ps1 -Json "$ARGUMENTS"` 并传入 `--number N+1` 与 `--short-name`：
   - Bash 示例：`.specify/scripts/powershell/create-new-feature.ps1 -Json "$ARGUMENTS" --json --number 5 --short-name "user-auth" "Add user authentication"`
   - PowerShell 示例：`.specify/scripts/powershell/create-new-feature.ps1 -Json "$ARGUMENTS" -Json -Number 5 -ShortName "user-auth" "Add user authentication"`

   重要：
   - 必须同时检查远端、本地与目录
   - 仅匹配该短名的精确模式
   - 若无任何匹配则从 1 开始
   - 每个特性此脚本只运行一次
   - 以终端 JSON 输出为准（包含 BRANCH_NAME 与 SPEC_FILE）
   - 参数中单引号需转义：'I'\''m Groot'（或使用双引号）

3. 加载 `.specify/templates/spec-template.md` 理解所需章节。

4. 执行流程：
   1) 解析输入中的特性描述（为空则报错）
   2) 提取关键词：参与者、动作、数据、约束
   3) 不清晰之处：
      - 在有行业通用默认时作合理假设
      - 仅当满足以下任一条件时使用 [NEEDS CLARIFICATION: 具体问题]：
        - 选择将显著影响范围或体验
        - 存在多个合理解释且影响不同
        - 不存在合理默认
      - 总数最多 3 处，按影响优先：范围 > 安全/隐私 > 体验 > 技术细节
   4) 填写“用户场景与测试”（无清晰用户流则报错）
   5) 生成“功能性需求”（必须可测试）；未指明细节采用“假设”章节记录
   6) 定义“成功标准”：可度量、与技术无关、可验证；含定量与定性
   7) 识别关键实体（若有数据）
   8) 返回：SUCCESS（规范可用于规划）

5. 按模板结构写入 SPEC_FILE，用从特性描述推导的具体内容替换占位，保持章节顺序与标题。

6. 规范质量校验：写入后创建需求质量清单并校验：
   a) 在 `FEATURE_DIR/checklists/requirements.md` 生成清单，结构如下：

   ```markdown
   # Specification Quality Checklist: [FEATURE NAME]

   **Purpose**: Validate specification completeness and quality before proceeding to planning
   **Created**: [DATE]
   **Feature**: [Link to spec.md]

   ## Content Quality

   - [ ] No implementation details (languages, frameworks, APIs)
   - [ ] Focused on user value and business needs
   - [ ] Written for non-technical stakeholders
   - [ ] All mandatory sections completed

   ## Requirement Completeness

   - [ ] No [NEEDS CLARIFICATION] markers remain
   - [ ] Requirements are testable and unambiguous
   - [ ] Success criteria are measurable
   - [ ] Success criteria are technology-agnostic (no implementation details)
   - [ ] All acceptance scenarios are defined
   - [ ] Edge cases are identified
   - [ ] Scope is clearly bounded
   - [ ] Dependencies and assumptions identified

   ## Feature Readiness

   - [ ] All functional requirements have clear acceptance criteria
   - [ ] User scenarios cover primary flows
   - [ ] Feature meets measurable outcomes defined in Success Criteria
   - [ ] No implementation details leak into specification

   ## Notes

   - Items marked incomplete require spec updates before `/speckit.clarify` or `/speckit.plan`
   ```

   b) 运行校验：逐项判定通过/失败，并引用问题片段。

   c) 处理结果：
   - 全通过：标记完成并进入下一步
   - 失败（不含 [NEEDS CLARIFICATION]）：列出失败项 → 更新规范 → 迭代至多 3 次；仍失败则记录并提示风险
   - 若仍有 [NEEDS CLARIFICATION]：
     1) 提取所有标记；若 >3，仅保留 3 个最关键；其余作合理假设
     2) 为每个澄清生成问答块（表格：Option/Answer/Implications），编号 Q1–Q3
     3) 一次性呈现全部问题并等待用户回答格式（如 “Q1: A, Q2: Custom - ..., Q3: B”）
     4) 根据回答替换标记并重跑校验

   d) 每轮校验后更新清单状态。

7. 报告完成：输出分支名、规范路径、清单结果以及下一阶段（`/speckit.clarify` 或 `/speckit.plan`）就绪情况。

说明：脚本会创建并切换到新分支，并在写入前初始化规范文件。

## 通用指南

- 聚焦用户“做什么/为什么”；避免“如何实现”；面向业务干系人书写；不要在规范中内嵌清单。
- 章节：必须/可选。无关章节直接删除（不要写 N/A）。

### AI 生成指引

- 做合理假设；记录“假设”；澄清标记最多 3 处，且仅用于关键决策。
- 澄清优先级：范围 > 安全/隐私 > 体验 > 技术细节。
- 像测试人员一样思考：含糊需求应无法通过“可测试与明确”的校验。
- 常见澄清（若无合理默认）：范围边界、用户类型与权限、安全/合规。

合理默认示例（不必询问）：
- 数据保留：行业惯例
- 性能目标：常见 Web/移动预期
- 错误处理：友好提示与回退
- 认证方式：Web 默认会话或 OAuth2
- 集成模式：RESTful

### 成功标准准则

- 可度量（时间、百分比、数量、速率）
- 与技术无关（不提框架/语言/数据库/工具）
- 面向用户/业务结果
- 可在未知实现细节时验证

好例：
- 用户 3 分钟内完成结账
- 系统支持 10,000 并发
- 95% 搜索 1 秒内返回
- 任务完成率提升 40%

坏例（太实现导向）：
- API 响应 <200ms（用“用户看到结果几乎即时”）
- 数据库 1000 TPS（用“业务侧吞吐目标”）
- React 渲染高效（框架特定）
- Redis 命中率 >80%（技术特定）
