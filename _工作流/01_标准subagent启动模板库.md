# 标准 subagent 启动模板库

> 用途：说明本项目可直接复制使用的隔离式临时 subagent 模板如何组织、命名和复用。具体 subagent 文件统一放在 `_工作流/03_subagents/`。
>
> **开一篇新文章怎么按顺序调用这些 agent**：见 [`02_单篇文章从0到HTML成稿执行手册.md`](02_单篇文章从0到HTML成稿执行手册.md)。

---

## 一、使用规则

1. 每个模板都是“开箱可用”的临时 subagent 提示词。
2. 使用时复制对应 `.md` 文件，把【占位符】替换为当前文章信息。
3. 每次启动 subagent 都应视为一次隔离任务：只给当前阶段必要文件，不给其他文章材料。
4. 审阅、评估类 subagent 不放具体内容示例，避免污染判断。
5. 生成类、格式类 subagent 可以给功能性示例。
6. subagent 只完成当前任务，不主动推进下一阶段。

---

## 二、通用 frontmatter 规范

每个可落地为 `.cursor/agents/*.md` 的 subagent 文件，建议使用以下 frontmatter：

```yaml
---
name: agent-name-in-kebab-case
description: 一句话说明这个 subagent 做什么，以及什么时候使用。
model: inherit
---
```

说明：

- `name`：小写英文、数字和连字符。
- `description`：说明 WHAT + WHEN。
- `model`：如无特殊模型要求，使用 `inherit`；如以后指定 MiniMax 或其他模型，再写具体模型名。

---

## 三、通用隔离规则

所有内容生产 subagent 都必须遵守：

1. 只处理当前任务。
2. 只使用用户明确提供或任务中列出的文件。
3. 不引用其他文章、其他项目、其他历史对话。
4. 不把同系列其他文章的事实、机制、标题、结构带入本文。
5. 不引入未核事实。
6. 材料不足时写“待补资料”，不得编造。
7. 不输出当前阶段之外的产物。
8. 不用泛泛意见代替具体判断。

---

## 四、推荐文件命名

具体模板文件放在：

```text
_工作流/03_subagents/
```

如果要复制到某个新项目中作为 Cursor agent 使用，建议复制到：

```text
.cursor/agents/
```

命名示例：

```text
content-project-architect.md
content-researcher.md
content-evidence-ledger.md
content-fact-checker.md
content-content-ecosystem-analyst.md
content-insight-selector.md
content-communication-criteria.md
content-communication-analyst.md
content-structure-criteria.md
content-structure-analyst.md
content-style-guide.md
content-direction-director.md
content-reader-criteria.md
content-outline-planner.md
content-outline-reviewer.md
content-draft-writer.md
content-reader-reviewer.md
content-chief-editor.md
content-revision-writer.md
content-release-checker.md
content-title-strategist.md
content-illustration-planner.md
content-html-producer.md
```

### 功能词定义

| 功能词 | 含义 | 典型产物 |
|---|---|---|
| `architect` | 项目初始化 | README、总计划、目录结构 |
| `researcher` / `ledger` / `fact-checker` | 资料研究、证据整理、事实核查 | 资料.md、证据台账.md、事实核查清单.md |
| `criteria` | 生成评估标准 / 审查卡，不执行评分或审读 | 传播学审查卡、结构命题审查卡、读者审稿卡 |
| `analyst` | 按已有标准做分析、评分、排序 | 传播学分析卡、结构命题分析卡、外部内容搜索 |
| `selector` | 从材料中初选候选，不做最终定稿 | 洞察及主题初选 |
| `director` | 方向统筹、取舍、洞察组合编排 | 方向把控 |
| `guide` | 生成本文专属写作指导 | 文风卡 |
| `planner` | 生成方案或结构施工图 | 大纲、插图方案 |
| `reviewer` | 对已有产物做审阅，输出修改意见 | 大纲审阅、读者审读、内容密度审读、主编修改建议 |
| `writer` | 写正文或修订稿 | 草稿、修订稿 |
| `checker` | 发布前检查 | 发布检查（内容闭环）、成稿终审（格式） |
| `strategist` | 策略分析与候选生成 | 标题生态搜索、标题方案 |
| `producer` | 生成最终格式化交付物 | HTML 终稿 |

### 旧名 → 新名对照

| 旧文件名 | 新文件名 | 改名原因 |
|---|---|---|
| `content-external-search-analyst.md` | `content-content-ecosystem-analyst.md` | 不只搜索，而是分析外部内容生态 |
| `content-insight-editor.md` | `content-insight-selector.md` | 做洞察初选，不是普通编辑 |
| `content-communication-reviewer.md` | `content-communication-criteria.md` | 生成标准，不是执行审读 |
| `content-structure-reviewer.md` | `content-structure-criteria.md` | 生成标准，不是执行审读 |
| `content-direction-editor.md` | `content-direction-director.md` | 做方向统筹，不是普通编辑 |
| `content-style-card-editor.md` | `content-style-guide.md` | 产物是文风卡，guide 更自然 |
| `content-outline-editor.md` | `content-outline-planner.md` | 生成结构施工图，不是泛泛编辑 |
| `content-reader-review-card.md` | `content-reader-criteria.md` | 生成读者审读标准 |
| `content-title-editor.md` | `content-title-strategist.md` | 含标题生态、分析、审查 |
| `content-image-planner.md` | `content-illustration-planner.md` | 避免误解为处理图片文件 |

---

# 五、标准 subagent 启动模板

具体 subagent 模板不再内嵌在本文件中，统一拆分到：

```text
_工作流/03_subagents/
```

这样后续可以直接把该文件夹复制到新项目的 `.cursor/agents/` 或其他 agent 配置目录中使用。

## 当前模板清单

| 编号 | 文件 | 角色 | 用途 | 状态 |
|---|---|---|---|---|
| 01 | `_工作流/03_subagents/00-project-setup.md` | 项目初始化 | 新文章项目初始化，生成 README.md、总计划.md、00_目录结构.md 和目录方案 | 已完成 |
| 02 | `_工作流/03_subagents/01-source-research.md` | 资料研究 | 生成 `01_资料/资料.md` | 已完成 |
| 03 | `_工作流/03_subagents/01-evidence-ledger.md` | 证据台账 | 生成 `01_资料/证据台账.md` | 已完成 |
| 04 | `_工作流/03_subagents/01-fact-check.md` | 事实检查 | 生成 `01_资料/事实核查清单.md` | 已完成 |
| 05 | `_工作流/03_subagents/02-ecosystem-scan.md` | 生态扫描 | 分析同题内容、常见写法和可避开的套路 | 已完成 |
| 06 | `_工作流/03_subagents/02-insight-select.md` | 洞察初选 | 生成洞察及主题初选 | 已完成 |
| 07 | `_工作流/03_subagents/02-communication-criteria.md` | 传播标准 | 生成当前文章专用 `02_洞察及主题/传播学审查卡.md` | 已完成 |
| 08 | `_工作流/03_subagents/02-communication-analyze.md` | 传播分析 | 生成 `02_洞察及主题/传播学分析卡.md`，评估和排序候选洞察 | 已完成 |
| 09 | `_工作流/03_subagents/02-structure-criteria.md` | 结构标准 | 生成当前文章专用 `02_洞察及主题/结构命题审查卡.md` | 已完成 |
| 10 | `_工作流/03_subagents/02-structure-analyze.md` | 结构分析 | 生成 `02_洞察及主题/结构命题分析卡.md`，评估和排序候选结构命题 | 已完成 |
| 11 | `_工作流/03_subagents/02-direction-decide.md` | 方向决策 | 生成进入文风卡和大纲前的 `02_洞察及主题/方向把控.md` | 已完成 |
| 12 | `_工作流/03_subagents/03-style-guide.md` | 文风指导 | 基于方向把控生成文风卡 | 已完成 |
| 13 | `_工作流/03_subagents/03-outline-plan.md` | 大纲规划 | 基于方向把控、文风卡和文章结构格式配置生成大纲；根据大纲审阅修订大纲 | 已完成 |
| 14 | `_工作流/03_subagents/03-outline-review.md` | 大纲审阅 | 审阅大纲并判断是否进入草稿、修订或退回上游 | 已完成 |
| 15 | `_工作流/03_subagents/03-reader-criteria.md` | 读者标准 | 基于已通过大纲、方向把控和文风卡生成 `03_文风与大纲/读者审稿卡.md` | 已完成 |
| 16 | `_工作流/03_subagents/04-draft-write.md` | 草稿写作 | 严格按已通过大纲、读者审稿卡、文风卡和事实边界生成第一版草稿 | 已完成 |
| 17 | `_工作流/03_subagents/05-free-review.md` | 自由审稿 | 零上下文盲审大纲/草稿/修订稿，纯自由文本 | 已完成 |
| 18 | `_工作流/03_subagents/05-reader-review.md` | 读者审读 | 生成 `05_审阅/读者审读 vN.md` 或 `读者审读 阶段B vN.md` | 已完成 |
| 19 | `_工作流/03_subagents/05-density-edit.md` | 内容密度审读 | 生成 `05_审阅/内容密度审读 vN.md` 或 `内容密度审读 阶段B vN.md` | 已完成 |
| 20 | `_工作流/03_subagents/05-editor-review.md` | 主编审稿 | 综合三读后生成主编修改建议；每轮必查成稿卫生 | 已完成 |
| 21 | `_工作流/03_subagents/06-draft-revise.md` | 草稿修订 | 生成 `06_修订与发布/修订稿 vN.md` | 已完成 |
| 22 | `_工作流/03_subagents/06-release-check.md` | 发布检查（内容闭环） | 主编内容冻结后生成 `发布检查.md` | 已完成 |
| 23 | `_工作流/03_subagents/06-format-final-check.md` | 成稿终审（格式） | HTML 前生成 `成稿终审.md`，仅格式/卫生 | 已完成 |
| 24 | `_工作流/03_subagents/07-title-ecosystem.md` | 标题生态 | 生成 `07_传播终审与标题/标题生态搜索.md` | 已完成 |
| 25 | `_工作流/03_subagents/07-title-write.md` | 标题文案 | 生成 `07_传播终审与标题/标题方案.md` | 已完成 |
| 26 | `_工作流/03_subagents/08-illustration-plan.md` | 插图规划 | 生成插图方案和 prompts.json | 已完成 |
| 27 | `_工作流/03_subagents/09-html-build.md` | HTML 构建 | 成稿终审通过后生成 `09_终稿/【文章编号】_终稿.html` | 已完成 |

## 复制使用方式

**维护规则**：修改 subagent 时先改 `_工作流/03_subagents/`，再整文件复制到 `.cursor/agents/`；禁止只改 wrapper 不改正文。

### `_工作流/03_subagents/` → `.cursor/agents/` 对照

| 工作流模板 | .cursor/agents |
|---|---|
| `00-project-setup.md` | `project-setup.md` |
| `01-source-research.md` | `source-research.md` |
| `01-evidence-ledger.md` | `evidence-ledger.md` |
| `01-fact-check.md` | `fact-check.md` |
| `02-ecosystem-scan.md` | `ecosystem-scan.md` |
| `02-insight-select.md` | `insight-select.md` |
| `02-communication-criteria.md` | `communication-criteria.md` |
| `02-communication-analyze.md` | `communication-analyze.md` |
| `02-structure-criteria.md` | `structure-criteria.md` |
| `02-structure-analyze.md` | `structure-analyze.md` |
| `02-direction-decide.md` | `direction-decide.md` |
| `03-style-guide.md` | `style-guide.md` |
| `03-outline-plan.md` | `outline-plan.md` |
| `03-outline-review.md` | `outline-review.md` |
| `03-reader-criteria.md` | `reader-criteria.md` |
| `04-draft-write.md` | `draft-write.md` |
| `05-free-review.md` | `free-review.md` |
| `05-reader-review.md` | `reader-review.md` |
| `05-density-edit.md` | `density-edit.md` |
| `05-editor-review.md` | `editor-review.md` |
| `06-draft-revise.md` | `draft-revise.md` |
| `06-release-check.md` | `release-check.md` |
| `06-format-final-check.md` | `format-final-check.md` |
| `07-title-ecosystem.md` | `title-ecosystem.md` |
| `07-title-write.md` | `title-write.md` |
| `08-illustration-plan.md` | `illustration-plan.md` |
| `09-html-build.md` | `html-build.md` |

如果要在新项目中使用这些 subagent：

1. 在新项目中创建：

```text
.cursor/agents/
```

2. 从 `_工作流/03_subagents/` **整文件复制**对应模板到 `.cursor/agents/`，按上表改名（保留 frontmatter，正文完整内嵌，不使用引用式 wrapper）。

3. 根据新项目需要，检查 frontmatter 中的 `model` 字段。

4. 如果使用特定模型，将：

```yaml
model: inherit
```

改为对应模型名。

## 后续设计顺序

后续每新增一个 subagent，都在 `_工作流/03_subagents/` 中新增一个独立 `.md` 文件，并同步更新本文件的“当前模板清单”状态。
