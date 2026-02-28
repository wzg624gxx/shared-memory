---
inclusion: always
type: domain_note
domain: rac-plugin
lastUpdated: "2026-02-28"
---

# RAC 插件开发经验

## asyncExec中必须catch Throwable而非Exception

**来源**: RAC菜单handler点击无反应的bug修复
**问题**: `Display.getDefault().asyncExec()`中的Runnable如果抛出`Error`（如`NoClassDefFoundError`），`catch(Exception)`捕获不到，导致UI线程静默吞掉异常，用户看到的现象是"点击菜单没反应"
**方案**: RAC handler中的asyncExec/syncExec内部必须用`catch(Throwable)`，不能只catch Exception。Error级别的异常（ClassNotFound、NoClassDefFound、LinkageError等）在插件环境中很常见。
```java
Display.getDefault().asyncExec(new Runnable() {
    public void run() {
        try {
            // 业务逻辑
        } catch (Throwable e) {  // 不是 Exception!
            showMessage("异常", e.getClass().getName() + ": " + e.getMessage(), SWT.ICON_ERROR);
        }
    }
});
```

## OSGi缓存必须清除才能加载新插件

**来源**: 部署新JAR后菜单不显示
**问题**: 替换plugins目录下的JAR后，RAC仍然加载旧版本的bundle
**方案**: 每次部署新JAR后，必须删除以下OSGi缓存目录再重启RAC:
- `{RAC_WORKSPACE}/org.eclipse.osgi/`
- `{RAC_WORKSPACE}/org.eclipse.update/`
这是因为RAC使用`org.eclipse.update.configurator`发现插件，缓存了bundle的元数据。

## Bundle-ClassPath中的外部JAR路径问题

**来源**: NoClassDefFoundError排查
**问题**: MANIFEST.MF中`Bundle-ClassPath`引用的JAR（如`classes12_1.0.0.jar`）使用相对路径，OSGi会在bundle安装位置（plugins目录）下查找这些JAR，而不是在源码目录下
**方案**: 
- 方案A: 将依赖JAR打包进plugin JAR内部（推荐）
- 方案B: 将依赖JAR复制到plugins目录下
- 方案C: 代码中对外部依赖做防御性编程，用NoClassDefFoundError保护
当前项目采用方案C作为临时方案。

## RAC获取TCSession的正确API

**来源**: 编译错误修复
**问题**: TC12 RAC中获取session的API与文档示例不同
**方案**: 正确写法是 `AIFUtility.getCurrentApplication().getSession()`，不是 `AIFUtility.getDefaultDesktop().getSession()`。需要import `com.teamcenter.rac.aifrcp.AIFUtility`。

## RAC插件配置发现机制

**来源**: 排查菜单不显示时的架构分析
**问题**: 不确定RAC用哪种机制发现插件
**方案**: RAC使用`org.eclipse.update.configurator`（不是simpleconfigurator）。在`config.ini`中可以看到`org.eclipse.update.configurator@3:start`。这意味着它会扫描plugins目录下所有JAR，不需要额外的bundles.info配置文件。

## plugin.xml中菜单visibleWhen的definitionId

**来源**: 分析现有plugin.xml中的菜单配置
**问题**: 菜单项需要在特定视图/透视图中才可见
**方案**: 常用的definitionId:
- `com.teamcenter.rac.ui.inMainPerspective` — 主透视图中可见
- `com.teamcenter.rac.pse.inMainView` — PSE（产品结构编辑器）中可见
集成测试菜单建议使用`inMainPerspective`，确保在主界面就能看到。

## RAC日志位置

**来源**: 调试handler异常
**问题**: 需要查看RAC运行时的错误日志
**方案**: 
- TC日志: `{RAC_WORKSPACE}/Plmadmin_TcRAC_{timestamp}.log`
- Eclipse日志: `{RAC_WORKSPACE}/.metadata/.log`
- Eclipse日志包含更详细的堆栈信息，是排查handler问题的首选
