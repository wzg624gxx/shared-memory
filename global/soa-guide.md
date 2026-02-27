# SOA 服务开发指南

## 概述

Teamcenter SOA (Service-Oriented Architecture) 是 Teamcenter 13 推荐的远程访问方式，支持 HTTP/HTTPS 协议，适用于防火墙环境和跨平台应用。

## 核心服务模块

| 服务模块 | 命名空间 | 主要功能 |
|---------|---------|---------|
| Core | `com.teamcenter.soa.client.model.Core` | 核心对象操作 |
| Query | `com.teamcenter.services.query` | 查询服务 |
| CAD | `com.teamcenter.services.cad` | CAD 集成 |
| Workflow | `com.teamcenter.services.workflow` | 工作流 |
| Admin | `com.teamcenter.services.administration` | 管理功能 |

## 项目初始化

### Gradle 配置 (build.gradle)

```gradle
dependencies {
    // Teamcenter 13 SOA 客户端库
    implementation files("${System.getenv('TC_ROOT')}/soa_client.jar")
    implementation files("${System.getenv('TC_ROOT')}/tcserver.jar")
    
    // 其他依赖
    implementation 'com.google.code.gson:gson:2.8.9'
}
```

### 连接配置

```java
import com.teamcenter.soa.client.Connection;
import com.teamcenter.soa.client.model.strong.User;

public class TcConnection {
    private static final String TC_URL = "http://tcserver:8080/tc";
    private static final String TC_USER = "infodba";
    private static final String TC_PASSWORD = "infodba";
    
    public Connection connect() throws Exception {
        Connection connection = new Connection(
            TC_URL, 
            new HttpPostRequestHandler(),
            new MyExceptionHandler(),
            new MyPartialErrorHandler()
        );
        
        // 登录
        Credentials credentials = new Credentials(TC_USER, TC_PASSWORD);
        SessionService sessionService = SessionService.getService(connection);
        LoginResponse response = sessionService.login(
            "Teamcenter", 
            credentials, 
            "", 
            "", 
            "", 
            new String[]{}
        );
        
        return connection;
    }
}
```

## 标准操作模板

### 1. 创建 Item

```java
import com.teamcenter.services.core.DataManagementService;
import com.teamcenter.services.core._2006_03.DataManagement.CreateItemsResponse;
import com.teamcenter.soa.client.model.strong.Item;
import com.teamcenter.soa.client.model.strong.ItemRevision;

public class ItemService {
    private DataManagementService dmService;
    
    public ItemService(Connection connection) {
        this.dmService = DataManagementService.getService(connection);
    }
    
    /**
     * 创建零组件
     * @param itemId 零组件 ID
     * @param itemName 零组件名称
     * @param itemType 零组件类型 (如 "Item", "Part", "Document")
     * @param itemRevId 版本 ID (如 "A", "001")
     * @return 创建的 Item 和 ItemRevision
     */
    public CreateItemsResponse createItem(
            String itemId, 
            String itemName, 
            String itemType,
            String itemRevId) {
        
        // 创建 Item 属性
        ItemProperties itemProps = new ItemProperties();
        itemProps.itemId = itemId;
        itemProps.name = itemName;
        itemProps.type = itemType;
        itemProps.description = "";
        itemProps.revId = itemRevId;
        
        // 调用服务创建
        CreateItemsResponse response = dmService.createItems(
            new ItemProperties[]{itemProps}, 
            null, 
            ""
        );
        
        // 检查错误
        if (response.serviceData.sizeOfPartialErrors() > 0) {
            throw new RuntimeException("创建失败: " + 
                response.serviceData.getPartialError(0).getMessages()[0]);
        }
        
        return response;
    }
}
```

### 2. 查询对象

```java
import com.teamcenter.services.query.SavedQueryService;
import com.teamcenter.services.query._2006_03.SavedQuery.GetSavedQueriesResponse;
import com.teamcenter.services.query._2007_06.SavedQuery.SavedQueriesResponse;
import com.teamcenter.services.query._2007_06.SavedQuery.QueryInput;

public class QueryService {
    private SavedQueryService queryService;
    
    public QueryService(Connection connection) {
        this.queryService = SavedQueryService.getService(connection);
    }
    
    /**
     * 执行已保存查询
     * @param queryName 查询名称 (如 "Item...", "General...")
     * @param entries 查询字段名数组
     * @param values 查询值数组
     * @return 查询结果对象数组
     */
    public ModelObject[] executeSavedQuery(
            String queryName,
            String[] entries,
            String[] values) {
        
        // 获取所有已保存查询
        GetSavedQueriesResponse savedQueries = queryService.getSavedQueries();
        
        // 查找指定查询
        SavedQuery query = null;
        for (SavedQuery sq : savedQueries.queries) {
            if (sq.get_name().equals(queryName)) {
                query = sq;
                break;
            }
        }
        
        if (query == null) {
            throw new RuntimeException("查询不存在: " + queryName);
        }
        
        // 构建查询输入
        QueryInput[] inputs = new QueryInput[1];
        inputs[0] = new QueryInput();
        inputs[0].query = query;
        inputs[0].entries = entries;
        inputs[0].values = values;
        
        // 执行查询
        SavedQueriesResponse response = queryService.executeSavedQueries(inputs);
        
        if (response.arrayOfResults.length > 0) {
            return response.arrayOfResults[0].objects;
        }
        
        return new ModelObject[0];
    }
    
    /**
     * 按 Item ID 查询
     */
    public Item findItemById(String itemId) {
        ModelObject[] results = executeSavedQuery(
            "Item...",
            new String[]{"Item ID"},
            new String[]{itemId}
        );
        
        if (results.length > 0 && results[0] instanceof Item) {
            return (Item) results[0];
        }
        
        return null;
    }
}
```

### 3. 属性操作

```java
import com.teamcenter.services.core.DataManagementService;
import com.teamcenter.soa.client.model.Property;

public class PropertyService {
    private DataManagementService dmService;
    
    /**
     * 读取对象属性
     * @param object 目标对象
     * @param propertyName 属性名
     * @return 属性值
     */
    public String getProperty(ModelObject object, String propertyName) {
        // 确保属性已加载
        dmService.getProperties(
            new ModelObject[]{object}, 
            new String[]{propertyName}
        );
        
        try {
            Property prop = object.getPropertyObject(propertyName);
            return prop.getStringValue();
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * 设置对象属性
     * @param object 目标对象
     * @param propertyName 属性名
     * @param value 属性值
     */
    public void setProperty(ModelObject object, String propertyName, String value) {
        dmService.setProperties(
            new ModelObject[]{object},
            new String[]{propertyName},
            new String[]{value}
        );
        
        // 保存更改
        dmService.saveObjects(new ModelObject[]{object}, null);
    }
}
```

### 4. BOM 操作

```java
import com.teamcenter.services.cad.StructureManagementService;
import com.teamcenter.services.cad._2007_01.StructureManagement.CreateBOMWindowsResponse;
import com.teamcenter.soa.client.model.strong.BOMLine;
import com.teamcenter.soa.client.model.strong.BOMWindow;

public class BOMService {
    private StructureManagementService structureService;
    private DataManagementService dmService;
    
    public BOMService(Connection connection) {
        this.structureService = StructureManagementService.getService(connection);
        this.dmService = DataManagementService.getService(connection);
    }
    
    /**
     * 打开 BOM 窗口
     * @param itemRev 根节点 ItemRevision
     * @return BOMWindow
     */
    public BOMWindow openBOMWindow(ItemRevision itemRev) {
        BOMViewRevision bomViewRev = getLatestBOMViewRevision(itemRev);
        
        CreateBOMWindowsResponse response = 
            structureService.createBOMWindows(
                new ItemRevision[]{itemRev},
                new BOMViewRevision[]{bomViewRev},
                new String[]{""}
            );
        
        return response.output[0].bomWindow;
    }
    
    /**
     * 遍历 BOM 结构
     * @param bomLine 起始 BOMLine
     * @param level 当前层级
     */
    public void traverseBOM(BOMLine bomLine, int level) {
        try {
            // 获取当前行信息
            dmService.getProperties(
                new ModelObject[]{bomLine},
                new String[]{"bl_item_item_id", "bl_item_object_name", "bl_quantity"}
            );
            
            String itemId = bomLine.getPropertyObject("bl_item_item_id").getStringValue();
            String name = bomLine.getPropertyObject("bl_item_object_name").getStringValue();
            
            System.out.println("  ".repeat(level) + itemId + " - " + name);
            
            // 获取子行
            BOMLine[] children = bomLine.get_bl_child_lines();
            if (children != null) {
                for (BOMLine child : children) {
                    traverseBOM(child, level + 1);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    /**
     * 关闭 BOM 窗口
     */
    public void closeBOMWindow(BOMWindow bomWindow) {
        structureService.closeBOMWindows(new BOMWindow[]{bomWindow});
    }
}
```

### 5. 文件操作 (Dataset)

```java
import com.teamcenter.services.core.DataManagementService;
import com.teamcenter.services.core.FileManagementService;
import com.teamcenter.soa.client.model.strong.Dataset;
import com.teamcenter.soa.client.model.strong.ImanFile;

public class DatasetService {
    private DataManagementService dmService;
    private FileManagementService fileService;
    
    public DatasetService(Connection connection) {
        this.dmService = DataManagementService.getService(connection);
        this.fileService = FileManagementService.getService(connection);
    }
    
    /**
     * 创建 Dataset 并上传文件
     * @param itemRev 关联的 ItemRevision
     * @param datasetName Dataset 名称
     * @param datasetType Dataset 类型 (如 "PDF", "Text", "UGMASTER")
     * @param toolName 工具名 (如 "PDF_Reference", "Text")
     * @param localFilePath 本地文件路径
     * @return 创建的 Dataset
     */
    public Dataset createDatasetWithFile(
            ItemRevision itemRev,
            String datasetName,
            String datasetType,
            String toolName,
            String localFilePath) throws Exception {
        
        // 创建 Dataset
        DatasetProperties dsProps = new DatasetProperties();
        dsProps.name = datasetName;
        dsProps.type = datasetType;
        dsProps.description = "";
        dsProps.tool = toolName;
        dsProps.container = itemRev;
        
        CreateDatasetsResponse dsResponse = 
            dmService.createDatasets(new DatasetProperties[]{dsProps});
        
        Dataset dataset = dsResponse.output[0].dataset;
        
        // 上传文件
        File file = new File(localFilePath);
        GetFileInfoResponse fileInfo = fileService.getFileInfo(
            new String[]{file.getName()},
            new long[]{file.length()},
            new boolean[]{false}
        );
        
        // 使用 FTP/HTTP 上传文件内容
        uploadFileContent(fileInfo.tickets[0], file);
        
        return dataset;
    }
    
    /**
     * 下载 Dataset 文件
     * @param dataset 目标 Dataset
     * @param outputPath 输出路径
     */
    public void downloadDatasetFile(Dataset dataset, String outputPath) throws Exception {
        // 获取关联的 ImanFile
        dmService.getProperties(
            new ModelObject[]{dataset},
            new String[]{"ref_list"}
        );
        
        ModelObject[] refList = dataset.get_ref_list();
        if (refList.length == 0) return;
        
        ImanFile imanFile = (ImanFile) refList[0];
        
        // 获取文件票证
        GetFileToLocationResponse response = fileService.getFileToLocation(
            new ImanFile[]{imanFile},
            new String[]{outputPath},
            new boolean[]{false}
        );
        
        // 文件已下载到 outputPath
    }
}
```

## 异常处理

```java
import com.teamcenter.soa.client.model.ErrorStack;
import com.teamcenter.soa.client.model.PartialError;

public class MyExceptionHandler implements ExceptionHandler {
    @Override
    public void handleException(InternalServerException e) {
        System.err.println("服务器异常: " + e.getMessage());
        
        ErrorStack[] errorStacks = e.getErrorStacks();
        for (ErrorStack stack : errorStacks) {
            System.err.println("  错误码: " + stack.getCode());
            System.err.println("  消息: " + stack.getMessage());
        }
    }
    
    @Override
    public void handleException(CanceledOperationException e) {
        System.err.println("操作被取消: " + e.getMessage());
    }
}

public class MyPartialErrorHandler implements PartialErrorListener {
    @Override
    public void handlePartialError(ServiceData serviceData) {
        for (int i = 0; i < serviceData.sizeOfPartialErrors(); i++) {
            PartialError error = serviceData.getPartialError(i);
            System.err.println("部分错误: " + error.getErrorValues()[0].getMessage());
        }
    }
}
```

## 最佳实践

1. **连接管理**: 使用连接池或单例模式管理 Connection
2. **属性缓存**: 批量获取属性减少网络往返
3. **错误处理**: 始终检查 ServiceData 中的 partial errors
4. **资源释放**: 及时关闭 BOMWindow 等资源
5. **会话超时**: 实现自动重新登录机制
