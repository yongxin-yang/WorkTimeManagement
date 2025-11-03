---
description: 通过交互或提供的原则输入创建/更新项目宪章，并确保所有依赖模板保持同步。
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前（若不为空），你必须考虑用户输入。

## 概述

你将更新位于 `.specify/memory/constitution.md` 的项目宪章。该文件是一个包含方括号占位符（如 `[PROJECT_NAME]`、`[PRINCIPLE_1_NAME]`）的模板。你的工作是：（a）收集/推导具体值，（b）精确填充模板，（c）将任何修订传播到依赖制品。

执行流程：

1. 加载 `.specify/memory/constitution.md` 模板。
   - 识别所有 `[ALL_CAPS_IDENTIFIER]` 形式的占位符。
   重要：原则数量可能与模板示例不同。若用户指定数量，需遵从并更新文档。

2. 收集/推导占位符的值：
   - 若对话中提供了值，优先使用。
   - 否则从现有仓库上下文推断（README、文档、先前版本）。
   - 治理日期：`RATIFICATION_DATE` 为最初采纳日（未知则询问或标记 TODO）；`LAST_AMENDED_DATE` 若有变更则为今天，否则保持不变。
   - `CONSTITUTION_VERSION` 遵循语义化版本：
     - MAJOR：向后不兼容的治理/原则删除或重定义
     - MINOR：新增或大幅扩展的原则/章节
     - PATCH：澄清、措辞、拼写修复、无语义变化
   - 若不确定升级类型，先给出理由再确定。

3. 拟定更新后的宪章内容：
   - 替换每个占位符（除非项目明确选择保留的模板槽位——需说明理由）
   - 保持标题层级；被替换后的注释可移除，除非仍具说明价值
   - 每条原则应包含：简洁名称、不可协商规则（段落或要点）、必要时的简短理由
   - 治理章节需包含：修订流程、版本策略、合规评审期望

4. 一致性传播检查清单（将先前清单转为实际校验）：
   - 读取 `.specify/templates/plan-template.md`，确保“宪章检查”与更新原则一致
   - 读取 `.specify/templates/spec-template.md`，若宪章增删必填部分/约束，则同步
   - 读取 `.specify/templates/tasks-template.md`，确保任务分类反映新增/移除的原则驱动类型（如可观测性、版本化、测试纪律）
   - 读取 `.specify/templates/commands/*.md`（包括本文件），移除过时引用（如代理专有名）并保持通用指引
   - 读取运行文档（README、docs/quickstart.md、代理特定指引等），更新变更后的原则引用

5. 生成同步影响报告（作为 HTML 注释放在宪章文件顶部）：
   - 版本变更：旧 → 新
   - 修改的原则列表（旧标题 → 新标题）
   - 新增章节
   - 删除章节
   - 需要更新的模板（✅ 已更新 / ⚠ 待处理）及路径
   - 若有保留的占位符，列为后续 TODO

6. 最终校验：
   - 无未解释的方括号占位符
   - 版本行与报告一致
   - 日期为 ISO 格式 YYYY-MM-DD
   - 原则具备宣告性、可测试性，避免模糊语言（“should” → 用 MUST/SHOULD 并给出理由）

7. 将完成内容写回 `.specify/memory/constitution.md`（覆盖写入）。

8. 向用户输出最终摘要：
   - 新版本与升级理由
   - 任何需要人工跟进的文件
   - 建议的提交信息（如：`docs: amend constitution to vX.Y.Z (principle additions + governance update)`）

格式与风格要求：

- 使用与模板一致的 Markdown 标题（不提升/降低级别）
- 长理由行适度换行以保持可读性（不强制硬换行）
- 章节之间保留单个空行
- 避免尾随空白

若用户仅提供部分更新（如仅修订一条原则），仍需执行校验与版本决策步骤。

若关键信息缺失（如无法获知采纳日期），插入 `TODO(<FIELD_NAME>): 说明`，并在同步影响报告中标注为延期项。

不要创建新模板；仅在现有 `.specify/memory/constitution.md` 上操作。
