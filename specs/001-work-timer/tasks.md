# 任务：多功能计时软件

**输入**：来自 `/specs/001-work-timer/` 的设计文档  
**前置**：plan.md（必需）、spec.md（用户故事必需）、research.md、data-model.md、contracts/

**测试**：本清单不包含测试任务（规范未明确要求 TDD）。

**组织**：任务按"用户故事"分组，以便每个故事可独立实现与测试。

## 格式：`[ID] [P?] [Story] 描述`

- **[P]**：可并行（不同文件、无依赖）
- **[Story]**：该任务所属的用户故事（如 US1、US2、US3）
- 描述中应包含精确文件路径

## 路径约定

- **Windows 端**：`windows/src/`、`windows/tests/`
- **Android 端**：`android/app/src/main/java/com/worktimer/`
- **共享契约**：`shared/contracts/`

---

## 阶段 1：Setup（共享基础设施）

**目的**：项目初始化与基础结构

- [ ] T001 创建 Windows 端项目结构 windows/src/（models/, services/, ui/, utils/）
- [ ] T002 创建 Android 端项目结构 android/app/src/main/java/com/worktimer/（data/, domain/, ui/, utils/）
- [ ] T003 [P] 创建共享契约目录 shared/contracts/
- [ ] T004 [P] 初始化 Windows 端 Python 项目并创建 requirements.txt
- [ ] T005 [P] 初始化 Android 端 Gradle 项目并配置 build.gradle.kts
- [ ] T006 [P] 配置 Windows 端 Lint 与格式化工具（pylint, black）
- [ ] T007 [P] 配置 Android 端 Lint 与格式化工具（ktlint）

---

## 阶段 2：Foundational（阻塞前置）

**目的**：所有用户故事开始前必须完成的核心基础设施

⚠️ 关键：未完成前不得进入任一用户故事

- [ ] T008 创建 Windows 端数据库初始化模块 windows/src/utils/db.py（SQLModel 引擎创建）
- [ ] T009 创建 Android 端数据库初始化模块 android/app/src/main/java/com/worktimer/data/AppDatabase.kt（Room 数据库）
- [ ] T010 [P] [US1] 创建 Task 模型 windows/src/models/task.py（SQLModel 实体）
- [ ] T011 [P] [US1] 创建 Task 实体 android/app/src/main/java/com/worktimer/data/entity/Task.kt（Room 实体）
- [ ] T012 [P] [US1] 创建 WorkRecord 模型 windows/src/models/work_record.py（SQLModel 实体，包含 RecordStatus 枚举）
- [ ] T013 [P] [US1] 创建 WorkRecord 实体 android/app/src/main/java/com/worktimer/data/entity/WorkRecord.kt（Room 实体，包含 RecordStatus 枚举）
- [ ] T014 实现 Windows 端数据库初始化函数 windows/src/utils/db.py（init_database，创建默认任务"工作"和"摸鱼"）
- [ ] T015 实现 Android 端数据库初始化函数 android/app/src/main/java/com/worktimer/data/AppDatabase.kt（创建默认任务"工作"和"摸鱼"）
- [ ] T016 [P] 创建 Windows 端存储路径配置模块 windows/src/utils/config.py（默认存储路径为当前目录下的 storage 文件夹）
- [ ] T017 [P] 创建 Android 端存储路径配置模块 android/app/src/main/java/com/worktimer/utils/Config.kt（使用 Context.getFilesDir()）
- [ ] T018 实现 Windows 端存储完整性检查模块 windows/src/utils/storage_check.py（检查未完成记录、外键完整性、数据一致性、索引完整性）
- [ ] T019 实现 Android 端存储完整性检查模块 android/app/src/main/java/com/worktimer/utils/StorageCheck.kt（检查未完成记录、外键完整性、数据一致性、索引完整性）
- [ ] T020 实现 Windows 端存储修复模块 windows/src/utils/storage_repair.py（自动修复未完成记录、重建索引、备份机制）
- [ ] T021 实现 Android 端存储修复模块 android/app/src/main/java/com/worktimer/utils/StorageRepair.kt（自动修复未完成记录、重建索引、备份机制）
- [ ] T022 实现 Windows 端定期保存机制 windows/src/utils/periodic_save.py（每 60 秒保存一次）
- [ ] T023 实现 Android 端定期保存机制 android/app/src/main/java/com/worktimer/utils/PeriodicSave.kt（每 60 秒保存一次）

检查点：基础可用——数据库初始化、存储检查/修复、定期保存机制就绪，可开始并行实现用户故事

---

## 阶段 3：用户故事 1 - 启动应用并查看时间统计（优先级：P1）🎯 MVP

**目标**：用户启动应用后，系统自动无感登录，进入主页。用户点击"时间分配统计"入口，查看当天、本周、本月的各任务时间分配情况。

**独立测试**：启动应用 → 进入统计页面 → 切换天/周/月视图 → 查看数据展示，完全测试并交付时间统计价值。

### 用户故事 1 的实现

- [ ] T024 [US1] 创建 Windows 端主窗口 windows/src/ui/main_window.py（PySide6 QMainWindow）
- [ ] T025 [US1] 创建 Android 端主 Activity android/app/src/main/java/com/worktimer/ui/MainActivity.kt（Jetpack Compose）
- [ ] T026 [US1] 实现 Windows 端自动无感登录逻辑 windows/src/ui/main_window.py（启动时自动完成，无需用户验证）
- [ ] T027 [US1] 实现 Android 端自动无感登录逻辑 android/app/src/main/java/com/worktimer/ui/MainActivity.kt（启动时自动完成，无需用户验证）
- [ ] T028 [US1] 创建 Windows 端主页 UI windows/src/ui/home_page.py（包含三个主要入口：时间分配统计、工作模式、工作记录管理，以及存储设置）
- [ ] T029 [US1] 创建 Android 端主页 UI android/app/src/main/java/com/worktimer/ui/home/HomeScreen.kt（包含三个主要入口：时间分配统计、工作模式、工作记录管理，以及存储设置）
- [ ] T030 [US1] 创建 Windows 端时间统计服务 windows/src/services/statistics_service.py（按天/周/月维度聚合工作记录）
- [ ] T031 [US1] 创建 Android 端时间统计服务 android/app/src/main/java/com/worktimer/domain/StatisticsService.kt（按天/周/月维度聚合工作记录）
- [ ] T032 [US1] 创建 Windows 端统计页面 UI windows/src/ui/statistics_page.py（显示天/周/月视图切换，展示各任务时间占比可视化图表或数据汇总）
- [ ] T033 [US1] 创建 Android 端统计页面 UI android/app/src/main/java/com/worktimer/ui/statistics/StatisticsScreen.kt（显示天/周/月视图切换，展示各任务时间占比可视化图表或数据汇总）
- [ ] T034 [US1] 实现 Windows 端统计查询性能优化 windows/src/services/statistics_service.py（使用索引、聚合查询、缓存 5 分钟）
- [ ] T035 [US1] 实现 Android 端统计查询性能优化 android/app/src/main/java/com/worktimer/domain/StatisticsService.kt（使用索引、聚合查询、缓存 5 分钟）
- [ ] T036 [US1] 实现 Windows 端启动时存储完整性检查 windows/src/ui/main_window.py（启动时调用 storage_check 模块）
- [ ] T037 [US1] 实现 Android 端启动时存储完整性检查 android/app/src/main/java/com/worktimer/ui/MainActivity.kt（启动时调用 StorageCheck 模块）
- [ ] T038 [US1] 集成 Windows 端主页与统计页面 windows/src/ui/main_window.py（从主页点击统计入口跳转到统计页面）
- [ ] T039 [US1] 集成 Android 端主页与统计页面 android/app/src/main/java/com/worktimer/ui/MainActivity.kt（从主页点击统计入口跳转到统计页面）

检查点：用户故事 1 可独立完整运行并可测试——启动应用 → 进入统计页面 → 切换天/周/月视图 → 查看数据展示

---

## 阶段 4：用户故事 2 - 使用工作模式记录时间（优先级：P1）🎯 MVP

**目标**：用户进入工作模式，从下拉菜单选择一个或两个已存在的任务，点击"开始"按钮进入工作状态。工作过程中，用户可通过悬浮按钮快速切换任务。点击"结束"按钮结束工作状态。

**独立测试**：选择任务 → 开始工作 → 切换任务 → 结束工作 → 查看记录，完全测试并交付时间记录价值。

### 用户故事 2 的实现

- [ ] T040 [US2] 创建 Windows 端工作模式服务 windows/src/services/work_mode_service.py（开始/结束/切换任务逻辑）
- [ ] T041 [US2] 创建 Android 端工作模式服务 android/app/src/main/java/com/worktimer/domain/WorkModeService.kt（开始/结束/切换任务逻辑）
- [ ] T042 [US2] 创建 Windows 端工作模式页面 UI windows/src/ui/work_mode_page.py（任务下拉菜单、开始/结束按钮、当前任务显示）
- [ ] T043 [US2] 创建 Android 端工作模式页面 UI android/app/src/main/java/com/worktimer/ui/workmode/WorkModeScreen.kt（任务下拉菜单、开始/结束按钮、当前任务显示）
- [ ] T044 [US2] 实现 Windows 端任务选择逻辑 windows/src/ui/work_mode_page.py（支持选择一个或两个任务）
- [ ] T045 [US2] 实现 Android 端任务选择逻辑 android/app/src/main/java/com/worktimer/ui/workmode/WorkModeScreen.kt（支持选择一个或两个任务）
- [ ] T046 [US2] 实现 Windows 端开始工作逻辑 windows/src/services/work_mode_service.py（创建 WorkRecord，状态为"进行中"，提供弹窗提示）
- [ ] T047 [US2] 实现 Android 端开始工作逻辑 android/app/src/main/java/com/worktimer/domain/WorkModeService.kt（创建 WorkRecord，状态为"进行中"，提供弹窗提示）
- [ ] T048 [US2] 实现 Windows 端结束工作逻辑 windows/src/services/work_mode_service.py（更新 WorkRecord，设置 end_time 和 duration，状态改为"已完成"，提供弹窗提示）
- [ ] T049 [US2] 实现 Android 端结束工作逻辑 android/app/src/main/java/com/worktimer/domain/WorkModeService.kt（更新 WorkRecord，设置 end_time 和 duration，状态改为"已完成"，提供弹窗提示）
- [ ] T050 [US2] 实现 Windows 端任务切换逻辑 windows/src/services/work_mode_service.py（结束当前记录，创建新记录，更新当前任务显示，提供弹窗提示）
- [ ] T051 [US2] 实现 Android 端任务切换逻辑 android/app/src/main/java/com/worktimer/domain/WorkModeService.kt（结束当前记录，创建新记录，更新当前任务显示，提供弹窗提示）
- [ ] T052 [US2] 实现 Windows 端悬浮按钮 windows/src/ui/floating_button.py（QSystemTrayIcon + 独立无边框窗口，显示任务切换键）
- [ ] T053 [US2] 实现 Android 端悬浮按钮 android/app/src/main/java/com/worktimer/ui/workmode/FloatingButton.kt（Notification + 快速设置磁贴，显示任务切换键）
- [ ] T054 [US2] 集成 Windows 端悬浮按钮与工作模式 windows/src/ui/work_mode_page.py（悬浮按钮切换任务时更新工作模式页面）
- [ ] T055 [US2] 集成 Android 端悬浮按钮与工作模式 android/app/src/main/java/com/worktimer/ui/workmode/WorkModeScreen.kt（Notification 快速操作切换任务时更新工作模式页面）
- [ ] T056 [US2] 实现 Windows 端任务名称自动更新逻辑 windows/src/services/work_mode_service.py（切换任务时，如果任务名称已被修改，自动识别并更新记录）
- [ ] T057 [US2] 实现 Android 端任务名称自动更新逻辑 android/app/src/main/java/com/worktimer/domain/WorkModeService.kt（切换任务时，如果任务名称已被修改，自动识别并更新记录）
- [ ] T058 [US2] 实现 Windows 端任务类型修改时保持记录不变逻辑 windows/src/services/work_mode_service.py（用户修改当前任务类型时，在下一次切换前保持当前记录不变）
- [ ] T059 [US2] 实现 Android 端任务类型修改时保持记录不变逻辑 android/app/src/main/java/com/worktimer/domain/WorkModeService.kt（用户修改当前任务类型时，在下一次切换前保持当前记录不变）
- [ ] T060 [US2] 集成 Windows 端主页与工作模式页面 windows/src/ui/main_window.py（从主页点击工作模式入口跳转到工作模式页面）
- [ ] T061 [US2] 集成 Android 端主页与工作模式页面 android/app/src/main/java/com/worktimer/ui/MainActivity.kt（从主页点击工作模式入口跳转到工作模式页面）
- [ ] T062 [US2] 实现 Windows 端工作过程中定期保存集成 windows/src/services/work_mode_service.py（集成 periodic_save 模块，每 60 秒保存一次）
- [ ] T063 [US2] 实现 Android 端工作过程中定期保存集成 android/app/src/main/java/com/worktimer/domain/WorkModeService.kt（集成 PeriodicSave 模块，每 60 秒保存一次）

检查点：用户故事 2 可独立完整运行并可测试——选择任务 → 开始工作 → 切换任务 → 结束工作 → 查看记录

---

## 阶段 5：用户故事 3 - 管理工作记录和任务（优先级：P2）

**目标**：用户进入工作记录管理页面，可以新建任务名称、管理任务信息（编辑、删除等）、转移或编辑已有工作记录。系统默认提供"工作"和"摸鱼"两个任务，这两个任务不可删除。

**独立测试**：创建新任务 → 编辑任务信息 → 编辑工作记录 → 尝试删除默认任务，完全测试并交付任务管理价值。

### 用户故事 3 的实现

- [ ] T064 [US3] 创建 Windows 端任务管理服务 windows/src/services/task_service.py（创建、编辑、删除任务逻辑，默认任务不可删除检查）
- [ ] T065 [US3] 创建 Android 端任务管理服务 android/app/src/main/java/com/worktimer/domain/TaskService.kt（创建、编辑、删除任务逻辑，默认任务不可删除检查）
- [ ] T066 [US3] 创建 Windows 端工作记录管理服务 windows/src/services/record_service.py（编辑、转移工作记录逻辑）
- [ ] T067 [US3] 创建 Android 端工作记录管理服务 android/app/src/main/java/com/worktimer/domain/RecordService.kt（编辑、转移工作记录逻辑）
- [ ] T068 [US3] 创建 Windows 端工作记录管理页面 UI windows/src/ui/record_management_page.py（任务列表、新建任务、编辑任务、删除任务、工作记录列表、编辑记录、转移记录）
- [ ] T069 [US3] 创建 Android 端工作记录管理页面 UI android/app/src/main/java/com/worktimer/ui/management/RecordManagementScreen.kt（任务列表、新建任务、编辑任务、删除任务、工作记录列表、编辑记录、转移记录）
- [ ] T070 [US3] 实现 Windows 端新建任务功能 windows/src/services/task_service.py（创建新任务，名称唯一性检查，长度 ≤ 50 字符）
- [ ] T071 [US3] 实现 Android 端新建任务功能 android/app/src/main/java/com/worktimer/domain/TaskService.kt（创建新任务，名称唯一性检查，长度 ≤ 50 字符）
- [ ] T072 [US3] 实现 Windows 端编辑任务功能 windows/src/services/task_service.py（更新任务信息，已记录的时间数据保持不变）
- [ ] T073 [US3] 实现 Android 端编辑任务功能 android/app/src/main/java/com/worktimer/domain/TaskService.kt（更新任务信息，已记录的时间数据保持不变）
- [ ] T074 [US3] 实现 Windows 端删除任务功能 windows/src/services/task_service.py（检查是否可删除，默认任务阻止删除，有关联记录时禁止删除或提示转移）
- [ ] T075 [US3] 实现 Android 端删除任务功能 android/app/src/main/java/com/worktimer/domain/TaskService.kt（检查是否可删除，默认任务阻止删除，有关联记录时禁止删除或提示转移）
- [ ] T076 [US3] 实现 Windows 端编辑工作记录功能 windows/src/services/record_service.py（更新工作记录的 start_time、end_time、duration、关联任务）
- [ ] T077 [US3] 实现 Android 端编辑工作记录功能 android/app/src/main/java/com/worktimer/domain/RecordService.kt（更新工作记录的 start_time、end_time、duration、关联任务）
- [ ] T078 [US3] 实现 Windows 端转移工作记录功能 windows/src/services/record_service.py（将工作记录关联到新任务，统计数据相应更新）
- [ ] T079 [US3] 实现 Android 端转移工作记录功能 android/app/src/main/java/com/worktimer/domain/RecordService.kt（将工作记录关联到新任务，统计数据相应更新）
- [ ] T080 [US3] 集成 Windows 端主页与工作记录管理页面 windows/src/ui/main_window.py（从主页点击工作记录管理入口跳转到管理页面）
- [ ] T081 [US3] 集成 Android 端主页与工作记录管理页面 android/app/src/main/java/com/worktimer/ui/MainActivity.kt（从主页点击工作记录管理入口跳转到管理页面）

检查点：用户故事 3 可独立完整运行并可测试——创建新任务 → 编辑任务信息 → 编辑工作记录 → 尝试删除默认任务

---

## 阶段 6：Polish 与横切关注点

**目的**：影响多个用户故事的改进

- [ ] T082 [P] 更新 Windows 端文档 windows/README.md（环境要求、安装步骤、使用说明）
- [ ] T083 [P] 更新 Android 端文档 android/README.md（环境要求、安装步骤、使用说明）
- [ ] T084 [P] 代码清理与重构（Windows 端）：统一错误处理、日志格式
- [ ] T085 [P] 代码清理与重构（Android 端）：统一错误处理、日志格式
- [ ] T086 [P] Windows 端全局性能优化（确保 1 万条记录规模下统计查询 ≤ 3 秒）
- [ ] T087 [P] Android 端全局性能优化（确保 1 万条记录规模下统计查询 ≤ 3 秒）
- [ ] T088 [P] Windows 端界面响应优化（确保界面切换 ≤ 1 秒，悬浮按钮切换 ≤ 2 秒）
- [ ] T089 [P] Android 端界面响应优化（确保界面切换 ≤ 1 秒，悬浮按钮切换 ≤ 2 秒）
- [ ] T090 Windows 端安全加固（存储路径权限检查、数据加密选项）
- [ ] T091 Android 端安全加固（存储路径权限检查、数据加密选项）
- [ ] T092 运行 quickstart.md 校验（Windows 端）：验证环境搭建与核心功能实现
- [ ] T093 运行 quickstart.md 校验（Android 端）：验证环境搭建与核心功能实现
- [ ] T094 Windows 端边界情况处理（存储路径不可写、应用关闭时未结束记录、大量数据查询）
- [ ] T095 Android 端边界情况处理（存储路径不可写、应用关闭时未结束记录、大量数据查询）
- [ ] T096 Windows 端数据恢复测试（模拟断电、数据损坏场景，验证恢复率 ≥ 95%）
- [ ] T097 Android 端数据恢复测试（模拟断电、数据损坏场景，验证恢复率 ≥ 95%）
- [ ] T098 Windows 端自动修复测试（验证修复成功率 ≥ 90%，修复过程 ≤ 5 秒）
- [ ] T099 Android 端自动修复测试（验证修复成功率 ≥ 90%，修复过程 ≤ 5 秒）
- [ ] T100 Windows 端错误率测试（验证正常使用场景下错误率 ≤ 0.1%）
- [ ] T101 Android 端错误率测试（验证正常使用场景下错误率 ≤ 0.1%）

---

## 依赖与执行顺序

### 阶段依赖

- Setup（阶段 1）：无依赖，可立即开始
- Foundational（阶段 2）：依赖 Setup，阻塞全部用户故事
- 用户故事（阶段 3+）：依赖 Foundational 完成
  - 有人力时可并行推进；或按优先级顺序串行（US1 → US2 → US3）
- Polish（最终阶段）：依赖所需故事完成

### 用户故事依赖

- 用户故事 1（P1）：Foundational 完成后开始；不依赖其他故事
- 用户故事 2（P1）：Foundational 完成后开始；可与 US1 并行（不同文件、无依赖）
- 用户故事 3（P2）：Foundational 完成后开始；可与 US1/US2 并行，但建议在 US1/US2 完成后开始（需要任务管理功能完整）

### 每个用户故事内的顺序

- 模型已在 Foundational 阶段创建（Task、WorkRecord）
- 服务 → UI → 集成
- 当前故事完成后再进入下一个（或并行）

### 并行机会

- 所有标记 [P] 的 Setup/Foundational 任务可并行
- Foundational 完成后，US1 和 US2 可并行（不同文件、无依赖）
- US1 和 US2 完成后，US3 可开始（但建议串行以确保功能完整）
- 故事内标记 [P] 的模型可并行（已在 Foundational 阶段完成）
- Windows 端和 Android 端可并行开发（不同目录、无依赖）

---

## 实施策略

### 先做 MVP（用户故事 1 和 2）

1) 完成阶段 1：Setup  
2) 完成阶段 2：Foundational（关键）  
3) 完成阶段 3：用户故事 1（时间统计）  
4) 完成阶段 4：用户故事 2（工作模式）  
5) 停止并验证：独立测试故事 1 和 2  
6) 若就绪则部署/演示

### 增量交付

1) 完成 Setup + Foundational → 基础就绪  
2) 加入用户故事 1 → 独立测试 → 部署/演示（MVP 第一步）  
3) 加入用户故事 2 → 独立测试 → 部署/演示（MVP 第二步）  
4) 加入用户故事 3 → 独立测试 → 部署/演示（完整功能）  
5) 确保新增不破坏既有功能

### 并行团队策略

多人协作：

1) 团队共同完成 Setup + Foundational  
2) 基础完成后：
   - A 负责 Windows 端 US1
   - B 负责 Android 端 US1
   - C 负责 Windows 端 US2
   - D 负责 Android 端 US2
3) US1 和 US2 完成后，E 负责 US3（Windows 和 Android 端）
4) 各故事独立完成并集成

---

## 任务统计

- **总任务数**：101 个任务
- **Setup 阶段**：7 个任务（T001-T007）
- **Foundational 阶段**：16 个任务（T008-T023）
- **用户故事 1**：16 个任务（T024-T039）
- **用户故事 2**：24 个任务（T040-T063）
- **用户故事 3**：18 个任务（T064-T081）
- **Polish 阶段**：20 个任务（T082-T101）

### 并行机会

- **Setup 阶段**：T003-T007 可并行（5 个任务）
- **Foundational 阶段**：T010-T013、T016-T017 可并行（6 个任务）
- **用户故事阶段**：US1 和 US2 可并行（Windows 端和 Android 端可分别并行）
- **Polish 阶段**：T082-T095 可并行（14 个任务）

### 独立测试标准

- **用户故事 1**：启动应用 → 进入统计页面 → 切换天/周/月视图 → 查看数据展示
- **用户故事 2**：选择任务 → 开始工作 → 切换任务 → 结束工作 → 查看记录
- **用户故事 3**：创建新任务 → 编辑任务信息 → 编辑工作记录 → 尝试删除默认任务

### 建议的 MVP 范围

**MVP 第一阶段**：Setup + Foundational + 用户故事 1（时间统计）
- 任务数：7 + 16 + 16 = 39 个任务
- 交付价值：用户可以启动应用并查看时间统计

**MVP 第二阶段**：MVP 第一阶段 + 用户故事 2（工作模式）
- 任务数：39 + 24 = 63 个任务
- 交付价值：用户可以记录时间并查看统计

**完整功能**：MVP 第二阶段 + 用户故事 3（任务管理）
- 任务数：63 + 18 = 81 个任务
- 交付价值：用户可以完整管理工作记录和任务

### 格式校验

✅ 所有任务都符合清单格式：
- 复选框：`- [ ]`
- 任务 ID：T001-T101
- [P] 标记：仅当可并行时加入
- [Story] 标签：仅在用户故事阶段使用（US1、US2、US3）
- 文件路径：所有任务都包含明确的文件路径

---

## 备注

- [P] 任务：不同文件、无依赖  
- [Story] 标签：用于可追溯性映射到用户故事  
- 每个用户故事应可独立完成与测试  
- 每个任务/逻辑组后提交  
- 可在任一检查点暂停并独立验证  
- Windows 端和 Android 端可并行开发（不同目录、无依赖）
- 避免：模糊任务、同文件冲突、破坏故事独立性的跨故事依赖

