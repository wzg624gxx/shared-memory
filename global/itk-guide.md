# ITK 开发指南

## 概述

ITK (Integration Toolkit) 是 Teamcenter 的 C/C++ API，提供最高性能的系统级访问能力。Teamcenter 13 ITK 保持向后兼容，同时引入了新的 API 和弃用了部分旧接口。

## 核心头文件

```c
// 基础头文件
#include <tc/tc.h>              // ITK 核心 API
#include <tc/emh.h>             // 错误处理
#include <tc/mem.h>             // 内存管理
#include <tc/tc_startup.h>      // 启动/退出

// 对象管理
#include <sa/user.h>            // 用户/组管理
#include <sa/group.h>
#include <sa/role.h>

// Item 管理
#include <item/item.h>          // Item 操作
#include <item/itemrevision.h>  // ItemRevision 操作
#include <item/itemdesc.h>      // Item 描述

// BOM 管理
#include <bom/bom.h>            // BOM 操作
#include <bom/bom_window.h>     // BOM 窗口
#include <bom/bom_line.h>       // BOM 行

// 数据集管理
#include <ae/dataset.h>         // Dataset 操作
#include <ae/datasettype.h>     // Dataset 类型
#include <ae/imf.h>             // ImanFile 操作

// 查询
#include <qry/qry.h>            // 查询操作

// 属性管理
#include <property/property.h>  // 属性操作
#include <tccore/aom.h>         // AOM (Active Object Model)
#include <tccore/aom_prop.h>    // AOM 属性

// 工作流
#include <epm/epm.h>            // 工作流操作
#include <epm/signoff.h>        // 签核操作

// 其他常用
#include <tccore/grm.h>         // 关系管理
#include <tccore/project.h>     // 项目管理
#include <cfm/cfm.h>            // 配置管理
#include <fclasses/tc_string.h> // 字符串工具
```

## 程序结构模板

```c
/**
 * @file acme_sample.c
 * @brief Teamcenter 13 ITK 示例程序
 * @version TC 13.x
 */

#include <tc/tc.h>
#include <tc/emh.h>
#include <tc/mem.h>
#include <tc/tc_startup.h>
#include <item/item.h>
#include <item/itemrevision.h>
#include <tccore/aom.h>
#include <stdio.h>

// 错误处理宏
#define CHECK_STATUS(func) \
    if (status != ITK_ok) { \
        char *error_text = NULL; \
        EMH_ask_error_text(status, &error_text); \
        printf("Error in %s: %s (code: %d)\n", #func, error_text, status); \
        MEM_free(error_text); \
        goto CLEANUP; \
    }

// 主函数
extern int ITK_user_main(int argc, char* argv[])
{
    int status = ITK_ok;
    
    // 初始化
    status = ITK_initialize_text_services(0);
    CHECK_STATUS(ITK_initialize_text_services);
    
    // 登录
    status = ITK_auto_login("infodba", "infodba", "dba");
    CHECK_STATUS(ITK_auto_login);
    
    printf("Login successful!\n");
    
    // ========== 业务逻辑开始 ==========
    
    // 你的代码...
    
    // ========== 业务逻辑结束 ==========
    
CLEANUP:
    // 退出
    ITK_exit_module(true);
    return status;
}
```

## 常用操作模板

### 1. Item 操作

```c
#include <item/item.h>
#include <item/itemrevision.h>

/**
 * 创建 Item 和 ItemRevision
 */
int create_item_example()
{
    int status = ITK_ok;
    tag_t item_tag = NULLTAG;
    tag_t itemrev_tag = NULLTAG;
    char *item_id = NULL;
    char *item_name = NULL;
    
    // 创建 Item
    status = ITEM_create_item(
        "000123",           // Item ID (NULL 表示自动生成)
        "My Test Part",     // Item 名称
        "Item",             // Item 类型
        "A",                // 版本 ID
        &item_tag,          // 输出: Item tag
        &itemrev_tag        // 输出: ItemRevision tag
    );
    CHECK_STATUS(ITEM_create_item);
    
    // 获取创建的 ID
    status = ITEM_ask_id(item_tag, &item_id);
    CHECK_STATUS(ITEM_ask_id);
    
    printf("Created Item: %s\n", item_id);
    
    // 保存
    status = AOM_save(item_tag);
    CHECK_STATUS(AOM_save);
    
    status = AOM_save(itemrev_tag);
    CHECK_STATUS(AOM_save);
    
CLEANUP:
    MEM_free(item_id);
    MEM_free(item_name);
    return status;
}

/**
 * 查找 Item
 */
int find_item_example()
{
    int status = ITK_ok;
    int count = 0;
    tag_t *item_tags = NULL;
    
    // 使用 ITEM_find_items_by_key_value 查找
    status = ITEM_find_items_by_key_value(
        "item_id",          // 搜索键
        "000123",           // 搜索值
        &count,             // 结果数量
        &item_tags          // 结果数组
    );
    CHECK_STATUS(ITEM_find_items_by_key_value);
    
    printf("Found %d items\n", count);
    
    // 处理结果...
    for (int i = 0; i < count; i++) {
        char *id = NULL;
        ITEM_ask_id(item_tags[i], &id);
        printf("  Item %d: %s\n", i, id);
        MEM_free(id);
    }
    
CLEANUP:
    MEM_free(item_tags);
    return status;
}

/**
 * 获取 Item 的最新版本
 */
int get_latest_revision(tag_t item_tag, tag_t *latest_rev)
{
    int status = ITK_ok;
    int rev_count = 0;
    tag_t *revisions = NULL;
    
    status = ITEM_list_all_revs(item_tag, &rev_count, &revisions);
    CHECK_STATUS(ITEM_list_all_revs);
    
    if (rev_count > 0) {
        *latest_rev = revisions[rev_count - 1];  // 最后一个是最新的
    } else {
        *latest_rev = NULLTAG;
    }
    
CLEANUP:
    MEM_free(revisions);
    return status;
}
```

### 2. 属性操作 (AOM)

```c
#include <tccore/aom.h>
#include <tccore/aom_prop.h>

/**
 * 读取属性 - 通用模板
 */
int read_property(tag_t object_tag, const char *prop_name, char **value)
{
    int status = ITK_ok;
    int prop_type = 0;
    
    // 先询问属性类型
    status = AOM_ask_value_type(object_tag, prop_name, &prop_type);
    CHECK_STATUS(AOM_ask_value_type);
    
    switch (prop_type) {
        case PROP_string:
        case PROP_external_reference:
            status = AOM_ask_value_string(object_tag, prop_name, value);
            break;
            
        case PROP_int:
        case PROP_logical: {
            int int_val;
            status = AOM_ask_value_int(object_tag, prop_name, &int_val);
            // 转换为字符串...
            break;
        }
            
        case PROP_date: {
            date_t date_val;
            status = AOM_ask_value_date(object_tag, prop_name, &date_val);
            // 格式化日期...
            break;
        }
            
        case PROP_tag: {
            tag_t tag_val;
            status = AOM_ask_value_tag(object_tag, prop_name, &tag_val);
            // 处理 tag...
            break;
        }
            
        default:
            printf("Unsupported property type: %d\n", prop_type);
            break;
    }
    
    CHECK_STATUS(AOM_ask_value_xxx);
    
CLEANUP:
    return status;
}

/**
 * 设置属性 - 通用模板
 */
int set_property(tag_t object_tag, const char *prop_name, const char *value)
{
    int status = ITK_ok;
    
    status = AOM_set_value_string(object_tag, prop_name, value);
    CHECK_STATUS(AOM_set_value_string);
    
    // 保存
    status = AOM_save(object_tag);
    CHECK_STATUS(AOM_save);
    
CLEANUP:
    return status;
}

/**
 * 读取多值属性
 */
int read_string_array_property(tag_t object_tag, const char *prop_name)
{
    int status = ITK_ok;
    int count = 0;
    char **values = NULL;
    
    status = AOM_ask_value_strings(object_tag, prop_name, &count, &values);
    CHECK_STATUS(AOM_ask_value_strings);
    
    printf("Property '%s' has %d values:\n", prop_name, count);
    for (int i = 0; i < count; i++) {
        printf("  [%d]: %s\n", i, values[i]);
    }
    
    // 释放内存 - 重要！
    for (int i = 0; i < count; i++) {
        MEM_free(values[i]);
    }
    MEM_free(values);
    
    return status;
}
```

### 3. 查询操作 (QRY)

```c
#include <qry/qry.h>

/**
 * 执行已保存查询
 */
int execute_saved_query(
    const char *query_name,
    int num_entries,
    char **entries,
    char **values,
    int *result_count,
    tag_t **results)
{
    int status = ITK_ok;
    tag_t query_tag = NULLTAG;
    
    // 查找查询
    status = QRY_find(query_name, &query_tag);
    CHECK_STATUS(QRY_find);
    
    if (query_tag == NULLTAG) {
        printf("Query '%s' not found!\n", query_name);
        status = -1;
        goto CLEANUP;
    }
    
    // 执行查询
    status = QRY_execute(
        query_tag,
        num_entries,
        entries,
        values,
        result_count,
        results
    );
    CHECK_STATUS(QRY_execute);
    
    printf("Query returned %d results\n", *result_count);
    
CLEANUP:
    return status;
}

/**
 * 常用查询示例
 */
int query_examples()
{
    int status = ITK_ok;
    int count = 0;
    tag_t *results = NULL;
    
    // 示例 1: 按 Item ID 查询
    char *entries1[] = {"Item ID"};
    char *values1[] = {"000123"};
    status = execute_saved_query(
        "Item...",
        1,
        entries1,
        values1,
        &count,
        &results
    );
    CHECK_STATUS(query);
    MEM_free(results);
    
    // 示例 2: 模糊查询
    char *entries2[] = {"Item ID", "Object Name"};
    char *values2[] = {"000*", "*test*"};
    status = execute_saved_query(
        "General...",
        2,
        entries2,
        values2,
        &count,
        &results
    );
    CHECK_STATUS(query);
    MEM_free(results);
    
CLEANUP:
    return status;
}
```

### 4. BOM 操作

```c
#include <bom/bom.h>
#include <bom/bom_window.h>
#include <bom/bom_line.h>
#include <cfm/cfm.h>

/**
 * 打开 BOM 并遍历
 */
int traverse_bom_example(tag_t itemrev_tag)
{
    int status = ITK_ok;
    tag_t bom_window = NULLTAG;
    tag_t top_line = NULLTAG;
    tag_t rule = NULLTAG;
    
    // 创建 BOM 窗口
    status = BOM_create_window(&bom_window);
    CHECK_STATUS(BOM_create_window);
    
    // 设置配置规则 (使用最新生效)
    status = CFM_find("Latest Working", &rule);
    CHECK_STATUS(CFM_find);
    
    status = BOM_set_window_config_rule(bom_window, rule);
    CHECK_STATUS(BOM_set_window_config_rule);
    
    // 设置顶层行
    status = BOM_set_window_top_line(bom_window, NULLTAG, itemrev_tag, NULLTAG, &top_line);
    CHECK_STATUS(BOM_set_window_top_line);
    
    // 展开 BOM
    status = BOM_line_ask_all_child_lines(top_line, &count, &children);
    CHECK_STATUS(BOM_line_ask_all_child_lines);
    
    // 递归遍历
    traverse_bom_recursive(top_line, 0);
    
    // 关闭窗口
    BOM_close_window(bom_window);
    
CLEANUP:
    return status;
}

/**
 * 递归遍历 BOM
 */
void traverse_bom_recursive(tag_t bom_line, int level)
{
    int status = ITK_ok;
    int count = 0;
    tag_t *children = NULL;
    tag_t itemrev_tag = NULLTAG;
    char *item_id = NULL;
    char *item_name = NULL;
    
    // 获取行信息
    status = BOM_line_ask_item_rev(bom_line, &itemrev_tag);
    if (status != ITK_ok || itemrev_tag == NULLTAG) return;
    
    // 读取属性
    AOM_ask_value_string(itemrev_tag, "item_id", &item_id);
    AOM_ask_value_string(itemrev_tag, "object_name", &item_name);
    
    // 打印缩进
    for (int i = 0; i < level; i++) printf("  ");
    printf("%s - %s\n", item_id ? item_id : "N/A", item_name ? item_name : "N/A");
    
    // 获取子行
    status = BOM_line_ask_all_child_lines(bom_line, &count, &children);
    if (status == ITK_ok && count > 0) {
        for (int i = 0; i < count; i++) {
            traverse_bom_recursive(children[i], level + 1);
        }
    }
    
    // 清理
    MEM_free(item_id);
    MEM_free(item_name);
    MEM_free(children);
}

/**
 * 修改 BOM 行数量
 */
int set_bom_line_quantity(tag_t bom_line, double quantity)
{
    int status = ITK_ok;
    
    status = BOM_line_set_attribute_real(
        bom_line,
        "bl_quantity",
        quantity
    );
    CHECK_STATUS(BOM_line_set_attribute_real);
    
    // 保存更改
    status = BOM_save_window(bom_line);
    CHECK_STATUS(BOM_save_window);
    
CLEANUP:
    return status;
}
```

### 5. Dataset 和文件操作

```c
#include <ae/dataset.h>
#include <ae/datasettype.h>
#include <ae/imf.h>

/**
 * 创建 Dataset
 */
int create_dataset(
    tag_t itemrev_tag,
    const char *dataset_name,
    const char *dataset_type,
    const char *tool_name,
    tag_t *dataset_tag)
{
    int status = ITK_ok;
    tag_t ds_type_tag = NULLTAG;
    tag_t tool_tag = NULLTAG;
    
    // 查找 Dataset 类型
    status = AE_find_datasettype(dataset_type, &ds_type_tag);
    CHECK_STATUS(AE_find_datasettype);
    
    // 创建 Dataset
    status = AE_create_dataset_with_id(
        ds_type_tag,
        dataset_name,
        "",                 // description
        "",                 // dataset_id (auto)
        tool_name,
        dataset_tag
    );
    CHECK_STATUS(AE_create_dataset_with_id);
    
    // 关联到 ItemRevision
    status = AE_add_dataset_named_ref(
        *dataset_tag,
        "IMAN_specification",   // 关系类型
        tool_name,
        itemrev_tag
    );
    CHECK_STATUS(AE_add_dataset_named_ref);
    
    // 保存
    status = AOM_save(*dataset_tag);
    CHECK_STATUS(AOM_save);
    
CLEANUP:
    return status;
}

/**
 * 上传文件到 Dataset
 */
int upload_file_to_dataset(
    tag_t dataset_tag,
    const char *local_file_path,
    const char *file_name)
{
    int status = ITK_ok;
    tag_t imanfile_tag = NULLTAG;
    AE_reference_type_t ref_type;
    
    // 创建 ImanFile
    status = IMF_create_file(
        local_file_path,
        file_name,
        &ref_type,
        &imanfile_tag
    );
    CHECK_STATUS(IMF_create_file);
    
    // 关联到 Dataset
    status = AE_add_dataset_named_ref2(
        dataset_tag,
        "IMAN_file",
        ref_type,
        imanfile_tag
    );
    CHECK_STATUS(AE_add_dataset_named_ref2);
    
    // 保存
    status = AOM_save(dataset_tag);
    CHECK_STATUS(AOM_save);
    
CLEANUP:
    return status;
}
```

## 编译配置

### Windows (Visual Studio)

```makefile
# Makefile for Teamcenter 13 ITK
TC_ROOT = C:\Siemens\Teamcenter13
TC_DATA = C:\Siemens\tcdata

CC = cl
CFLAGS = /c /O2 /W3 /nologo /EHsc /MT \
    /I"$(TC_ROOT)\include" \
    /I"$(TC_ROOT)\include_cpp" \
    /D "TC13" \
    /D "NT40" \
    /D "WIN32_LEAN_AND_MEAN"

LDFLAGS = /LIBPATH:"$(TC_ROOT)\lib" \
    libitk.lib libtc.lib libuser_exits.lib \
    libtccore.lib libae.lib libbom.lib \
    libqry.lib libepm.lib libgrm.lib \
    kernel32.lib user32.lib ws2_32.lib

TARGET = acme_sample.exe
OBJS = acme_sample.obj

all: $(TARGET)

.c.obj:
    $(CC) $(CFLAGS) $<

$(TARGET): $(OBJS)
    link /OUT:$@ $(OBJS) $(LDFLAGS)

clean:
    del $(OBJS) $(TARGET)
```

### Linux (GCC)

```makefile
TC_ROOT = /opt/teamcenter13
TC_DATA = /opt/tcdata

CC = gcc
CFLAGS = -c -O2 -Wall -fPIC \
    -I$(TC_ROOT)/include \
    -I$(TC_ROOT)/include_cpp \
    -DTC13 -DUNIX -DLINUX

LDFLAGS = -L$(TC_ROOT)/lib \
    -litk -ltc -luser_exits \
    -ltccore -lae -lbom \
    -lqry -lepm -lgrm \
    -lpthread -ldl

TARGET = acme_sample
OBJS = acme_sample.o

all: $(TARGET)

.c.o:
    $(CC) $(CFLAGS) $<

$(TARGET): $(OBJS)
    $(CC) -o $@ $(OBJS) $(LDFLAGS)

clean:
    rm -f $(OBJS) $(TARGET)
```

## Teamcenter 13 升级注意事项

根据官方 Upgrade Assistant 的提示，以下 API 在 TC13 中有所变化：

| 旧 API (已弃用) | 新 API (TC13 推荐) | 说明 |
|----------------|-------------------|------|
| `WSOM_find_objects` | `WSOM_find_objects2` | 增强的搜索功能 |
| `ITEM_find` | `ITEM_find_items_by_key_value` | 更精确的查找 |
| `AOM_refresh` | `AOM_refresh_with_args` | 支持更多刷新选项 |
| `EPM_ask_attachments` | `EPM_ask_attachments2` | 支持更多附件类型 |

使用 `Upgrade Assistant ITK Reporter` 工具可以扫描代码中的弃用 API。
