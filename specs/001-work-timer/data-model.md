# 数据模型：多功能计时软件

**日期**：2025-01-27  
**特性**：001-work-timer

## 概述

本数据模型定义任务、工作记录、时间统计三个核心实体，支持 Windows 和 Android 双平台统一数据契约。使用 SQLite 作为存储引擎，Windows 端使用 SQLModel，Android 端使用 Room。

## 实体定义

### 1. 任务（Task）

**描述**：代表一个可记录时间的类别，用户可创建、编辑、删除（默认任务除外）。

**属性**：
- `id`：整数，主键，自增
- `name`：字符串，任务名称，非空，唯一
- `created_at`：时间戳，创建时间，非空
- `is_default`：布尔值，是否为默认任务（"工作"和"摸鱼"），非空，默认 false
- `is_deletable`：布尔值，是否可删除（默认任务不可删除），非空，默认 true

**约束**：
- 名称唯一性（UNIQUE constraint）
- 默认任务名称固定为"工作"和"摸鱼"
- 默认任务的 `is_default = true`，`is_deletable = false`

**状态**：无状态转移（创建后即存在，删除后物理删除）

**索引**：
- `idx_task_name`：name 字段（用于快速查找）

### 2. 工作记录（WorkRecord）

**描述**：代表一段时间的记录，包含开始时间、结束时间、关联任务、持续时间、状态等属性。

**属性**：
- `id`：整数，主键，自增
- `task_id`：整数，外键，关联任务表，非空
- `session_id`：整数，工作周期 ID（用于甘特图展示，标识属于同一工作周期的记录），非空
- `start_time`：时间戳，开始时间，非空
- `end_time`：时间戳，结束时间，可为空（进行中的记录）
- `duration`：整数，持续时间（秒），可为空（进行中的记录）
- `status`：枚举，状态（进行中/已完成/已中断），非空，默认"进行中"
- `created_at`：时间戳，创建时间，非空
- `updated_at`：时间戳，更新时间，非空

**状态转移**：
- 进行中 → 已完成：用户点击"结束"按钮
- 进行中 → 已中断：系统异常关闭或断电
- 已中断 → 已完成：用户手动修复或系统自动修复

**约束**：
- 外键约束：`task_id` 必须存在于任务表
- 时间约束：`end_time >= start_time`（如果 end_time 不为空）
- 持续时间约束：`duration = end_time - start_time`（如果两者都不为空）
- 状态约束：`status = '进行中'` 时，`end_time` 和 `duration` 必须为空

**索引**：
- `idx_work_record_task_time`：task_id, start_time（用于统计查询）
- `idx_work_record_status`：status（用于查找未完成记录）
- `idx_work_record_session`：session_id, start_time（用于工作周期查询和甘特图展示）

### 3. 时间统计（TimeStatistics）

**描述**：按天、周、月维度聚合的工作记录，展示各任务的时间占比和总计。此为视图/查询结果，不持久化存储。

**属性**（查询结果）：
- `task_id`：整数，任务 ID
- `task_name`：字符串，任务名称
- `date`：日期，统计日期（天维度）
- `week_start`：日期，周开始日期（周维度）
- `month`：字符串，月份（YYYY-MM 格式，月维度）
- `total_duration`：整数，总持续时间（秒）
- `percentage`：浮点数，时间占比（0-100）

**聚合规则**：
- 天维度：按日期 + 任务聚合，`SUM(duration) WHERE DATE(start_time) = date`
- 周维度：按周开始日期 + 任务聚合，`SUM(duration) WHERE WEEK(start_time) = week_start`
- 月维度：按月份 + 任务聚合，`SUM(duration) WHERE YEAR(start_time) = year AND MONTH(start_time) = month`
- 占比计算：`percentage = (task_duration / total_duration) * 100`

**数据来源**：基于工作记录明细聚合，可重算（符合宪章要求）

### 4. 工作周期视图（WorkSessionView）

**描述**：用于甘特图展示的单个工作周期视图，展示一个完整工作周期内多个工作的执行和切换。此为视图/查询结果，不持久化存储。

**属性**（查询结果）：
- `session_id`：整数，工作周期 ID（基于开始时间生成的唯一标识）
- `session_start`：时间戳，工作周期开始时间（第一个工作记录的 start_time）
- `session_end`：时间戳，工作周期结束时间（最后一个工作记录的 end_time）
- `work_records`：数组，该周期内的所有工作记录（按时间顺序）
  - `record_id`：整数，工作记录 ID
  - `task_id`：整数，任务 ID
  - `task_name`：字符串，任务名称
  - `start_time`：时间戳，开始时间
  - `end_time`：时间戳，结束时间
  - `duration`：整数，持续时间（秒）

**聚合规则**：
- 工作周期识别：从用户点击"开始"到用户点击"结束"之间的所有工作记录属于一个工作周期，通过 `session_id` 字段关联
- 工作记录按 `start_time` 排序
- 甘特图展示：以时间轴为横轴，任务为纵轴，展示每个工作记录的时间段
- 查询方式：`SELECT * FROM work_records WHERE session_id = ? ORDER BY start_time ASC`

**数据来源**：基于工作记录明细聚合，可重算（符合宪章要求）

## 数据库架构

### SQLModel 实体（Windows）

#### Task 实体

```python
from sqlmodel import SQLModel, Field, Relationship
from typing import Optional, List
from datetime import datetime

class Task(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(unique=True, index=True)
    created_at: int = Field(default_factory=lambda: int(datetime.now().timestamp()))
    is_default: bool = Field(default=False)
    is_deletable: bool = Field(default=True)
    
    # 关系
    work_records: List["WorkRecord"] = Relationship(back_populates="task")
```

#### WorkRecord 实体

```python
from sqlmodel import SQLModel, Field, Relationship
from typing import Optional
from datetime import datetime
from enum import Enum

class RecordStatus(str, Enum):
    IN_PROGRESS = "进行中"
    COMPLETED = "已完成"
    INTERRUPTED = "已中断"

class WorkRecord(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    task_id: int = Field(foreign_key="task.id")
    session_id: int = Field(index=True)  # 工作周期 ID，用于甘特图展示
    start_time: int
    end_time: Optional[int] = None
    duration: Optional[int] = None
    status: RecordStatus = Field(default=RecordStatus.IN_PROGRESS)
    created_at: int = Field(default_factory=lambda: int(datetime.now().timestamp()))
    updated_at: int = Field(default_factory=lambda: int(datetime.now().timestamp()))
    
    # 关系
    task: Optional[Task] = Relationship(back_populates="work_records")
```

#### 数据库初始化

```python
from sqlmodel import create_engine, SQLModel, Session, select
from pathlib import Path

def init_database(db_path: Path):
    engine = create_engine(f"sqlite:///{db_path}", echo=False)
    SQLModel.metadata.create_all(engine)
    
    # 创建默认任务
    with Session(engine) as session:
        from datetime import datetime
        now = int(datetime.now().timestamp())
        
        # 检查并创建默认任务
        from sqlmodel import select
        if not session.exec(select(Task).where(Task.name == "工作")).first():
            task_work = Task(name="工作", created_at=now, is_default=True, is_deletable=False)
            session.add(task_work)
        
        if not session.exec(select(Task).where(Task.name == "摸鱼")).first():
            task_rest = Task(name="摸鱼", created_at=now, is_default=True, is_deletable=False)
            session.add(task_rest)
        
        session.commit()
```

### Room 实体（Android）

#### Task 实体

```kotlin
@Entity(tableName = "tasks")
data class Task(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    @ColumnInfo(name = "name")
    val name: String,
    @ColumnInfo(name = "created_at")
    val createdAt: Long,
    @ColumnInfo(name = "is_default")
    val isDefault: Boolean = false,
    @ColumnInfo(name = "is_deletable")
    val isDeletable: Boolean = true
)
```

#### WorkRecord 实体

```kotlin
@Entity(
    tableName = "work_records",
    foreignKeys = [
        ForeignKey(
            entity = Task::class,
            parentColumns = ["id"],
            childColumns = ["task_id"],
            onDelete = ForeignKey.RESTRICT
        )
    ],
    indices = [
        Index(value = ["task_id", "start_time"]),
        Index(value = ["status"]),
        Index(value = ["session_id", "start_time"])  // 用于工作周期查询和甘特图展示
    ]
)
data class WorkRecord(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    @ColumnInfo(name = "task_id")
    val taskId: Long,
    @ColumnInfo(name = "session_id")
    val sessionId: Long,  // 工作周期 ID，用于甘特图展示
    @ColumnInfo(name = "start_time")
    val startTime: Long,
    @ColumnInfo(name = "end_time")
    val endTime: Long? = null,
    @ColumnInfo(name = "duration")
    val duration: Long? = null,
    @ColumnInfo(name = "status")
    val status: RecordStatus = RecordStatus.IN_PROGRESS,
    @ColumnInfo(name = "created_at")
    val createdAt: Long,
    @ColumnInfo(name = "updated_at")
    val updatedAt: Long
)

enum class RecordStatus {
    IN_PROGRESS,    // 进行中
    COMPLETED,      // 已完成
    INTERRUPTED     // 已中断
}
```

## 数据校验规则

### 任务校验
- 名称不能为空
- 名称长度限制：英文字符不超过50个，中文字符不超过20个
- 默认任务名称必须为"工作"或"摸鱼"
- 删除任务时，检查是否有关联的工作记录（如有则禁止删除，除非转移记录）

### 工作记录校验
- 开始时间必须 ≤ 当前时间
- 结束时间必须 ≥ 开始时间
- 状态为"已完成"时，结束时间和持续时间必须非空
- 状态为"进行中"时，结束时间和持续时间必须为空
- 任务切换时，自动结束当前记录并创建新记录

## 数据完整性检查

### 启动时检查项

1. **未完成记录检查**：查找 `status = '进行中'` 的记录
   - 修复策略：自动结束记录（以最后保存时间为 end_time），状态改为"已中断"，然后尝试恢复为"已完成"

2. **外键完整性检查**：使用 SQLModel 的 SQLAlchemy 引擎执行 `PRAGMA foreign_key_check`
   - 修复策略：标记孤立记录，提示用户修复

3. **数据一致性检查**：验证 `duration = end_time - start_time`
   - 修复策略：自动修复不一致的持续时间

4. **索引完整性检查**：使用 SQLModel 的 SQLAlchemy 引擎执行 `PRAGMA integrity_check`
   - 修复策略：重建索引，如失败则提示用户

### 修复流程

1. 启动时自动执行检查
2. 发现问题时，先备份数据库（`.backup` 后缀）
3. 尝试自动修复（FR-021）
4. 修复成功：继续启动
5. 修复失败：提示用户并保留备份（FR-022）

## 数据迁移

### 版本管理

- 数据库版本号：存储在数据库元数据中
- 迁移脚本：支持版本升级时的数据迁移

### 初始数据

- 创建默认任务："工作"（id=1）和"摸鱼"（id=2）
- 设置 `is_default = true`，`is_deletable = false`

## 性能优化

### 查询优化

- 统计查询使用聚合函数（SUM、COUNT）在数据库层完成
- 使用索引加速查询（task_id + start_time 组合索引）
- 缓存统计结果 5 分钟

### 写入优化

- 定期保存（每 60 秒）使用事务批量写入
- 使用 WAL 模式提高并发性能
- 避免频繁的数据库连接/断开

## 数据导出/导入

### 导出格式

- JSON 格式：包含任务和工作记录的完整数据
- CSV 格式：工作记录的时间序列数据

### 导入格式

- 支持 JSON 导入（任务 + 工作记录）
- 支持 CSV 导入（工作记录的时间序列数据）
- 版本字段：支持向后兼容（数据契约版本号）

