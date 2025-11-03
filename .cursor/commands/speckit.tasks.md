---
description: 基于现有设计制品为该特性生成可执行、按依赖排序的 tasks.md。
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前（若不为空），你必须考虑用户输入。

## 概述

1. 设置：在仓库根目录运行 `.specify/scripts/powershell/check-prerequisites.ps1 -Json`，解析 FEATURE_DIR 与 AVAILABLE_DOCS。路径需为绝对路径。参数含单引号时转义：'I'\''m Groot'（或使用双引号）。

2. 加载设计文档（来自 FEATURE_DIR）：
   - 必需：plan.md（技术栈、库、结构）、spec.md（带优先级的用户故事）
   - 可选：data-model.md（实体）、contracts/（API 端点）、research.md（决策）、quickstart.md（测试场景）
   - 注：并非所有项目都有上述文件。任务应基于可用材料生成。

3. 执行任务生成工作流：
   - 解析 plan.md 提取技术栈、库与项目结构
   - 解析 spec.md 提取用户故事与优先级（P1、P2、P3...）
   - 若存在 data-model.md：抽取实体并映射至用户故事
   - 若存在 contracts/：将端点映射至用户故事
   - 若存在 research.md：提取用于 Setup 的决策
   - 以“用户故事”为主线组织任务（见规则）
   - 生成故事完成顺序的依赖图
   - 为每个故事生成并行执行示例
   - 校验任务完备性（每个故事具备独立可测所需的全部任务）

4. 生成 tasks.md：按 `.specify.specify/templates/tasks-template.md` 结构填充：
   - 正确的特性名（来自 plan.md）
   - 阶段 1：Setup（初始化）
   - 阶段 2：Foundational（所有故事的前置阻塞）
   - 阶段 3+：每个用户故事一个阶段（按 spec.md 优先级顺序）
   - 每阶段包含：目标、独立测试标准、测试（如请求）、实现任务
   - 最终阶段：打磨与横切关注
   - 所有任务严格遵循清单格式（见下方规则）
   - 为每个任务提供明确文件路径
   - 提供依赖关系与并行示例
   - 提供实现策略（MVP 优先，增量交付）

5. 报告：输出生成的 tasks.md 路径与摘要：
   - 任务总数与每个故事任务数
   - 识别的并行机会
   - 每个故事的独立测试标准
   - 建议的 MVP 范围（通常仅用户故事 1）
   - 格式校验：所有任务都符合清单格式（复选框、ID、标签、路径）

上下文：$ARGUMENTS。

该 tasks.md 应可直接驱动执行——每个任务足够具体，使 LLM 无需额外上下文即可完成。

## 任务生成规则

关键：任务必须按“用户故事”组织，以支持独立实现与测试。

测试为可选：仅当规范或用户明确要求 TDD 时生成测试任务。

### 清单格式（必需）

每个任务必须严格遵循：

```text
- [ ] [TaskID] [P?] [Story?] Description with file path
```

格式组件：

1. 复选框：始终以 `- [ ]` 开头
2. 任务 ID：按执行顺序递增（T001、T002、...）
3. [P] 标记：仅当可并行（不同文件、无未完成依赖）时加入
4. [Story] 标签：仅在用户故事阶段必需
   - 形式：[US1]、[US2]...
   - Setup/Foundational/Polish 阶段不使用故事标签
5. 描述：明确动作与精确文件路径

示例：
- 正确：`- [ ] T001 Create project structure per implementation plan`
- 正确：`- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
- 正确：`- [ ] T012 [P] [US1] Create User model in src/models/user.py`
- 正确：`- [ ] T014 [US1] Implement UserService in src/services/user_service.py`
- 错误：`- [ ] Create User model`（缺 ID 与故事标签）
- 错误：`T001 [US1] Create model`（缺复选框）
- 错误：`- [ ] [US1] Create User model`（缺任务 ID）
- 错误：`- [ ] T001 [US1] Create model`（缺文件路径）

### 任务组织

1) 来自用户故事（主组织）：
   - 每个故事（P1、P2、P3...）作为独立阶段
   - 将所需模型/服务/端点/UI 与之映射；测试（如请求）置于故事内相应位置
   - 标注故事依赖（大多数应相互独立）

2) 来自合约：
   - 将每个合约/端点映射到服务的用户故事
   - 若有测试请求：在实现前生成对应合约测试任务 [P]

3) 来自数据模型：
   - 将每个实体映射到使用它的故事
   - 若实体服务多个故事：置于最早需要的故事或 Setup 阶段
   - 关系 → 在相应故事阶段的服务层任务

4) 来自设置/基础设施：
   - 共享基础设施 → Setup 阶段
   - 阻塞前置 → Foundational 阶段
   - 故事特定的设置 → 放在该故事阶段

### 阶段结构

- 阶段 1：Setup（初始化）
- 阶段 2：Foundational（全局前置，完成后进入故事）
- 阶段 3+：按优先级的用户故事（P1、P2、P3...）
  - 故事内顺序：测试（如请求）→ 模型 → 服务 → 端点 → 集成
  - 每阶段应是完整、可独立验证的增量
- 最终阶段：Polish & Cross-Cutting Concerns
