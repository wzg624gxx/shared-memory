# Teamcenter 13 开发规范与约束

## 命名规范

### SOA 命名
- **包名**: `com.company.tc.{module}`
- **类名**: PascalCase (如 `ItemService`, `BOMHelper`)
- **方法名**: camelCase (如 `createItem`, `findById`)
- **常量**: UPPER_SNAKE_CASE

### ITK 命名
- **自定义函数**: `{company}_{module}_{action}` (如 `ACME_query_findItems`)
- **变量**: 小写 + 下划线 (如 `item_count`, `bom_window`)
- **宏**: 全大写 (如 `CHECK_STATUS`)

## 代码约束

### 内存管理（强制）
```c
// 必须遵循的规则
1. ITK 返回的 char* → 必须使用 MEM_free
2. tag_t 数组 → 必须使用 MEM_free
3. 字符串数组 → 先释放每个元素，再释放数组
4. 禁止直接 free()，必须使用 MEM_free
```

### 错误处理（强制）
```c
// 每个 ITK 调用后必须检查状态
int status = ITK_ok;
status = SOME_ITK_FUNCTION(args);
if (status != ITK_ok) {
    // 处理错误
    goto CLEANUP;
}
```

### 事务管理
```c
// 标准模式
ITK_auto_login(...);
// 业务操作
ITK_exit_module(true);  // 正常退出

// 或
ITK_exit_module(false); // 异常退出，回滚未保存更改
```

## API 版本约束

### TC13 推荐 API
- 使用 `WSOM_find_objects2` 替代 `WSOM_find_objects`
- 使用 `ITEM_find_items_by_key_value` 替代 `ITEM_find`
- 使用 `EPM_ask_attachments2` 替代 `EPM_ask_attachments`

### 已弃用 API（避免使用）
| 旧 API | 替代 API | TC13 状态 |
|-------|---------|----------|
| `WSOM_find_objects` | `WSOM_find_objects2` | 已弃用 |
| `ITEM_find` | `ITEM_find_items_by_key_value` | 已弃用 |
| `AOM_refresh` | `AOM_refresh_with_args` | 已弃用 |
| `EPM_ask_attachments` | `EPM_ask_attachments2` | 已弃用 |

## 性能约束

### 批量操作
- 优先使用数组 API 而非循环单个调用
- 批量获取属性而非逐个获取
- 使用查询过滤而非内存过滤

### BOM 操作
- 及时关闭 BOM 窗口
- 避免深层递归遍历
- 使用配置规则减少展开范围

### 文件操作
- 大文件使用流式传输
- 避免频繁的小文件操作
- 使用缓存减少重复下载

## 安全约束

### 输入验证
- 验证所有用户输入
- 检查字符串长度限制
- 防止 SQL 注入（使用参数化查询）

### 权限检查
- 验证用户操作权限
- 检查对象访问权限
- 记录敏感操作日志

### 敏感信息
- 禁止硬编码密码
- 使用配置文件或环境变量
- 日志中隐藏敏感信息

## 部署约束

### 环境变量
```bash
# 必须设置
TC_ROOT=/opt/teamcenter13
TC_DATA=/opt/tcdata

# 可选但推荐
TC_LOG_LEVEL=INFO
TC_LANG=zh_CN
```

### 文件权限
- ITK 可执行文件: 755
- 配置文件: 644
- 日志目录: 777 (或应用用户可写)

### 服务依赖
- Teamcenter 服务器必须运行
- 数据库连接必须可用
- 文件管理系统 (FMS) 必须可访问
