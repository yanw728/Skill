# Skill — 跨平台 AI Skill 管理仓库

一句话说明：**把你写给 AI 的"自定义指令"统一管理起来，让同一套规则能在 Claude、OpenClaw、GPT 三个平台上复用。**

---

## 这是什么？

当你用 AI 聊天时，经常需要告诉它"按照某种格式输出"、"遵循某些规则"——这些指令就叫 **Skill**。

问题是：你可能同时在用 Claude、OpenClaw、GPT，每个平台的加载方式不一样。如果每个平台单独维护一份指令，改一处就要同步改三处。

这个仓库解决的就是这件事：

- **写一次核心逻辑**（`SKILL.md`）
- **按平台做轻量适配**（`adapters/`）
- **用脚本自动组装**（`scripts/`）

## 仓库结构一览

```
Skill/
├── README.md              ← 你正在看的文件
│
├── skills/
│   ├── my/                ← 你自己写的 skill
│   │   └── 每个 skill 一个文件夹/
│   │       ├── SKILL.md          核心逻辑（平台无关）
│   │       ├── meta.yaml         身份信息（名称、标签、适用平台等）
│   │       ├── adapters/         平台适配文件（可选）
│   │       │   ├── claude.md         Claude 专用补丁
│   │       │   ├── openclaw.yaml     OpenClaw frontmatter
│   │       │   └── gpt.md           GPT 精简版
│   │       └── references/       参考资料（可选）
│   │
│   └── vendor/            ← 从别人那里引入的 skill
│       └── {作者}--{名称}/
│           ├── SKILL.md          原始文件（不修改）
│           ├── meta.yaml         来源、版本、许可证
│           └── adapters/         你的适配层（如有）
│
├── scripts/               ← 自动化脚本
│   ├── build-claude.sh       组装 Claude 版本
│   ├── build-openclaw.sh     组装 OpenClaw 版本
│   ├── build-gpt.sh          组装 GPT 版本
│   └── sync-vendor.sh        从 GitHub/ClawHub 拉取第三方 skill 更新
│
└── dist/                  ← 构建产物（自动生成，不用手动编辑）
    ├── claude/
    ├── openclaw/
    └── gpt/
```

## 现有 Skill 列表

### 我自己写的（`skills/my/`）

| Skill | 用途 | 适用平台 |
|-------|------|----------|
| [conversation-distill](skills/my/conversation-distill/) | 把 AI 对话提炼成 Obsidian 笔记，提取认知过程和知识增量 | Claude |
| [defuddle](skills/my/defuddle/) | 用 Defuddle CLI 从网页提取干净的 Markdown 内容，省 token | Claude |
| [obsidian-bases](skills/my/obsidian-bases/) | 创建和编辑 Obsidian Bases（.base 文件），做笔记的数据库视图 | Claude |
| [obsidian-writing](skills/my/obsidian-writing/) | 生成规范化的 Obsidian Markdown 笔记，是所有 .md 输出的格式权威 | Claude |
| [vault-cleanup](skills/my/vault-cleanup/) | 全库知识图谱标准化：统一标签、重建双链、规范 frontmatter | Claude |

### 第三方引入的（`skills/vendor/`）

暂无。使用 `scripts/sync-vendor.sh` 可以从 GitHub 或 ClawHub 引入。

## 三个平台有什么不同？

| | Claude | OpenClaw | GPT |
|---|---|---|---|
| 核心文件 | `SKILL.md` | `SKILL.md` | 纯文本 |
| 元数据 | 无 frontmatter，靠外部 description | YAML frontmatter（name, description, requires 等） | 无结构化元数据 |
| 怎么加载 | 挂载到 `/mnt/skills/`，系统自动注入 | workspace → 用户目录 → 内置，按优先级覆盖 | 手动粘贴到 Custom Instructions |
| 生态 | 无公开 registry | ClawHub（2,800+ skills） | GPT Store（不可导出） |
| 辅助文件 | 可附带脚本和参考文件 | 可附带脚本、配置 | 不支持 |

**好消息**：三个平台的核心载体都是纯文本指令。核心逻辑大约 70-80% 可以直接复用，需要适配的主要是：

- **Claude**：善用 XML 标签做结构化指令，支持 `{baseDir}` 路径引用
- **OpenClaw**：需要 YAML frontmatter 声明 `requires`（依赖），`description` 要写成用户实际会说的话（用于 skill 匹配）
- **GPT**：受 Custom Instructions 长度限制，通常需要精简版；不支持文件引用

## 怎么用？

### 添加一个新 Skill

1. 在 `skills/my/` 下新建文件夹，例如 `skills/my/my-new-skill/`
2. 创建 `SKILL.md`——写平台无关的核心逻辑
3. 创建 `meta.yaml`——填写名称、标签、适用平台（参考下面的模板）
4. 如果需要多平台，在 `adapters/` 下放各平台的适配文件

### 引入第三方 Skill

1. 在 `skills/vendor/` 下新建文件夹，命名为 `{作者}--{skill 名称}`
2. 把原始 `SKILL.md` 放进去（保持原样不修改）
3. 创建 `meta.yaml` 记录来源和版本
4. 如果需要适配，在 `adapters/` 下加你自己的适配文件

### 构建平台特定版本

```bash
# 组装 Claude 版本 → 输出到 dist/claude/
bash scripts/build-claude.sh

# 组装 OpenClaw 版本 → 输出到 dist/openclaw/
bash scripts/build-openclaw.sh

# 组装 GPT 精简版 → 输出到 dist/gpt/
bash scripts/build-gpt.sh
```

### 同步第三方 Skill 更新

```bash
bash scripts/sync-vendor.sh
```

## meta.yaml 模板

每个 Skill 文件夹里的 `meta.yaml` 长这样：

```yaml
name: skill-name              # Skill 名称（英文，用连字符分隔）
description: 一句话描述        # 人话，说清楚这个 skill 干什么
author: your-name             # 作者
source: local                 # 来源：local / GitHub URL / clawhub://skill-name
version: v1.0.0               # 版本号
license: MIT                  # 许可证（第三方 skill 请注明）
platforms: [claude]           # 适用平台：claude / openclaw / gpt
tags: [obsidian, writing]     # 分类标签
last_synced: 2026-03-25       # 最后同步日期（第三方 skill 用）
```

## 常见问题

**Q: 我只用 Claude，需要做适配吗？**
不需要。直接在 `SKILL.md` 里写就行，`adapters/` 是可选的。

**Q: `dist/` 目录需要提交到 Git 吗？**
不需要，它已经在 `.gitignore` 里了。每次用脚本构建会自动生成。

**Q: vendor 目录里的 SKILL.md 能改吗？**
建议不改。如果需要定制，在 `adapters/` 里加你的修改，脚本构建时会自动合并。这样上游更新时不会冲突。
