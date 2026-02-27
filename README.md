# 团队共享经验库

自动记忆系统的团队共享经验库。Kiro 会自动从此仓库拉取和同步经验。

## 目录结构

- `global/` - 全局通用经验（所有项目类型都适用）
- `profiles/` - 按项目类型分组的经验
  - `teamcenter-rac/` - Teamcenter RAC 插件类项目
  - `springboot-api/` - Spring Boot API 类项目
  - `react-frontend/` - React 前端类项目
  - `vue-frontend/` - Vue 前端类项目
  - `gradle-java/` - Gradle Java 类项目
  - `generic/` - 通用项目

## 工作原理

1. Kiro 新会话开始时自动 git pull 拉取最新经验
2. 工作结束后如果产生通用经验，自动同步到对应 profile 目录并 push
3. 同事 git pull 项目代码后 hooks 自动生效，无需手动配置
