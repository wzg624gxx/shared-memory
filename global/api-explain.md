# Teamcenter 13 API 解释

解释 Teamcenter 13 API 的用法、参数和示例。

## 使用方法

用户提供 API 名称，我提供：
1. 功能说明
2. 函数签名
3. 参数解释
4. 返回值
5. 完整示例
6. 相关 API

## 示例

**用户**: "解释 ITEM_create_item"

**回复**:
```
## ITEM_create_item

创建一个新的 Item 和对应的 ItemRevision。

### 函数签名
```c
int ITEM_create_item(
    const char *item_id,      // 输入: Item ID，NULL 表示自动生成
    const char *item_name,    // 输入: Item 名称
    const char *item_type,    // 输入: Item 类型 (如 "Item", "Part")
    const char *rev_id,       // 输入: 版本 ID (如 "A", "001")
    tag_t *item_tag,          // 输出: 创建的 Item tag
    tag_t *itemrev_tag        // 输出: 创建的 ItemRevision tag
);
```

### 返回值
- ITK_ok (0): 成功
- 其他: 错误码，使用 EMH_ask_error_text 获取错误信息

### 完整示例
```c
int create_sample_item() {
    int status = ITK_ok;
    tag_t item = NULLTAG;
    tag_t itemrev = NULLTAG;
    char *item_id = NULL;
    
    status = ITEM_create_item(
        NULL,              // 自动生成 ID
        "Sample Part",     // 名称
        "Part",            // 类型
        "A",               // 版本
        &item,
        &itemrev
    );
    
    if (status == ITK_ok) {
        ITEM_ask_id(item, &item_id);
        printf("Created: %s\n", item_id);
        MEM_free(item_id);
        
        AOM_save(item);
        AOM_save(itemrev);
    }
    
    return status;
}
```

### 相关 API
- ITEM_find_items_by_key_value: 查找 Item
- ITEM_ask_latest_rev: 获取最新版本
- AOM_save: 保存对象
```
