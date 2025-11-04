# 实施计划：多功能计时软件

**分支**：`001-work-timer` | **日期**：2025-01-27 | **规范**：[spec.md](./spec.md)  
**输入**：来自 `/specs/001-work-timer/spec.md` 的特性规范

说明：此模板由 `/speckit.plan` 填充。执行流程见 `.specify/templates/commands/plan.md`。

## 摘要

开发一个多功能计时软件，支持 Windows 桌面端（PySide6）和 Android 移动端。核心功能包括自动无感登录、时间分配统计（天/周/月维度）、工作模式（任务选择、开始/结束、快速切换）、工作记录管理（任务 CRUD、记录编辑/转移）。系统需具备存储完整性检查与自动修复能力，确保异常关闭（如断电）时数据可恢复。技术路线：Windows 端使用 Python 3.11+ + PySide6，Android 端使用 Kotlin 1.9+ + Jetpack Compose，数据层统一使用 SQLite（Room on Android），共享数据契约与聚合口径。

## 技术上下文

**语言/版本**：Python 3.11+（Windows）、Kotlin 1.9+（Android）  
**主要依赖**：PySide6（Windows GUI）、Jetpack Compose（Android UI）、SQLModel（Windows 数据访问）、SQLite（Room on Android）  
**存储**：SQLite 数据库（Windows 使用 SQLModel，Android 使用 Room）  
**测试**：pytest（Windows）、JUnit/Espresso（Android）  
**目标平台**：Windows 桌面、Android 移动端  
**项目类型**：mobile（双平台应用）  
**性能目标**：1 万条记录规模下统计查询 ≤ 3 秒，界面切换 ≤ 1 秒，悬浮按钮切换 ≤ 2 秒  
**约束**：本地优先、离线可用、数据恢复率 ≥ 95%、自动修复成功率 ≥ 90%、错误率 ≤ 0.1%  
**规模/范围**：1 万条工作记录、3 个主要功能模块、默认任务 2 个（工作、摸鱼）

## 宪章检查

门禁：在阶段 0 调研前必须通过；阶段 1 设计后重检。

1. ✅ Windows（PySide6）与 Android：两端等价能力；技术栈与数据口径一致。
   - Windows 端使用 PySide6，Android 端使用 Jetpack Compose，功能等价（记录、编辑、统计）
   - 数据模型统一，共享数据契约与聚合口径

2. ✅ 核心数据统一：本地持久化模型一致（事件明细→聚合）。
   - 使用 SQLite 作为统一存储（Windows 直接使用，Android 使用 Room）
   - 工作记录作为明细，统计基于明细聚合，可重算

3. ✅ 统计可验证：项目/天/月的聚合口径一致且可重算。
   - 统计基于工作记录明细聚合
   - 支持按任务、按天/周/月维度统计，口径一致

4. ✅ 集成合约预留：导入/导出格式定义，含版本字段与兼容策略。
   - 预留导入/导出接口（JSON/CSV 格式）
   - 数据契约包含版本字段，支持向后兼容

5. ✅ 简单与最小依赖：避免额外依赖与多层抽象，职责单一。
   - Windows：PySide6（GUI）+ SQLModel（数据访问）+ Python 标准库
   - Android：Compose（UI）+ Room（数据）+ Coroutines（可选）
   - 避免过度抽象，模块职责清晰

## 项目结构

### 文档（本特性）

```text
specs/001-work-timer/
├── plan.md              # 本文件（/speckit.plan 输出）
├── research.md          # 阶段 0 输出（/speckit.plan）
├── data-model.md        # 阶段 1 输出（/speckit.plan）
├── quickstart.md        # 阶段 1 输出（/speckit.plan）
├── contracts/           # 阶段 1 输出（/speckit.plan）
└── tasks.md             # 阶段 2 输出（/speckit.tasks 生成）
```

### 源码（仓库根）

```text
# Windows 端
windows/
├── src/
│   ├── models/          # 数据模型（任务、工作记录）
│   ├── services/        # 业务逻辑（时间统计、存储管理）
│   ├── ui/              # PySide6 UI 组件
│   │   ├── main_window.py
│   │   ├── home_page.py
│   │   ├── statistics_page.py
│   │   ├── work_mode_page.py
│   │   └── record_management_page.py
│   ├── utils/           # 工具函数（存储检查、修复）
│   └── main.py          # 应用入口
└── tests/
    ├── unit/            # 单元测试
    ├── integration/     # 集成测试
    └── fixtures/        # 测试数据

# Android 端
android/
├── app/
│   ├── src/main/java/com/worktimer/
│   │   ├── data/        # Room 数据库、实体、DAO
│   │   ├── domain/      # 业务逻辑
│   │   ├── ui/          # Compose UI
│   │   │   ├── home/
│   │   │   ├── statistics/
│   │   │   ├── workmode/
│   │   │   └── management/
│   │   └── utils/       # 工具函数（存储检查、修复）
│   └── src/test/        # 单元测试
└── build.gradle.kts

# 共享数据契约（可选）
shared/
└── contracts/           # 数据模型定义（JSON Schema）
    ├── task.json
    ├── work_record.json
    └── statistics.json
```

**结构决策**：采用双平台独立结构（windows/ 和 android/），共享数据契约（shared/contracts/）。Windows 端使用 Python 标准项目结构，Android 端遵循 Android 标准项目结构。数据层统一使用 SQLite，但实现方式不同（Windows 使用 SQLModel，Android 使用 Room）。

## 复杂度跟踪

无需填写（无宪章违规）
