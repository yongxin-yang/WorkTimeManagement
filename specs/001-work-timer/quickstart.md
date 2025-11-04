# 快速开始指南：多功能计时软件

**日期**：2025-01-27  
**特性**：001-work-timer

## 概述

本指南提供快速开始开发多功能计时软件的步骤，涵盖 Windows 和 Android 双平台的环境搭建、项目结构、核心功能实现要点。

## 环境要求

### Windows 端

- Python 3.11 或更高版本
- pip 包管理器
- Git（可选，用于版本控制）

### Android 端

- Android Studio Hedgehog | 2023.1.1 或更高版本
- JDK 17 或更高版本
- Android SDK API 21+（最低支持 Android 5.0）
- Gradle 8.0+

## 项目结构

```
WorkManageCursor/
├── windows/              # Windows 端代码
│   ├── src/
│   │   ├── models/
│   │   ├── services/
│   │   ├── ui/
│   │   └── utils/
│   └── tests/
├── android/              # Android 端代码
│   └── app/
│       └── src/main/java/com/worktimer/
└── shared/               # 共享数据契约
    └── contracts/
```

## 快速开始步骤

### Windows 端

#### 1. 创建虚拟环境

```bash
cd windows
python -m venv venv
venv\Scripts\activate  # Windows
```

#### 2. 安装依赖

```bash
pip install PySide6
pip install sqlmodel
pip install pytest  # 测试框架
```

#### 3. 初始化数据库

创建 `src/models/task.py`：

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
    
    work_records: List["WorkRecord"] = Relationship(back_populates="task")
```

创建 `src/models/work_record.py`：

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
    start_time: int
    end_time: Optional[int] = None
    duration: Optional[int] = None
    status: RecordStatus = Field(default=RecordStatus.IN_PROGRESS)
    created_at: int = Field(default_factory=lambda: int(datetime.now().timestamp()))
    updated_at: int = Field(default_factory=lambda: int(datetime.now().timestamp()))
    
    task: Optional["Task"] = Relationship(back_populates="work_records")
```

创建 `src/utils/db.py`：

```python
from sqlmodel import create_engine, SQLModel, Session, select
from pathlib import Path
from datetime import datetime
from src.models.task import Task
from src.models.work_record import WorkRecord

def init_database(db_path: Path):
    engine = create_engine(f"sqlite:///{db_path}", echo=False)
    SQLModel.metadata.create_all(engine)
    
    # 创建默认任务
    with Session(engine) as session:
        now = int(datetime.now().timestamp())
        
        # 检查并创建默认任务
        if not session.exec(select(Task).where(Task.name == "工作")).first():
            task_work = Task(name="工作", created_at=now, is_default=True, is_deletable=False)
            session.add(task_work)
        
        if not session.exec(select(Task).where(Task.name == "摸鱼")).first():
            task_rest = Task(name="摸鱼", created_at=now, is_default=True, is_deletable=False)
            session.add(task_rest)
        
        session.commit()
```

#### 4. 创建主窗口

创建 `src/ui/main_window.py`：

```python
from PySide6.QtWidgets import QMainWindow, QWidget, QVBoxLayout, QPushButton

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("多功能计时软件")
        self.setGeometry(100, 100, 800, 600)
        
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        layout = QVBoxLayout()
        central_widget.setLayout(layout)
        
        # 主页入口
        btn_statistics = QPushButton("时间分配统计")
        btn_work_mode = QPushButton("工作模式")
        btn_management = QPushButton("工作记录管理")
        
        layout.addWidget(btn_statistics)
        layout.addWidget(btn_work_mode)
        layout.addWidget(btn_management)
```

#### 5. 运行应用

```bash
python src/main.py
```

### Android 端

#### 1. 创建 Android 项目

在 Android Studio 中创建新项目：
- 模板：Empty Activity
- 包名：com.worktimer
- 最低 SDK：API 21（Android 5.0）
- 语言：Kotlin

#### 2. 添加依赖

在 `app/build.gradle.kts` 中添加：

```kotlin
dependencies {
    // Room
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    kapt("androidx.room:room-compiler:2.6.1")
    
    // Compose
    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    
    // Lifecycle
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
}
```

#### 3. 创建数据库

创建 `app/src/main/java/com/worktimer/data/AppDatabase.kt`：

```kotlin
@Database(
    entities = [Task::class, WorkRecord::class],
    version = 1,
    exportSchema = true
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun taskDao(): TaskDao
    abstract fun workRecordDao(): WorkRecordDao
    
    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null
        
        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "work_timer.db"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}
```

#### 4. 创建主界面

创建 `app/src/main/java/com/worktimer/ui/home/HomeScreen.kt`：

```kotlin
@Composable
fun HomeScreen(
    onNavigateToStatistics: () -> Unit,
    onNavigateToWorkMode: () -> Unit,
    onNavigateToManagement: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Button(onClick = onNavigateToStatistics) {
            Text("时间分配统计")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Button(onClick = onNavigateToWorkMode) {
            Text("工作模式")
        }
        Spacer(modifier = Modifier.height(16.dp))
        Button(onClick = onNavigateToManagement) {
            Text("工作记录管理")
        }
    }
}
```

## 核心功能实现要点

### 1. 存储完整性检查

**Windows 端**：

```python
from sqlmodel import Session, select, text
from sqlmodel import create_engine
from src.models.work_record import WorkRecord, RecordStatus

def check_database_integrity(engine):
    with Session(engine) as session:
        # 检查未完成记录
        incomplete_records = session.exec(
            select(WorkRecord).where(WorkRecord.status == RecordStatus.IN_PROGRESS)
        ).all()
        
        # 检查外键完整性（使用 SQLAlchemy 引擎执行 PRAGMA）
        foreign_key_result = session.exec(text("PRAGMA foreign_key_check"))
        foreign_key_errors = foreign_key_result.all()
        
        # 检查数据库完整性
        integrity_result = session.exec(text("PRAGMA integrity_check")).first()
        
        return incomplete_records, foreign_key_errors, integrity_result
```

**Android 端**：

```kotlin
suspend fun checkDatabaseIntegrity(): IntegrityResult {
    val incompleteRecords = workRecordDao.getIncompleteRecords()
    val foreignKeyErrors = database.query("PRAGMA foreign_key_check")
    val integrityCheck = database.query("PRAGMA integrity_check")
    
    return IntegrityResult(incompleteRecords, foreignKeyErrors, integrityCheck)
}
```

### 2. 定期保存机制

**Windows 端**：

```python
from PySide6.QtCore import QTimer

class WorkModeService:
    def __init__(self):
        self.timer = QTimer()
        self.timer.timeout.connect(self.auto_save)
        self.timer.start(60000)  # 60 秒
    
    def auto_save(self):
        # 保存当前工作状态
        pass
```

**Android 端**：

```kotlin
class WorkModeViewModel : ViewModel() {
    private val saveJob = viewModelScope.launch {
        while (true) {
            delay(60000) // 60 秒
            autoSave()
        }
    }
    
    private suspend fun autoSave() {
        // 保存当前工作状态
    }
}
```

### 3. 悬浮按钮实现

**Windows 端**（系统托盘）：

```python
from PySide6.QtWidgets import QSystemTrayIcon, QMenu
from PySide6.QtGui import QIcon

tray_icon = QSystemTrayIcon()
tray_icon.setIcon(QIcon("icon.png"))
menu = QMenu()
switch_action = menu.addAction("切换任务")
tray_icon.setContextMenu(menu)
tray_icon.show()
```

**Android 端**（通知栏）：

```kotlin
val notification = NotificationCompat.Builder(context, CHANNEL_ID)
    .setContentTitle("工作模式")
    .setContentText("当前任务：工作")
    .setSmallIcon(R.drawable.ic_work)
    .addAction(R.drawable.ic_switch, "切换任务", switchPendingIntent)
    .setOngoing(true)
    .build()
```

## 测试

### Windows 端

```bash
pytest tests/
```

### Android 端

在 Android Studio 中运行单元测试或 UI 测试。

## 下一步

1. 实现数据模型层（Task、WorkRecord）
2. 实现业务逻辑层（时间统计、存储管理）
3. 实现 UI 层（主页、统计页面、工作模式页面）
4. 实现存储完整性检查与修复
5. 实现悬浮按钮/通知栏快速切换
6. 编写测试用例

## 参考文档

- [数据模型文档](./data-model.md)
- [技术调研文档](./research.md)
- [数据契约](./contracts/)

