# Settings 配置目录

## 说明

本目录存放Kiro工作区级别的配置文件。

## 文件清单

| 文件 | 功能 | 说明 |
|------|------|------|
| `mcp.json` | MCP服务器配置 | 定义Agent可连接的外部数据源（数据库、API等） |

## MCP配置说明

当前配置的MCP服务器：

| 服务器名 | 类型 | 用途 | 状态 |
|----------|------|------|------|
| postgres | 本地命令 | PostgreSQL本地数据库 | 启用 |

## 配置优先级

```
用户级配置（~/.kiro/settings/mcp.json）
    ↓ 被覆盖
工作区配置（.kiro/settings/mcp.json）← 本文件
```

## 注意事项

- 修改mcp.json后，MCP服务器会自动重连
- 敏感信息（密码、Token）存储在此文件中，注意不要提交到公共仓库
- 如需添加新的MCP服务器，直接编辑mcp.json的mcpServers对象
