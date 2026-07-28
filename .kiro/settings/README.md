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

## Multica 运行环境（重要）

在 **Multica** 下运行时，MCP 连接**不读本目录的 `mcp.json`**，而是由**运行 Agent 的 `mcp_config` / `custom_env`** 承载（`multica agent update <id> --mcp-config-file ...`，读取时脱敏）。

- 连接串/账号/口令只存于 Agent `mcp_config`，本仓库任何文件都不写连接信息。
- 更换库/主机/账号时，**只改 Agent `mcp_config` 一处**；skill、契约、steering 均无需改动。
- 本目录的 `mcp.json` 仅供 **Kiro IDE** 本地使用；两套环境互不影响。

## 注意事项

- （Kiro IDE）修改mcp.json后，MCP服务器会自动重连
- 敏感信息（密码、Token）存储在此文件中，注意不要提交到公共仓库
- 如需添加新的MCP服务器：Kiro IDE 编辑 mcp.json 的 mcpServers；Multica 改 Agent `mcp_config`
