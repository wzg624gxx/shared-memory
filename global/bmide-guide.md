# BMIDE 业务建模指南

## 概述

BMIDE (Business Modeler Integrated Development Environment) 是 Teamcenter 13 中用于扩展数据模型和业务规则的主要工具。通过 BMIDE 可以：

- 创建自定义业务对象类型
- 定义新的属性和关系
- 配置业务规则 (Rules)
- 定义常量 (Constants)
- 管理 LOV (List of Values)

## 核心概念

### 业务对象层次结构

```
WorkspaceObject (基类)
    ├── Item
    │     ├── Part
    │     ├── Document
    │     └── [你的自定义Item类型]
    ├── Dataset
    │     ├── PDF
    │     ├── Text
    │     └── [你的自定义Dataset类型]
    ├── Folder
    └── [其他]
```

### BMIDE 项目结构

```
MyBMIDEProject/
├── code/
│   ├── item_types.xml          # Item 类型定义
│   ├── dataset_types.xml       # Dataset 类型定义
│   ├── business_rules.xml      # 业务规则
│   ├── constants.xml           # 常量定义
│   └── lovs.xml               # LOV 定义
├── install/
│   └── [部署脚本]
└── MyBMIDEProject.xml         # 项目主文件
```

## 常用扩展类型

### 1. 自定义 Item 类型

```xml
<!-- item_types.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<types>
    <!-- 扩展 Part 类型 -->
    <type name="ACME_Part" 
          parent="Part"
          description="ACME Custom Part Type">
        
        <!-- 自定义属性 -->
        <property name="acme_part_category" 
                  type="String"
                  maxLength="64"
                  description="Part Category"/>
        
        <property name="acme_weight_kg" 
                  type="Double"
                  description="Weight in Kilograms"/>
        
        <property name="acme_manufacturing_date" 
                  type="Date"
                  description="Manufacturing Date"/>
        
        <property name="acme_approved" 
                  type="Logical"
                  description="Approval Status"/>
        
        <!-- 多值属性 -->
        <property name="acme_suppliers" 
                  type="String"
                  maxLength="128"
                  arraySize="-1"
                  description="Supplier List"/>
        
        <!-- 引用属性 -->
        <property name="acme_designer" 
                  type="User"
                  description="Designer User"/>
    </type>
    
    <!-- 对应的 ItemRevision 类型 -->
    <type name="ACME_PartRevision" 
          parent="PartRevision">
        
        <property name="acme_revision_status" 
                  type="String"
                  maxLength="32"
                  description="Custom Revision Status"/>
    </type>
</types>
```

### 2. 自定义 Dataset 类型

```xml
<!-- dataset_types.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<types>
    <type name="ACME_DesignFile"
          parent="Dataset"
          description="ACME Design File">
        
        <!-- 引用关系 -->
        <relation name="ACME_design_source"
                  type="IMAN_specification"
                  targetType="ACME_PartRevision"
                  description="Design Source"/>
        
        <!-- 自定义属性 -->
        <property name="acme_file_format"
                  type="String"
                  maxLength="16"
                  description="File Format (STEP, IGES, etc.)"/>
        
        <property name="acme_file_version"
                  type="Integer"
                  description="File Version"/>
    </type>
</types>
```

### 3. LOV (List of Values)

```xml
<!-- lovs.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<lists>
    <!-- 简单 LOV -->
    <lov name="ACME_PartCategories"
         type="String"
         description="Part Category LOV">
        <value>Mechanical</value>
        <value>Electrical</value>
        <value>Hydraulic</value>
        <value>Pneumatic</value>
        <value>Software</value>
    </lov>
    
    <!-- 带描述的 LOV -->
    <lov name="ACME_RevisionStatus"
         type="String"
         description="Revision Status">
        <value description="Work in Progress">WIP</value>
        <value description="Under Review">REVIEW</value>
        <value description="Approved">APPROVED</value>
        <value description="Released">RELEASED</value>
        <value description="Obsolete">OBSOLETE</value>
    </lov>
    
    <!-- 级联 LOV -->
    <lov name="ACME_Departments"
         type="String"
         description="Department List">
        <value>Engineering</value>
        <value>Manufacturing</value>
        <value>Quality</value>
        <value>Procurement</value>
    </lov>
</lists>
```

### 4. 业务规则 (Rules)

```xml
<!-- business_rules.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<rules>
    <!-- 属性验证规则 -->
    <rule name="ACME_ValidatePartWeight"
          type="Validation"
          targetType="ACME_Part"
          description="Validate part weight is positive">
        
        <condition>
            <expression>
                acme_weight_kg &gt; 0
            </expression>
            <errorMessage>
                Part weight must be greater than 0
            </errorMessage>
        </condition>
    </rule>
    
    <!-- 命名规则 -->
    <rule name="ACME_PartIdFormat"
          type="Naming"
          targetType="ACME_Part"
          description="Part ID must start with ACME-">
        
        <pattern>^ACME-[0-9]{6}$</pattern>
        <errorMessage>
            Part ID must follow format: ACME-######
        </errorMessage>
    </rule>
    
    <!-- 必填字段规则 -->
    <rule name="ACME_RequireCategory"
          type="Required"
          targetType="ACME_Part"
          description="Part category is required">
        
        <property>acme_part_category</property>
        <errorMessage>
            Part category must be specified
        </errorMessage>
    </rule>
</rules>
```

### 5. 常量定义 (Constants)

```xml
<!-- constants.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<constants>
    <!-- 字符串常量 -->
    <constant name="ACME_COMPANY_NAME"
              type="String"
              value="ACME Corporation"/>
    
    <constant name="ACME_DEFAULT_UNIT"
              type="String"
              value="mm"/>
    
    <!-- 数值常量 -->
    <constant name="ACME_MAX_PART_WEIGHT"
              type="Double"
              value="1000.0"/>
    
    <constant name="ACME_DEFAULT_REVISION"
              type="String"
              value="A"/>
    
    <!-- 逻辑常量 -->
    <constant name="ACME_STRICT_VALIDATION"
              type="Logical"
              value="true"/>
</constants>
```

## BMIDE 操作模板

### 创建扩展类型的标准流程

```
1. 在 BMIDE 中创建新项目
   File → New → BMIDE Project
   
2. 定义业务对象类型
   - 右键 Types → New Type
   - 选择父类型
   - 添加自定义属性
   
3. 定义 LOV
   - 右键 Lists of Values → New LOV
   - 添加值列表
   
4. 定义规则
   - 右键 Rules → New Rule
   - 配置规则条件
   
5. 保存并部署
   - File → Save
   - 生成部署包
   - 在服务器上运行 install.bat/install.sh
```

### 代码中访问 BMIDE 扩展

```c
// ITK 中访问 BMIDE 扩展属性
#include <tccore/aom.h>

int access_bmide_properties(tag_t item_tag)
{
    int status = ITK_ok;
    char *category = NULL;
    double weight = 0.0;
    date_t mfg_date;
    logical approved = false;
    
    // 读取 BMIDE 扩展属性
    status = AOM_ask_value_string(item_tag, "acme_part_category", &category);
    CHECK_STATUS(AOM_ask_value_string);
    
    status = AOM_ask_value_double(item_tag, "acme_weight_kg", &weight);
    CHECK_STATUS(AOM_ask_value_double);
    
    status = AOM_ask_value_date(item_tag, "acme_manufacturing_date", &mfg_date);
    CHECK_STATUS(AOM_ask_value_date);
    
    status = AOM_ask_value_logical(item_tag, "acme_approved", &approved);
    CHECK_STATUS(AOM_ask_value_logical);
    
    printf("Category: %s\n", category);
    printf("Weight: %.2f kg\n", weight);
    printf("Approved: %s\n", approved ? "Yes" : "No");
    
CLEANUP:
    MEM_free(category);
    return status;
}
```

```java
// SOA 中访问 BMIDE 扩展属性
import com.teamcenter.services.core.DataManagementService;

public void accessBMIDEProperties(ModelObject item) {
    DataManagementService dmService = ...;
    
    // 获取扩展属性
    dmService.getProperties(
        new ModelObject[]{item},
        new String[]{
            "acme_part_category",
            "acme_weight_kg",
            "acme_approved"
        }
    );
    
    try {
        String category = item.getPropertyObject("acme_part_category").getStringValue();
        double weight = item.getPropertyObject("acme_weight_kg").getDoubleValue();
        boolean approved = item.getPropertyObject("acme_approved").getBoolValue();
        
        System.out.println("Category: " + category);
        System.out.println("Weight: " + weight + " kg");
        System.out.println("Approved: " + approved);
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

## Teamcenter 13 BMIDE 新特性

### 1. 增强的属性类型
- 支持更复杂的数组类型
- 改进的日期/时间处理
- 增强的引用属性

### 2. 规则引擎增强
- 支持更复杂的条件表达式
- 新增规则类型
- 性能优化

### 3. 部署改进
- 支持热部署（部分更改）
- 改进的冲突检测
- 更好的版本控制集成

## 最佳实践

1. **命名规范**
   - 使用公司前缀（如 `ACME_`）避免命名冲突
   - 属性名使用小写加下划线
   - 类型名使用 PascalCase

2. **属性设计**
   - 合理设置字符串长度
   - 使用 LOV 限制输入值
   - 考虑属性是否可搜索

3. **规则设计**
   - 规则条件尽量简单
   - 提供清晰的错误消息
   - 避免过度复杂的验证

4. **部署管理**
   - 在测试环境充分验证
   - 备份现有数据模型
   - 记录所有更改
