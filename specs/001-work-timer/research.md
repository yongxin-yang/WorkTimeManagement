# 技术调研：多功能计时软件

**日期**：2025-01-27  
**特性**：001-work-timer

## 调研目标

确定 Windows 和 Android 双平台的技术选型、数据存储方案、存储完整性检查与修复机制，确保两端功能等价、数据口径一致。

## 技术决策

### 决策 1：Windows 端 GUI 框架选择

**决策**：使用 PySide6（Qt for Python）

**理由**：
- 符合宪章要求（Windows 端使用 PySide6）
- 跨平台能力（Qt 框架成熟稳定）
- Python 生态系统支持良好
- 支持创建悬浮窗口（系统托盘/悬浮按钮）
- 性能满足桌面应用需求

**备选方案**：
- Tkinter：功能有限，不支持现代 UI
- wxPython：API 较复杂，社区活跃度较低
- Electron + Python：资源占用大，不符合简单性原则

### 决策 2：Android 端 UI 框架选择

**决策**：使用 Jetpack Compose

**理由**：
- 符合宪章要求（Android 端使用 Jetpack Compose）
- 现代声明式 UI 框架，开发效率高
- 与 Material Design 3 集成良好
- Kotlin 官方推荐
- 支持状态管理（State、ViewModel）

**备选方案**：
- XML + ViewBinding：传统方式，代码量大
- Flutter：跨平台但不符合项目架构（独立 Android 端）

### 决策 3：数据存储方案

**决策**：统一使用 SQLite，Windows 端使用 SQLModel，Android 端使用 Room

**理由**：
- 符合宪章要求（本地优先、SQLite）
- SQLite 轻量级、无服务器、本地文件存储
- 支持事务、索引、查询优化
- SQLModel 提供类型安全、简洁易懂的 ORM（基于 Pydantic + SQLAlchemy）
- Room 提供类型安全、编译时检查
- 两端数据模型可统一（表结构一致）
- 支持数据完整性检查（外键、约束）

**Windows 端 SQLModel 优势**：
- 基于 Pydantic，提供类型验证和自动补全
- 代码简洁，无需手写 SQL
- 与 FastAPI 生态兼容（未来可扩展）
- 支持关系映射和查询构建

**备选方案**：
- 直接使用 sqlite3：代码冗长，需要手写 SQL，类型安全不足
- JSON 文件：查询性能差，不支持复杂查询
- CSV 文件：无事务支持，数据完整性难以保证
- Realm：依赖较大，不符合最小依赖原则

### 决策 4：存储完整性检查与修复机制

**决策**：启动时自动检查 + 定期保存（60 秒） + 事务日志

**理由**：
- 启动检查：检测未完成记录、损坏文件、数据不一致
- 定期保存：减少异常关闭时的数据损失（FR-023 要求每 60 秒）
- 事务日志：SQLite WAL 模式提供原子性，支持回滚
- 修复策略：自动恢复未完成记录（基于最后保存时间），重建索引，验证外键约束

**实现要点**：
- Windows：使用 SQLModel 的 SQLAlchemy 引擎执行 integrity_check、PRAGMA foreign_key_check
- Android：使用 Room 的 @Database(exportSchema = true)，运行时检查完整性
- 备份机制：修复前自动备份数据库文件（.backup 后缀）

**备选方案**：
- 仅启动检查：无法应对运行中异常
- 实时保存：性能开销大，不符合定期保存策略

### 决策 5：悬浮按钮实现方案

**决策**：
- Windows：使用 PySide6 的 QSystemTrayIcon + 独立无边框窗口
- Android：使用 Notification + 快速设置磁贴（Quick Settings Tile）

**理由**：
- Windows QSystemTrayIcon：系统托盘图标，点击显示悬浮窗口，支持全局快捷键
- Android Notification：常驻通知栏，快速操作，符合 Android 设计规范
- 两端功能等价：都提供快速切换任务的能力

**实现要点**：
- Windows：悬浮窗口设置 `setWindowFlags(Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint)`
- Android：使用 NotificationCompat.Builder 创建常驻通知，添加快速操作按钮

**备选方案**：
- Windows 全屏覆盖层：用户体验差，不符合桌面应用习惯
- Android 悬浮窗（Overlay）：需要特殊权限，可能被系统限制

### 决策 6：数据同步与一致性

**决策**：共享数据契约（JSON Schema），两端独立实现，不实时同步

**理由**：
- 符合宪章要求（本地优先、核心不依赖网络）
- JSON Schema 定义统一的数据结构
- 两端独立实现，避免网络依赖
- 未来可通过导入/导出实现数据交换

**实现要点**：
- 定义 shared/contracts/ 目录存放 JSON Schema
- 任务、工作记录、统计的数据格式统一
- 版本字段支持向后兼容（FR-022 要求）

**备选方案**：
- 实时同步：需要服务器，不符合本地优先原则
- 完全独立：无法保证数据一致性（已通过契约解决）

### 决策 7：时间统计查询性能优化

**决策**：使用 SQLite 索引 + 聚合查询 + 缓存

**理由**：
- 成功标准要求：1 万条记录查询 ≤ 3 秒（SC-004）
- SQLite 索引：在 task_id、start_time 字段建立索引
- 聚合查询：使用 SQL GROUP BY、SUM 在数据库层完成聚合
- 缓存：统计结果缓存 5 分钟，减少重复计算

**实现要点**：
- 索引：`CREATE INDEX idx_work_record_task_time ON work_record(task_id, start_time)`
- 聚合：`SELECT task_id, SUM(duration) FROM work_record WHERE ... GROUP BY task_id`
- 缓存：使用内存字典缓存（Windows）或 Room 的 @Query 缓存（Android）

**备选方案**：
- 内存全量加载：内存占用大，不符合轻量级要求
- 实时计算：每次查询都计算，性能不满足要求

## 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| SQLite 数据损坏 | 高 | 启动时完整性检查 + 自动修复 + 备份机制 |
| 悬浮按钮权限问题（Android） | 中 | 使用 Notification 替代悬浮窗，符合系统规范 |
| 跨平台数据格式不一致 | 高 | 使用 JSON Schema 定义统一契约 |
| 性能不满足 1 万条记录要求 | 中 | 使用索引 + 聚合查询 + 缓存优化 |

## 待验证项

- [ ] PySide6 悬浮窗口在 Windows 11 上的兼容性
- [ ] Room 数据库在 Android 低版本（API 21+）的兼容性
- [ ] SQLite 完整性检查的耗时（需满足 SC-008：修复过程 ≤ 5 秒）
- [ ] 1 万条记录的实际查询性能测试

## 参考资料

- PySide6 官方文档：https://doc.qt.io/qtforpython/
- Jetpack Compose 官方文档：https://developer.android.com/jetpack/compose
- Room 持久化库：https://developer.android.com/training/data-storage/room
- SQLite 完整性检查：https://www.sqlite.org/pragma.html#pragma_integrity_check

