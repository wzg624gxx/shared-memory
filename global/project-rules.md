---
inclusion: always
type: project_rules
lastUpdated: "2026-02-28"
entries: []
---

<!-- 项目级规则会自动追加到此文件 -->

## VM环境与路径约定

**来源**: 多轮部署调试中反复确认的环境信息
**问题**: 每次新会话都需要重新摸索VM路径和工具可用性
**方案**:
- VM地址: 192.168.15.131, 用户 Plmadmin, 密码 123.plm
- TC版本: Teamcenter 12 (不是13), RAC路径: `C:\Siemens\Teamcenter12\portal\`
- 插件目录: `C:\Siemens\Teamcenter12\portal\plugins\`
- 源码工作区: `C:\srcodeproject\SR\`
- 用户RAC工作区: `C:\Users\Plmadmin\Teamcenter\RAC\20220330202055\`
- VM上可用工具: javac, jar, powershell, copy, type
- VM上不可用: eclipsec.exe, ant, node, npm, maven
- SFTP支持单文件传输，不支持目录传输

## 编译流程约定

**来源**: 解决Windows CMD不展开`*.java`通配符的问题
**问题**: `javac src\com\sr\plm\handler\*.java` 在CMD中不工作
**方案**: 使用`@argfile`方式编译，将所有源文件路径写入`C:\srcodeproject\SR\sources.txt`，然后执行:
```
javac -encoding UTF-8 -d C:\srcodeproject\SR\bin -cp "C:\Siemens\Teamcenter12\portal\plugins\*;C:\srcodeproject\SR\classes12_1.0.0.jar;C:\srcodeproject\SR\fastjson-1.2.47.jar;C:\srcodeproject\SR\aliyun-sdk-oss-3.10.2.jar;C:\srcodeproject\SR\aliyun-java-sdk-core-3.4.0.jar;C:\srcodeproject\SR\jdom2-2.0.6.jar;C:\srcodeproject\SR\commons-codec-1.11.jar;C:\srcodeproject\SR\commons-logging-1.1.1.jar;C:\srcodeproject\SR\httpclient-4.5.8.jar;C:\srcodeproject\SR\httpcore-4.4.11.jar;C:\srcodeproject\SR\jettison-1.1.jar" -sourcepath C:\srcodeproject\SR\src @C:\srcodeproject\SR\sources.txt
```
**失败方案**: 直接用`*.java`通配符; `for /r`循环在SSH中转义问题

## JAR打包与部署流程

**来源**: 多次打包部署迭代
**问题**: 需要保持与原始JAR一致的MANIFEST.MF和plugin.xml
**方案**:
1. 编译: `javac ... @sources.txt`
2. 打包: `jar -cvfm C:\srcodeproject\SR\com.hh.sr.bpm_1.0.0.0.jar C:\srcodeproject\SR\META-INF\MANIFEST.MF -C C:\srcodeproject\SR\bin . -C C:\srcodeproject\SR plugin.xml`
3. 部署: `copy /Y ... C:\Siemens\Teamcenter12\portal\plugins\com.hh.sr.bpm_1.0.0.0.jar`
4. 清缓存: 删除 `org.eclipse.osgi` 和 `org.eclipse.update` 目录
5. 重启RAC

## 插件JAR命名与Bundle约定

**来源**: 排查菜单不显示问题时发现
**问题**: JAR文件名`com.hh.sr.bpm_1.0.0.0.jar`与MANIFEST.MF中`Bundle-SymbolicName: SR;singleton:=true`不一致
**方案**: 这是正常的。OSGi通过MANIFEST.MF中的Bundle-SymbolicName识别bundle，不依赖文件名。保持现有命名不变。

## 备份JAR冲突问题

**来源**: 菜单不显示的排查过程
**问题**: plugins目录下存在`com.hh.sr.bpm_1.0.0.0beifen.jar`（17MB备份），OSGi会同时加载两个bundle导致冲突
**方案**: 将备份JAR移出plugins目录到`C:\srcodeproject\SR\`。plugins目录下同一bundle只能有一个JAR。

## DBUtil外部依赖不可用

**来源**: 集成测试handler点击无反应的根因分析
**问题**: `com.hh.tools.Util.DBUtil`类不在任何已打包的JAR中，MANIFEST.MF的Bundle-ClassPath引用的外部JAR（classes12等）是相对路径，在plugins目录下找不到
**方案**: 所有使用DBUtil的代码必须用`try-catch(NoClassDefFoundError)`保护，通过包装方法`getDbConnection()`安全调用。未来如需数据库功能，需要将DBUtil所在的JAR打包进plugin JAR内部或放到plugins目录下。

## SSH命令转义注意事项

**来源**: 通过MCP execute_ssh_command执行命令时的多次失败
**问题**: `for /f`循环中的`%%`在SSH远程执行时转义不正确
**方案**: 复杂的批处理逻辑用`powershell -Command "..."`替代CMD的`for /f`循环。PowerShell的管道和ForEach-Object在SSH中工作正常。
