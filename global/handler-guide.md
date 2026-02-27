# Teamcenter 13 Handler 开发指南

## 概述

Handler 是 Teamcenter 工作流中的动作处理器，用于在流程节点执行自定义逻辑。Teamcenter 13 支持 C/C++ 编写的自定义 Handler。

## Handler 类型

| Handler 类型 | 触发时机 | 用途 |
|-------------|---------|------|
| **Action Handler** | 用户执行动作时 | 执行操作、验证 |
| **Rule Handler** | 流程路由时 | 决定流程走向 |
| **Pre-Action Handler** | 动作执行前 | 前置验证 |
| **Post-Action Handler** | 动作执行后 | 后续处理 |
| **Validation Handler** | 提交流程时 | 数据验证 |

## Handler 结构模板

```c
/**
 * @file acme_custom_handler.c
 * @brief Teamcenter 13 自定义 Handler 示例
 */

#include <tc/tc.h>
#include <tc/emh.h>
#include <tc/mem.h>
#include <epm/epm.h>
#include <epm/signoff.h>
#include <tccore/aom.h>
#include <tccore/grm.h>

// Handler 入口函数 - 标准签名
extern EPM_decision_t ACME_custom_action_handler(
    EPM_action_message_t msg  // 动作消息，包含上下文信息
);

extern EPM_decision_t ACME_custom_rule_handler(
    EPM_rule_message_t msg    // 规则消息
);

/**
 * Action Handler 示例 - 自动设置属性
 */
EPM_decision_t ACME_auto_set_properties(EPM_action_message_t msg)
{
    int status = ITK_ok;
    EPM_decision_t decision = EPM_go;
    
    tag_t root_task = NULLTAG;
    tag_t *attachments = NULL;
    int attachment_count = 0;
    
    // 获取根任务
    status = EPM_ask_root_task(msg.task, &root_task);
    if (status != ITK_ok) {
        return EPM_nogo;
    }
    
    // 获取流程附件（目标对象）
    status = EPM_ask_attachments(
        root_task,
        EPM_target_attachment,
        &attachment_count,
        &attachments
    );
    if (status != ITK_ok) {
        return EPM_nogo;
    }
    
    // 遍历所有附件对象
    for (int i = 0; i < attachment_count; i++) {
        char *object_type = NULL;
        
        // 获取对象类型
        status = WSOM_ask_object_type2(attachments[i], &object_type);
        if (status == ITK_ok) {
            // 只处理 ItemRevision
            if (strcmp(object_type, "ItemRevision") == 0 ||
                strcmp(object_type, "ACME_PartRevision") == 0) {
                
                // 设置属性
                status = AOM_set_value_string(
                    attachments[i],
                    "acme_workflow_status",
                    "In Review"
                );
                
                if (status == ITK_ok) {
                    AOM_save(attachments[i]);
                }
            }
        }
        
        MEM_free(object_type);
    }
    
    MEM_free(attachments);
    
    return decision;
}

/**
 * Rule Handler 示例 - 根据属性决定路由
 */
EPM_decision_t ACME_check_approval_required(EPM_rule_message_t msg)
{
    int status = ITK_ok;
    EPM_decision_t decision = EPM_go;  // 默认通过
    
    tag_t root_task = NULLTAG;
    tag_t *attachments = NULL;
    int attachment_count = 0;
    logical needs_approval = false;
    
    // 获取附件
    status = EPM_ask_root_task(msg.task, &root_task);
    if (status != ITK_ok) return EPM_nogo;
    
    status = EPM_ask_attachments(
        root_task,
        EPM_target_attachment,
        &attachment_count,
        &attachments
    );
    if (status != ITK_ok) return EPM_nogo;
    
    // 检查每个附件
    for (int i = 0; i < attachment_count; i++) {
        double weight = 0.0;
        
        // 读取重量属性
        status = AOM_ask_value_double(
            attachments[i],
            "acme_weight_kg",
            &weight
        );
        
        // 重量超过 100kg 需要审批
        if (status == ITK_ok && weight > 100.0) {
            needs_approval = true;
            break;
        }
    }
    
    // 根据条件返回不同决策
    if (needs_approval) {
        decision = EPM_go;  // 走审批分支
    } else {
        decision = EPM_bypass;  // 跳过审批
    }
    
    MEM_free(attachments);
    
    return decision;
}

/**
 * Validation Handler 示例 - 提交前验证
 */
EPM_decision_t ACME_validate_before_submit(EPM_action_message_t msg)
{
    int status = ITK_ok;
    EPM_decision_t decision = EPM_go;
    
    tag_t root_task = NULLTAG;
    tag_t *attachments = NULL;
    int attachment_count = 0;
    
    status = EPM_ask_root_task(msg.task, &root_task);
    if (status != ITK_ok) return EPM_nogo;
    
    status = EPM_ask_attachments(
        root_task,
        EPM_target_attachment,
        &attachment_count,
        &attachments
    );
    if (status != ITK_ok) return EPM_nogo;
    
    // 验证每个附件
    for (int i = 0; i < attachment_count; i++) {
        char *category = NULL;
        logical approved = false;
        
        // 检查必填字段
        status = AOM_ask_value_string(
            attachments[i],
            "acme_part_category",
            &category
        );
        
        if (status != ITK_ok || category == NULL || strlen(category) == 0) {
            // 设置错误消息
            EMH_store_error_s1(
                EMH_severity_error,
                0,
                "Part category is required before submission"
            );
            decision = EPM_nogo;
            MEM_free(category);
            break;
        }
        
        // 检查批准状态
        status = AOM_ask_value_logical(
            attachments[i],
            "acme_approved",
            &approved
        );
        
        if (status != ITK_ok || !approved) {
            EMH_store_error_s1(
                EMH_severity_error,
                0,
                "Part must be approved before workflow submission"
            );
            decision = EPM_nogo;
            MEM_free(category);
            break;
        }
        
        MEM_free(category);
    }
    
    MEM_free(attachments);
    
    return decision;
}

/**
 * Handler 注册入口 - 在模块加载时调用
 */
extern DLLAPI int ACME_custom_handler_register_callbacks()
{
    int status = ITK_ok;
    
    // 注册 Action Handler
    status = EPM_register_action_handler(
        "ACME-auto-set-properties",      // Handler 名称
        "Auto set properties on workflow start",
        ACME_auto_set_properties         // 函数指针
    );
    if (status != ITK_ok) {
        printf("Failed to register ACME-auto-set-properties\n");
        return status;
    }
    
    // 注册 Rule Handler
    status = EPM_register_rule_handler(
        "ACME-check-approval-required",
        "Check if approval is required based on weight",
        ACME_check_approval_required
    );
    if (status != ITK_ok) {
        printf("Failed to register ACME-check-approval-required\n");
        return status;
    }
    
    // 注册 Validation Handler
    status = EPM_register_action_handler(
        "ACME-validate-before-submit",
        "Validate part before workflow submission",
        ACME_validate_before_submit
    );
    if (status != ITK_ok) {
        printf("Failed to register ACME-validate-before-submit\n");
        return status;
    }
    
    printf("ACME custom handlers registered successfully\n");
    
    return ITK_ok;
}
```

## Handler 常用 API

### 获取流程信息

```c
// 获取根任务
tag_t root_task;
EPM_ask_root_task(current_task, &root_task);

// 获取任务名称
char *task_name;
EPM_ask_name(current_task, &task_name);

// 获取任务状态
EPM_status_t task_status;
EPM_ask_status(current_task, &task_status);
// task_status: EPM_started, EPM_completed, EPM_aborted, etc.

// 获取父任务
tag_t parent_task;
EPM_ask_parent(current_task, &parent_task);

// 获取子任务
int child_count;
tag_t *child_tasks;
EPM_ask_child_tasks(current_task, &child_count, &child_tasks);
```

### 附件操作

```c
// 获取目标附件（流程操作的主要对象）
tag_t *targets;
int target_count;
EPM_ask_attachments(root_task, EPM_target_attachment, &target_count, &targets);

// 获取参考附件
int ref_count;
tag_t *references;
EPM_ask_attachments(root_task, EPM_reference_attachment, &ref_count, &references);

// 添加附件
EPM_add_attachment(root_task, object_tag, EPM_target_attachment);

// 移除附件
EPM_remove_attachment(root_task, object_tag, EPM_target_attachment);
```

### 签核操作

```c
// 获取签核列表
tag_t *signoffs;
int signoff_count;
EPM_ask_signoffs(current_task, &signoff_count, &signoffs);

// 获取签核状态
EPM_signoff_decision_t decision;
EPM_ask_signoff_decision(signoffs[0], &decision);
// decision: EPM_signoff_approved, EPM_signoff_rejected, EPM_signoff_no_decision

// 获取签核人
tag_t signer;
EPM_ask_signoff_signer(signoffs[0], &signer);
```

### 流程控制

```c
// 完成任务
EPM_complete_task(current_task);

// 中止流程
EPM_abort_process(root_task);

// 挂起任务
EPM_suspend_task(current_task);

// 恢复任务
EPM_resume_task(current_task);
```

## Handler 注册配置

```xml
<!-- custom_handlers.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<handlers>
    <action-handler name="ACME-auto-set-properties"
                    description="Auto set properties on workflow start"
                    library="libacme_handlers.dll"
                    function="ACME_auto_set_properties"/>
    
    <rule-handler name="ACME-check-approval-required"
                  description="Check if approval is required"
                  library="libacme_handlers.dll"
                  function="ACME_check_approval_required"/>
    
    <validation-handler name="ACME-validate-before-submit"
                        description="Validate before submission"
                        library="libacme_handlers.dll"
                        function="ACME_validate_before_submit"/>
</handlers>
```

## Handler 编译

```makefile
# Handler 编译需要链接额外的库
TC_ROOT = C:\Siemens\Teamcenter13

CC = cl
CFLAGS = /c /O2 /W3 /nologo /EHsc /MT /LD \
    /I"$(TC_ROOT)\include" \
    /D "TC13" /D "NT40" /D "WIN32_LEAN_AND_MEAN"

LDFLAGS = /DLL /LIBPATH:"$(TC_ROOT)\lib" \
    libitk.lib libtc.lib libuser_exits.lib \
    libepm.lib libtccore.lib \
    kernel32.lib

TARGET = libacme_handlers.dll
OBJS = acme_custom_handler.obj

all: $(TARGET)

$(TARGET): $(OBJS)
    link /OUT:$@ $(OBJS) $(LDFLAGS)

clean:
    del $(OBJS) $(TARGET)
```

## 部署步骤

1. 编译 Handler DLL/SO
2. 复制到 `%TC_ROOT%/lib` 或 `%TC_ROOT%/bin`
3. 在 BMIDE 中注册 Handler
4. 在工作流模板中配置 Handler
5. 重启 Teamcenter 服务

## 调试技巧

```c
// 使用日志输出调试信息
#include <tc/tc_util.h>

void log_debug(const char *format, ...)
{
    va_list args;
    va_start(args, format);
    
    char buffer[1024];
    vsnprintf(buffer, sizeof(buffer), format, args);
    
    // 输出到 Teamcenter 日志
    TC_write_syslog("ACME_HANDLER: %s\n", buffer);
    
    va_end(args);
}

// 在 Handler 中使用
EPM_decision_t my_handler(EPM_action_message_t msg)
{
    log_debug("Handler called for task: %p", msg.task);
    
    // ... 逻辑代码
    
    log_debug("Handler completed with decision: %d", decision);
    
    return decision;
}
```
