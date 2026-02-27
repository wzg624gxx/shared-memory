# Teamcenter 13 常用函数速查表

## ITK 核心函数

### 初始化与登录

| 函数 | 用途 | 示例 |
|-----|------|------|
| `ITK_initialize_text_services` | 初始化文本服务 | `ITK_initialize_text_services(0)` |
| `ITK_auto_login` | 自动登录 | `ITK_auto_login("infodba", "infodba", "dba")` |
| `ITK_exit_module` | 退出模块 | `ITK_exit_module(true)` |
| `ITK_set_bypass` | 设置 bypass 模式 | `ITK_set_bypass(true)` |

### 内存管理

| 函数 | 用途 | 示例 |
|-----|------|------|
| `MEM_free` | 释放内存 | `MEM_free(ptr)` |
| `MEM_alloc` | 分配内存 | `MEM_alloc(size)` |

### 错误处理

| 函数 | 用途 | 示例 |
|-----|------|------|
| `EMH_ask_error_text` | 获取错误文本 | `EMH_ask_error_text(status, &text)` |
| `EMH_store_error_s1` | 存储错误消息 | `EMH_store_error_s1(severity, code, text)` |
| `EMH_clear_errors` | 清除错误 | `EMH_clear_errors()` |

## Item 操作

### 创建与查找

```c
// 创建 Item
ITEM_create_item(
    const char *item_id,      // NULL 表示自动生成
    const char *item_name,
    const char *item_type,    // "Item", "Part", "Document" 等
    const char *rev_id,       // "A", "001" 等
    tag_t *item_tag,
    tag_t *itemrev_tag
);

// 按 ID 查找
ITEM_find_items_by_key_value(
    const char *key,          // "item_id"
    const char *value,
    int *count,
    tag_t **items
);

// 按 Item ID 查找 ItemRevision
ITEM_find_item_revs_by_key_value(
    const char *key,
    const char *value,
    int *count,
    tag_t **itemrevs
);
```

### 属性访问

```c
// 获取 ID
ITEM_ask_id(tag_t item, char **item_id);

// 获取名称
ITEM_ask_name(tag_t item, char **item_name);

// 获取类型
ITEM_ask_type(tag_t item, char **item_type);

// 获取最新版本
ITEM_ask_latest_rev(tag_t item, tag_t *itemrev);

// 获取所有版本
ITEM_list_all_revs(tag_t item, int *count, tag_t **itemrevs);
```

### ItemRevision 操作

```c
// 获取父 Item
ITEM_ask_item_of_rev(tag_t itemrev, tag_t *item);

// 获取版本 ID
ITEM_ask_rev_id(tag_t itemrev, char **rev_id);

// 创建新版本
ITEM_create_rev(
    tag_t parent_item,
    const char *rev_id,
    tag_t *new_rev
);
```

## AOM (Active Object Model)

### 属性读取

```c
// 字符串属性
AOM_ask_value_string(tag_t object, const char *prop, char **value);

// 整数属性
AOM_ask_value_int(tag_t object, const char *prop, int *value);

// 双精度属性
AOM_ask_value_double(tag_t object, const char *prop, double *value);

// 逻辑属性
AOM_ask_value_logical(tag_t object, const char *prop, logical *value);

// 日期属性
AOM_ask_value_date(tag_t object, const char *prop, date_t *value);

// Tag 属性
AOM_ask_value_tag(tag_t object, const char *prop, tag_t *value);

// 字符串数组
AOM_ask_value_strings(tag_t object, const char *prop, int *count, char ***values);

// Tag 数组
AOM_ask_value_tags(tag_t object, const char *prop, int *count, tag_t **values);
```

### 属性设置

```c
// 设置字符串
AOM_set_value_string(tag_t object, const char *prop, const char *value);

// 设置整数
AOM_set_value_int(tag_t object, const char *prop, int value);

// 设置双精度
AOM_set_value_double(tag_t object, const char *prop, double value);

// 设置逻辑值
AOM_set_value_logical(tag_t object, const char *prop, logical value);

// 设置日期
AOM_set_value_date(tag_t object, const char *prop, date_t value);

// 设置 Tag
AOM_set_value_tag(tag_t object, const char *prop, tag_t value);

// 追加到数组
AOM_append_value_string(tag_t object, const char *prop, const char *value);
```

### 对象操作

```c
// 保存对象
AOM_save(tag_t object);

// 刷新对象
AOM_refresh(tag_t object, logical discard_changes);

// 删除对象
AOM_delete(tag_t object);

// 锁定对象
AOM_lock(tag_t object);

// 解锁对象
AOM_unlock(tag_t object);

// 询问属性类型
AOM_ask_value_type(tag_t object, const char *prop, int *prop_type);
```

## 查询 (QRY)

```c
// 查找已保存查询
QRY_find(const char *query_name, tag_t *query);

// 执行查询
QRY_execute(
    tag_t query,
    int n_entries,
    char **entries,
    char **values,
    int *count,
    tag_t **results
);

// 获取查询描述
QRY_ask_query_description(tag_t query, char **description);

// 获取查询字段
QRY_ask_query_entries(tag_t query, int *count, char ***entries);
```

## BOM 操作

### BOM 窗口

```c
// 创建 BOM 窗口
BOM_create_window(tag_t *bom_window);

// 关闭 BOM 窗口
BOM_close_window(tag_t bom_window);

// 保存 BOM 窗口
BOM_save_window(tag_t bom_window);

// 设置顶层行
BOM_set_window_top_line(
    tag_t bom_window,
    tag_t item,
    tag_t itemrev,
    tag_t bom_view,
    tag_t *bom_line
);

// 设置配置规则
BOM_set_window_config_rule(tag_t bom_window, tag_t rule);

// 设置修订规则
BOM_set_window_rev_rule(tag_t bom_window, tag_t rev_rule);
```

### BOM 行

```c
// 获取子行
BOM_line_ask_child_lines(tag_t bom_line, int *count, tag_t **children);

// 获取所有子行（递归）
BOM_line_ask_all_child_lines(tag_t bom_line, int *count, tag_t **children);

// 获取父行
BOM_line_ask_parent_line(tag_t bom_line, tag_t *parent);

// 获取关联的 ItemRevision
BOM_line_ask_item_rev(tag_t bom_line, tag_t *itemrev);

// 获取关联的 Item
BOM_line_ask_item(tag_t bom_line, tag_t *item);

// 设置属性
BOM_line_set_attribute_string(tag_t bom_line, const char *attr, const char *value);
BOM_line_set_attribute_int(tag_t bom_line, const char *attr, int value);
BOM_line_set_attribute_double(tag_t bom_line, const char *attr, double value);

// 获取属性
BOM_line_ask_attribute_string(tag_t bom_line, const char *attr, char **value);
BOM_line_ask_attribute_int(tag_t bom_line, const char *attr, int *value);
BOM_line_ask_attribute_double(tag_t bom_line, const char *attr, double *value);

// 常用 BOM 行属性
// "bl_item_item_id" - Item ID
// "bl_item_object_name" - Item 名称
// "bl_rev_item_revision_id" - 版本 ID
// "bl_quantity" - 数量
// "bl_uom" - 单位
// "bl_occurrence_type" - 出现类型
```

### BOM 修改

```c
// 添加子项
BOM_line_add(
    tag_t parent_line,
    tag_t child_item,
    tag_t child_itemrev,
    tag_t bom_view,
    logical is_precise,
    tag_t *new_line
);

// 移除子项
BOM_line_remove(tag_t bom_line);

// 替换子项
BOM_line_replace(
    tag_t bom_line,
    tag_t new_item,
    tag_t new_itemrev,
    tag_t bom_view,
    logical is_precise
);

// 剪切行
BOM_line_cut(tag_t bom_line);

// 粘贴行
BOM_line_paste(tag_t parent_line, tag_t *new_line);
```

## Dataset 操作

```c
// 查找 Dataset 类型
AE_find_datasettype(const char *type_name, tag_t *datasettype);

// 创建 Dataset
AE_create_dataset(
    tag_t datasettype,
    const char *dataset_name,
    const char *dataset_desc,
    tag_t *dataset
);

// 创建 Dataset 带 ID
AE_create_dataset_with_id(
    tag_t datasettype,
    const char *dataset_name,
    const char *dataset_desc,
    const char *dataset_id,
    const char *tool_name,
    tag_t *dataset
);

// 添加命名引用
AE_add_dataset_named_ref(
    tag_t dataset,
    const char *reference_name,
    const char *tool_name,
    tag_t object
);

// 列出引用
AE_ask_dataset_named_refs(
    tag_t dataset,
    const char *reference_name,
    int *count,
    tag_t **refs
);

// 移除引用
AE_remove_dataset_named_ref(tag_t dataset, const char *reference_name, tag_t ref);
```

## ImanFile 操作

```c
// 创建 ImanFile
IMF_create_file(
    const char *file_path,
    const char *file_name,
    AE_reference_type_t *ref_type,
    tag_t *imanfile
);

// 询问文件路径
IMF_ask_file_pathname(tag_t imanfile, int os, char **path);

// 询问原始文件名
IMF_ask_original_file_name(tag_t imanfile, char **file_name);

// 询问文件大小
IMF_ask_file_size(tag_t imanfile, int64_t *size);
```

## 工作流 (EPM)

```c
// 创建流程
EPM_create_process(
    const char *process_name,
    const char *process_desc,
    tag_t process_template,
    tag_t target_attachment,
    tag_t *root_task
);

// 启动流程
EPM_start_process(tag_t root_task);

// 完成任务
EPM_complete_task(tag_t task);

// 中止流程
EPM_abort_process(tag_t root_task);

// 询问根任务
EPM_ask_root_task(tag_t task, tag_t *root_task);

// 询问任务名称
EPM_ask_name(tag_t task, char **name);

// 询问任务状态
EPM_ask_status(tag_t task, EPM_status_t *status);

// 询问附件
EPM_ask_attachments(
    tag_t task,
    EPM_attachment_type_t attachment_type,
    int *count,
    tag_t **attachments
);

// 添加附件
EPM_add_attachment(tag_t task, tag_t object, EPM_attachment_type_t type);

// 移除附件
EPM_remove_attachment(tag_t task, tag_t object, EPM_attachment_type_t type);
```

## 关系 (GRM)

```c
// 查找关系类型
GRM_find_relation_type(const char *type_name, tag_t *relation_type);

// 列出关系
GRM_list_relations(
    tag_t primary,
    tag_t secondary,
    tag_t relation_type,
    int *count,
    tag_t **relations
);

// 创建关系
GRM_create_relation(
    tag_t primary,
    tag_t secondary,
    tag_t relation_type,
    tag_t user_data,
    tag_t *relation
);

// 删除关系
GRM_delete_relation(tag_t relation);

// 询问主对象
GRM_ask_primary(tag_t relation, tag_t *primary);

// 询问次对象
GRM_ask_secondary(tag_t relation, tag_t *secondary);

// 常用关系类型
// "IMAN_specification" - 规格关系
// "IMAN_reference" - 参考关系
// "IMAN_manifestation" - 表现形式关系
// "IMAN_rendering" - 渲染关系
```

## 用户与组织 (SA)

```c
// 查找用户
SA_find_user(const char *user_name, tag_t *user);

// 查找组
SA_find_group(const char *group_name, tag_t *group);

// 查找角色
SA_find_role(const char *role_name, tag_t *role);

// 获取当前用户
SA_ask_current_user(tag_t *user);

// 获取用户默认组
SA_ask_user_default_group(tag_t user, tag_t *group);

// 获取用户名称
SA_ask_user_name(tag_t user, char **user_name);

// 获取用户 ID
SA_ask_user_id(tag_t user, char **user_id);
```

## 配置管理 (CFM)

```c
// 查找配置规则
CFM_find(const char *rule_name, tag_t *rule);

// 常用配置规则
// "Latest Working" - 最新工作版本
// "Latest Released" - 最新发布版本
// "As Stored" - 按存储状态
// "Precise" - 精确版本
```

## SOA Java 常用类

### 核心服务

```java
// 数据管理服务
DataManagementService dmService = DataManagementService.getService(connection);

// 查询服务
SavedQueryService queryService = SavedQueryService.getService(connection);

// 会话服务
SessionService sessionService = SessionService.getService(connection);

// 结构管理服务
StructureManagementService structureService = 
    StructureManagementService.getService(connection);

// 文件管理服务
FileManagementService fileService = FileManagementService.getService(connection);

// 工作流服务
WorkflowService workflowService = WorkflowService.getService(connection);
```

### 常用方法

```java
// 获取属性
dmService.getProperties(ModelObject[] objects, String[] propertyNames);

// 设置属性
dmService.setProperties(ModelObject[] objects, String[] propertyNames, String[] values);

// 保存对象
dmService.saveObjects(ModelObject[] objects, String[] propertyNames);

// 删除对象
dmService.deleteObjects(ModelObject[] objects);

// 刷新对象
dmService.refreshObjects(ModelObject[] objects);

// 加载对象
dmService.loadObjects(String[] uids);
```

## 常见错误码

| 错误码 | 含义 | 处理建议 |
|-------|------|---------|
| `ITK_ok` (0) | 成功 | - |
| `EMH_NO_ERROR` | 无错误 | - |
| `ITK_invalid_tag` | 无效 Tag | 检查对象是否存在 |
| `ITK_invalid_name` | 无效名称 | 检查命名规范 |
| `ITK_duplicate` | 重复对象 | 检查唯一性约束 |
| `ITK_not_found` | 未找到 | 检查查询条件 |
| `ITK_no_permission` | 无权限 | 检查用户权限 |
| `ITK_locked` | 对象被锁定 | 等待或联系锁定者 |
| `ITK_not_initialized` | 未初始化 | 检查 ITK 初始化 |
