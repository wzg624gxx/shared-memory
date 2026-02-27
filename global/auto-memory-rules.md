---
inclusion: always
---

## 自动记忆系统规则

本项目启用了自动记忆系统。以下规则在所有会话中始终生效。

### 经验识别规则

在工作过程中，遇到以下情况时必须记录经验：

1. **Bug 修复**：修复了一个 bug 并找到根因时，记录根因和修复方法
2. **多次尝试**：经过 2 次以上失败尝试才找到正确方案时，记录最终方案和失败方案
3. **项目约定**：发现代码中需要遵循的约定（构建步骤、命名规范、配置要求）时，记录为项目规则
4. **技术陷阱**：在某个 API、框架、工具链中发现非显而易见的用法或陷阱时，记录为领域笔记

### 经验分类规则

- **Project_Rule**（项目规则）：适用于整个项目的通用约定 → 写入 `.kiro/steering/project-rules.md`
- **Domain_Note**（领域笔记）：针对特定技术领域的经验 → 写入 `.kiro/steering/domain-{领域名}.md`

### 记录格式

每条经验使用以下 markdown 格式：

```
## 标题

**来源**: 在什么场景下发现的
**问题**: 遇到了什么问题
**方案**: 最终的解决方案
**失败方案**: （如有）尝试过但无效的方案
```

### 去重规则

- 写入前先检查目标文件中是否已有相同标题的条目
- 如果已有相同经验，更新内容而非重复创建
- 如果内容完全一致，跳过不写

### 通用经验同步规则

判断经验的适用范围：
- 如果经验涉及项目特有的路径、配置、业务逻辑 → 仅记录到本项目
- 如果经验涉及通用技术知识（框架用法、API 陷阱、工具链技巧）→ 同时复制到团队共享路径

团队共享 Git 仓库：`https://github.com/wzg624gxx/shared-memory`
本地 clone 路径：`D:\shared-memory-test`（同事需要 clone 到相同路径，或修改 hooks 中的路径）

### 项目类型自动识别规则

根据项目特征文件自动判断项目类型（profile）：
- 包含 `pom.xml` 且有 teamcenter 相关依赖 → `teamcenter-rac`
- 包含 `pom.xml` 且有 spring-boot 相关依赖 → `springboot-api`
- 包含 `package.json` 且有 react 依赖 → `react-frontend`
- 包含 `package.json` 且有 vue 依赖 → `vue-frontend`
- 包含 `build.gradle` → `gradle-java`
- 其他 → `generic`
