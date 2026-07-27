# Kiro 官方文档中文版

> 翻译自 [kiro.dev/docs](https://kiro.dev/docs/)，内容经过整理和意译，非逐字翻译。
> 最后更新：2026-05-09

---

## 目录

1. [快速入门](#快速入门)
2. [Specs（规格说明）](#specs规格说明)
3. [Steering（引导规则）](#steering引导规则)
4. [Agent Skills（技能）](#agent-skills技能)
5. [Hooks（钩子/自动化）](#hooks钩子自动化)
6. [MCP（模型上下文协议）](#mcp模型上下文协议)
7. [Powers（能力包）](#powers能力包)

---

## 快速入门

Kiro 是一个 **Agent 驱动的 IDE**，通过 Specs、Steering 和 Hooks 等功能帮助你高效开发。

### 核心能力一览

| 功能 | 说明 |
|------|------|
| **Specs** | 用结构化规格说明来规划和构建功能 |
| **Hooks** | 通过智能触发器自动化重复任务 |
| **Chat** | 通过自然语言对话构建功能 |
| **Steering** | 用自定义规则和上下文引导 AI |
| **MCP** | 连接外部工具和数据源 |
| **Powers** | 一键安装的能力包（MCP + 知识 + 工作流） |

### 安装要求

- **Windows**：Windows 10/11（仅64位）
- **Linux**：glibc 2.39+（Ubuntu 24+、Debian 13+、Fedora 40+）
- **macOS**：支持

---

## Specs（规格说明）

Specs 是 Kiro 中用于**结构化规划和构建功能**的核心机制。它将开发过程分为需求、设计和实现任务三个阶段，让你在编码前先想清楚要做什么。

### 什么是 Spec？

Spec 是一组结构化文档，包含：
- **需求文档**：用 EARS 表示法（Easy Approach to Requirements Syntax）描述功能需求和验收标准
- **设计文档**：技术方案、数据流、接口设计
- **任务列表**：将实现拆分为可执行的小任务，Agent 逐个完成

### 使用场景

- 需要深入思考的复杂功能
- 需要前期规划的重构工作
- 需要理解系统行为的场景
- 多步骤的实现任务

### 如何创建 Spec

1. 打开命令面板，搜索 "Kiro: Create Spec"
2. 或在 `.kiro/specs/` 目录下手动创建
3. 描述你要构建的功能，Kiro 会生成需求和设计文档
4. 确认后，Kiro 生成任务列表并逐步执行

### Spec 文件结构

```
.kiro/specs/{spec-name}/
├── requirements.md    # 需求文档（EARS表示法）
├── design.md          # 技术设计文档
└── tasks.md           # 实现任务列表（可勾选）
```

### 引用外部文件

Spec 文件中可以通过 `#[[file:相对路径]]` 引用其他文件（如 OpenAPI spec、GraphQL schema），让这些文档影响实现过程。

---

## Steering（引导规则）

Steering 通过 Markdown 文件为 Kiro 提供**持久化的工作区知识**。不用每次对话都重复解释你的规范，Steering 文件确保 Kiro 始终遵循你的模式、库和标准。

### 文件位置

- **工作区级别**：`.kiro/steering/*.md`（仅当前项目生效）
- **用户级别**：`~/.kiro/steering/*.md`（所有项目生效）

### 三种包含模式

| 模式 | 配置方式 | 说明 |
|------|----------|------|
| **always**（默认） | 无需配置 | 每次对话都自动加载 |
| **fileMatch** | front-matter 中设置 `inclusion: fileMatch` + `fileMatchPattern` | 当匹配的文件被读入上下文时加载 |
| **manual** | front-matter 中设置 `inclusion: manual` | 用户通过 `#` 手动引用时加载 |

### fileMatch 示例

```markdown
---
inclusion: fileMatch
fileMatchPattern: "**/*.sql"
---

# SQL 编码规范
所有SQL关键字必须大写...
```

当任何 `.sql` 文件被读入上下文时，这个规则会自动生效。

### 最佳实践

- 团队规范、编码标准 → always 模式
- 特定文件类型的规则 → fileMatch 模式
- 偶尔需要的参考信息 → manual 模式
- 支持 `#[[file:相对路径]]` 引用其他文件

---

## Agent Skills（技能）

Skills 是一种**按需加载的上下文指令**，让 Agent 在需要时获取特定领域的详细指导，而不是每次都加载所有信息。

### 文件位置

- **工作区级别**：`.kiro/skills/*.md`
- **用户级别**：`~/.kiro/skills/*.md`

### 与 Steering 的区别

| 特性 | Steering | Skills |
|------|----------|--------|
| 加载方式 | 自动/条件/手动 | 按需激活 |
| 用途 | 持久化规范和知识 | 特定任务的详细指导 |
| 上下文占用 | 始终占用（always模式） | 仅激活时占用 |
| 适合场景 | 团队规范、编码标准 | 复杂工作流、特定操作指南 |

### 使用方式

在对话中通过 `#` 引用 Skill 名称即可激活，Agent 会加载该 Skill 的完整指令到上下文中。

### 示例 Skill

```markdown
# SQL Review Skill

当用户请求审查SQL时，按以下步骤执行：
1. 检查SQL语法是否兼容目标数据库
2. 验证命名规范
3. 检查性能问题
4. 输出审查报告
```

---

## Hooks（钩子/自动化）

Hooks 将 IDE 事件映射到 Agent 动作，实现**自动化工作流**。当特定事件发生时，自动触发预定义的操作。

### 文件位置

`.kiro/hooks/*.kiro.hook`（JSON 格式）

### 支持的事件类型

| 事件类型 | 触发时机 |
|----------|----------|
| `fileEdited` | 用户保存文件时 |
| `fileCreated` | 创建新文件时 |
| `fileDeleted` | 删除文件时 |
| `promptSubmit` | 发送消息给 Agent 时 |
| `agentStop` | Agent 执行完成时 |
| `preToolUse` | 工具执行前 |
| `postToolUse` | 工具执行后 |
| `preTaskExecution` | Spec 任务开始前 |
| `postTaskExecution` | Spec 任务完成后 |
| `userTriggered` | 用户手动触发 |

### 支持的动作类型

| 动作 | 说明 |
|------|------|
| `askAgent` | 向 Agent 发送提示消息 |
| `runCommand` | 执行 Shell 命令 |

### Hook 文件格式

```json
{
  "name": "Hook名称",
  "version": "1.0.0",
  "description": "Hook描述",
  "when": {
    "type": "事件类型",
    "patterns": ["文件匹配模式"],
    "toolTypes": ["工具类型/正则"]
  },
  "then": {
    "type": "askAgent 或 runCommand",
    "prompt": "Agent提示（askAgent时必填）",
    "command": "Shell命令（runCommand时必填）"
  }
}
```

### 常见用例

- 保存 `.ts` 文件时自动运行 lint
- SQL 文件修改后自动更新血缘文档
- Spec 任务完成后自动运行测试
- 写入操作前检查编码规范

### 创建方式

1. 命令面板搜索 "Open Kiro Hook UI"
2. 或在 `.kiro/hooks/` 目录下手动创建 `.kiro.hook` 文件
3. 或在对话中让 Kiro 帮你创建

---

## MCP（模型上下文协议）

MCP（Model Context Protocol）让 Kiro 能够**连接外部工具和数据源**，扩展 Agent 的能力边界。

### 配置文件位置

- **工作区级别**：`.kiro/settings/mcp.json`
- **用户级别**：`~/.kiro/settings/mcp.json`
- 优先级：用户配置 < 工作区配置（工作区覆盖用户级）

### 配置格式

```json
{
  "mcpServers": {
    "服务器名称": {
      "command": "启动命令",
      "args": ["参数列表"],
      "env": {
        "环境变量": "值"
      },
      "disabled": false,
      "autoApprove": ["自动批准的工具名"]
    }
  }
}
```

### 常用 MCP Server

| Server | 用途 | 启动命令 |
|--------|------|----------|
| PostgreSQL | 数据库查询 | `npx @modelcontextprotocol/server-postgres` |
| AWS Docs | AWS文档查询 | `uvx awslabs.aws-documentation-mcp-server@latest` |
| Filesystem | 文件系统操作 | `npx @modelcontextprotocol/server-filesystem` |

### 安装依赖

大多数 MCP Server 通过 `uvx` 运行（Python 的 uv 包管理器）：
- 安装 uv：参考 [https://docs.astral.sh/uv/getting-started/installation/](https://docs.astral.sh/uv/getting-started/installation/)
- 安装后 `uvx` 会自动下载并运行 Server，无需单独安装每个包

### 管理方式

- 命令面板搜索 "MCP" 查看相关命令
- 修改配置文件后 Server 自动重连
- 也可从 MCP Server 视图手动重连

---

## Powers（能力包）

Powers 是 Kiro 的**一键安装能力包**，将文档、工作流指南和 MCP Server 打包在一起，提供开箱即用的领域能力。

### Powers 包含什么

| 组成部分 | 说明 |
|----------|------|
| **POWER.md** | 能力包文档（使用说明） |
| **MCP Servers** | 提供工具能力的后端服务 |
| **Steering Files** | 工作流引导文件 |

### 使用流程

1. **安装**：命令面板搜索 Powers，或在 Powers 面板中浏览安装
2. **激活**：使用前先激活（获取文档、工具列表、参数格式）
3. **使用**：通过对话调用 Power 提供的工具
4. **阅读指南**：查看 Steering 文件获取详细工作流指导

### 与 MCP 的关系

Powers 是 MCP 的上层封装：
- **MCP**：底层协议，需要手动配置 Server
- **Powers**：打包好的能力包，一键安装，包含文档和最佳实践

### 管理方式

- 命令面板搜索 "Powers" 打开管理面板
- 浏览、安装、卸载能力包
- 查看已安装 Powers 的工具列表

---

## 附录：常用命令面板操作

| 命令 | 功能 |
|------|------|
| Kiro: Create Spec | 创建新的 Spec |
| Kiro: Open Hook UI | 打开 Hook 管理界面 |
| Kiro: Powers | 打开 Powers 管理面板 |
| Kiro: MCP Servers | 查看 MCP Server 状态 |

---

## 附录：文件结构总览

```
.kiro/
├── steering/          # 引导规则（always/fileMatch/manual）
│   └── *.md
├── skills/            # Agent 技能（按需激活）
│   └── *.md
├── hooks/             # 自动化钩子
│   └── *.kiro.hook
├── settings/
│   └── mcp.json       # MCP 配置
├── specs/             # 规格说明
│   └── {spec-name}/
│       ├── requirements.md
│       ├── design.md
│       └── tasks.md
└── data/              # 数据文件（自定义）
```

---

> 💡 **提示**：Kiro 的对话支持中文，你可以直接用中文描述需求，Agent 会自动用中文回复。所有功能（Specs、Hooks、Steering 等）的内容也可以用中文编写。
