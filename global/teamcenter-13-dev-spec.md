# Teamcenter 13 开发规范

## 版本信息
- **Teamcenter Version**: 13.x (13.0, 13.1, 13.2, 13.3)
- **Active Workspace**: 5.x
- **文档版本**: 2021-2022 Release

## 开发类型总览

Teamcenter 13 二次开发分为四大技术栈：

| 开发类型 | 技术语言 | 适用场景 | 部署位置 |
|---------|---------|---------|---------|
| **SOA 服务开发** | Java / C++ | 远程调用、跨防火墙、Web应用 | 服务器端 |
| **ITK 客户端开发** | C/C++ | 高性能本地操作、复杂业务逻辑 | 客户端/服务器 |
| **Handler 开发** | C/C++ | 工作流规则、操作前/后处理 | 服务器端 |
| **BMIDE 业务建模** | XML/Schema | 数据模型扩展、业务规则 | 服务器配置 |

## 核心架构

### SOA 架构 (Service-Oriented Architecture)
```
Client Application
       ↓
   HTTP/HTTPS (SOAP/REST)
       ↓
Teamcenter SOA Framework
       ↓
   Service Operations
       ↓
Teamcenter Business Logic
```

### ITK 架构 (Integration Toolkit)
```
Custom Application
       ↓
   ITK API Calls
       ↓
Teamcenter Kernel
       ↓
Database / File System
```

## 关键概念

### 核心对象类型
| 对象类型 | 说明 | 常用场景 |
|---------|------|---------|
| `Item` | 零组件（零件、文档等） | 创建、查询、修改零组件 |
| `ItemRevision` | 零组件版本 | 版本管理、状态控制 |
| `Dataset` | 数据集（文件容器） | 文件管理、可视化 |
| `Folder` | 文件夹 | 组织数据、分类存储 |
| `BOMLine` | BOM 行 | 产品结构管理 |
| `ImanFile` | 物理文件 | 文件上传下载 |
| `WorkspaceObject` | 所有业务对象的基类 | 通用操作 |

### 关键 Tag 类型
```c
// Teamcenter 13 核心 Tag 定义
tag_t item_tag;           // Item 对象标签
tag_t itemrev_tag;        // ItemRevision 对象标签
tag_t dataset_tag;        // Dataset 对象标签
tag_t bomwindow_tag;      // BOM 窗口标签
tag_t bomline_tag;        // BOM 行标签
tag_t relation_tag;       // 关系标签
```

## Teamcenter 13 新特性（开发相关）

### 13.0 新特性
- **Teamcenter Assistant**: AI 辅助功能
- **Mendix Connector**: 低代码应用开发 OData API
- **Partner Connect**: 供应商协作 API
- **Smart Discovery**: 增强的搜索过滤 API

### 13.1 新特性
- **Requirements Quality Checker**: 需求质量检查 API
- **Carbon Footprint Calculator**: 碳足迹计算（Product Cost Management）

### 13.2 新特性
- **Partitions**: BOM 多视图管理 API
- **Discussions**: 讨论功能 API
- **Simple Change**: 简化变更流程 API
- **Folder Management**: CAE 文件夹结构管理 API
- **Solver Deck Management**: 求解器 deck 管理 API

### 13.3 新特性
- **Dashboard API**: 可配置仪表板
- **Requirements Workspace**: 需求管理工作区 API
- **EBOM Configurable Modules**: 可配置工程 BOM API
- **Upgrade Assistant**: 升级辅助工具（ITK 代码分析）

## 开发环境要求

### SOA 开发环境
- **JDK**: 1.8 或更高
- **构建工具**: Gradle 4.x+ 或 Maven 3.x+
- **IDE**: Eclipse / IntelliJ IDEA
- **依赖**: `soa_client.jar`, `tcserver.jar`

### ITK 开发环境
- **编译器**: MSVC 2015/2017 (Windows) / GCC 4.8+ (Linux)
- **头文件路径**: `%TC_ROOT%/include`
- **库文件路径**: `%TC_ROOT%/lib`
- **关键库**: `libitk.lib`, `libtc.lib`, `libuser_exits.lib`

## 内存管理规则（ITK 铁律）

```c
// 规则 1: ITK 返回的 char* 必须使用 MEM_free 释放
char *value = NULL;
ITK_call(AOM_ask_value_string(item_tag, "object_name", &value));
// 使用 value...
MEM_free(value);  // ← 必须释放

// 规则 2: tag_t 数组使用 MEM_free 释放
tag_t *tags = NULL;
int count = 0;
ITK_call(WSOM_find_objects2(&count, &tags));
// 使用 tags...
MEM_free(tags);  // ← 必须释放

// 规则 3: 字符串数组需要遍历释放
char **values = NULL;
int count = 0;
ITK_call(AOM_ask_value_strings(item_tag, "some_attr", &count, &values));
for (int i = 0; i < count; i++) {
    MEM_free(values[i]);  // ← 先释放每个字符串
}
MEM_free(values);  // ← 再释放数组本身
```

## 错误处理规范

```c
// 标准错误处理模式
int status = ITK_ok;
char *error_text = NULL;

status = SOME_ITK_FUNCTION(args);

if (status != ITK_ok) {
    EMH_ask_error_text(status, &error_text);
    printf("Error: %s\n", error_text);
    MEM_free(error_text);
    return status;  // 或进行恢复处理
}
```

## 事务管理

```c
// 标准事务模式
ITK_call(ITK_initialize_text_services(0));
ITK_call(ITK_auto_login("infodba", "infodba", "dba"));

// 开始事务
ITK_call(ITK_set_bypass(true));  // 可选：绕过某些规则

// 执行操作...
ITK_call(AOM_save(item_tag));

// 提交或回滚
// ITK_call(AOM_refresh(item_tag, true));  // 回滚

ITK_call(ITK_exit_module(true));  // true = 正常退出
```

## 常用命名规范

### SOA 命名规范
- **Service 类**: `{Module}Service` (如: `CoreService`, `QueryService`)
- **Operation 方法**: `{action}{Object}` (如: `createItem`, `findItem`)
- **Model 类**: 与 Teamcenter 类型名一致 (如: `Item`, `ItemRevision`)

### ITK 命名规范
- **函数前缀**: `{module}_{action}` (如: `AOM_ask_value`, `ITEM_create_item`)
- **自定义函数**: `{company}_{module}_{action}` (如: `ACME_query_findItems`)
- **常量**: 全大写 (如: `ITEM_name_size_c`)

## 文件组织规范

### SOA 项目结构
```
project/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/company/tc/
│   │   │       ├── service/       # 服务实现
│   │   │       ├── model/         # 数据模型
│   │   │       └── util/          # 工具类
│   │   └── resources/
│   │       └── META-INF/
│   └── test/
└── build.gradle
```

### ITK 项目结构
```
project/
├── src/
│   ├── acme_query.c
│   ├── acme_bom.c
│   └── acme_utils.c
├── include/
│   └── acme_utils.h
├── makefile
└── README.md
```
