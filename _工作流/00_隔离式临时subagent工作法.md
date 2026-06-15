# 隔离式临时 subagent 工作法

> 用途：规范系列文章生产中的临时 subagent 使用方式，减少不同文章、不同阶段、不同历史上下文之间的干扰。

---

## 一、核心原则

系列文章生产中，主 agent 不直接承担所有写作任务，而是作为项目经理拆分任务、分配材料、收集产物。

每个重要阶段都启动一个新的临时 subagent，并给它明确角色、任务边界、允许读取的材料和输出文件。

目标是：

1. 避免把其他文章的事实、结构、标题、口吻带入当前文章。
2. 避免主对话历史污染当前任务。
3. 让每个阶段只围绕当前文章、当前文件、当前目标工作。
4. 复用流程和标准，不复用具体内容。

一句话原则：

> 复用方法，不复用内容；传递文件，不传递闲聊上下文。

---

## 二、主 agent 职责

主 agent 只做项目经理，主要负责：

1. 确定当前文章项目路径。
2. 检查当前阶段需要哪些输入文件。
3. 启动新的临时 subagent。
4. 明确 subagent 的角色、任务、允许材料、禁止事项、输出格式。
5. 接收 subagent 产物。
6. 将产物写入当前文章目录中的指定文件。
7. 根据质量闸门决定是否进入下一阶段。

主 agent 不应：

1. 凭主对话记忆直接补事实。
2. 把其他文章内容带入当前文章。
3. 在没有明确文件依据时替 subagent 下结论。
4. 跳过审稿和事实核查阶段。

---

## 三、临时 subagent 隔离规则

每次启动临时 subagent 时，必须明确以下规则：

1. 只处理当前任务。
2. 只使用任务中列出的文件和用户明确提供的信息。
3. 不引用其他文章、其他项目、其他历史对话。
4. 不把同系列其他文章的事实、机制、标题、结构带入本文。
5. 不引入未核事实。
6. 如果材料不足，标注“待补资料”，不要编造。
7. 输出必须服务当前阶段，不做下一阶段工作。
8. 产物必须写入指定文件。

---

## 四、必须新开 subagent 的阶段

以下阶段必须使用新的临时 subagent：

1. 资料研究（`content-researcher`）
2. 证据台账（`content-evidence-ledger`）
3. 事实核查（`content-fact-checker`）
4. 外部内容生态分析（`content-content-ecosystem-analyst`）
5. 洞察初选（`content-insight-selector`）
6. 传播学标准与分析（`content-communication-criteria` / `content-communication-analyst`）
7. 结构命题标准与分析（`content-structure-criteria` / `content-structure-analyst`）
8. 方向把控（`content-direction-director`）
9. 文风卡（`content-style-guide`）
10. 读者审稿卡（`content-reader-criteria`）
11. 大纲（`content-outline-planner`）
12. 大纲审阅（`content-outline-reviewer`）
13. 草稿（`content-draft-writer`）
14. 读者审读（`content-reader-reviewer`）
15. 主编审稿（`content-chief-editor`）
16. 修订（`content-revision-writer`）
17. 发布检查（`content-release-checker`）
18. 标题策略（`content-title-strategist`）
19. 插图方案（`content-illustration-planner`）
20. HTML 终稿（`content-html-producer`）

其中，资料研究、洞察初选、方向把控、草稿、审稿、标题六类任务尤其需要隔离。

---

## 五、阶段角色与产物

| 阶段 | subagent 文件 | 临时角色 | 输入材料 | 输出文件 |
|---|---|---|---|---|
| 项目初始化 | `content-project-architect` | 项目架构员 | 用户选题、系列信息 | README.md、总计划.md、00_目录结构.md |
| 资料研究 | `content-researcher` | 资料研究员 | README.md、总计划.md | 01_资料/资料.md |
| 证据台账 | `content-evidence-ledger` | 证据台账员 | 资料.md | 01_资料/证据台账.md |
| 事实核查 | `content-fact-checker` | 事实核查员 | 资料.md、证据台账.md | 01_资料/事实核查清单.md |
| 外部内容生态分析 | `content-content-ecosystem-analyst` | 外部内容生态分析员 | README.md、总计划.md、搜索结果 | 02_洞察及主题/外部内容搜索.md |
| 洞察初选 | `content-insight-selector` | 洞察初选员 | 资料、证据台账、外部内容搜索 | 02_洞察及主题/洞察及主题初选.md |
| 传播学标准 | `content-communication-criteria` | 传播学标准生成员 | 系列传播配置、README、总计划、事实核查清单 | 02_洞察及主题/传播学审查卡.md |
| 传播学分析 | `content-communication-analyst` | 传播学分析员 | 传播学审查卡、外部内容搜索、洞察及主题初选、事实核查清单 | 02_洞察及主题/传播学分析卡.md |
| 结构命题标准 | `content-structure-criteria` | 结构命题标准生成员 | 系列结构命题配置、README、总计划、事实核查清单 | 02_洞察及主题/结构命题审查卡.md |
| 结构命题分析 | `content-structure-analyst` | 结构命题分析员 | 结构命题审查卡、洞察及主题初选、事实核查清单 | 02_洞察及主题/结构命题分析卡.md |
| 方向把控 | `content-direction-director` | 方向把控员 | 传播学分析卡、结构命题分析卡、事实核查清单、README、总计划、系列基调、读者画像、审稿政策 | 02_洞察及主题/方向把控.md |
| 文风卡 | `content-style-guide` | 文风指导编辑 | 方向把控、传播学分析卡、结构命题分析卡、事实核查清单、系列基调、平台与阅读方式、读者画像、文风禁用清单 | 03_文风与大纲/文风卡.md |
| 读者审稿卡 | `content-reader-criteria` | 读者审读标准生成员 | 方向把控、文风卡、读者画像、平台与阅读方式、事实核查清单 | 03_文风与大纲/读者审稿卡.md |
| 大纲 | `content-outline-planner` | 大纲策划编辑 | 方向把控、文风卡、文章结构与格式配置、事实核查清单、传播学分析卡、结构命题分析卡 | 03_文风与大纲/大纲.md |
| 大纲审阅 | `content-outline-reviewer` | 大纲审阅主编 | 大纲、方向把控、文风卡、文章结构与格式配置、事实核查清单 | 03_文风与大纲/大纲审阅.md |
| 草稿 | `content-draft-writer` | 作者 | 大纲、大纲审阅、文风卡、事实核查清单、资料、证据台账、方向把控、文章结构与格式配置 | 04_草稿/草稿.md |
| 读者审读 | `content-reader-reviewer` | 读者审读员 | 当前稿、读者审稿卡、文风卡 | 05_审阅/读者审读 vN.md |
| 主编审稿 | `content-chief-editor` | 主编 | 当前稿、主编审稿卡、证据台账 | 05_审阅/主编修改建议 vN.md |
| 修订 | `content-revision-writer` | 修订作者 | 当前稿、读者审读、主编建议 | 06_修订与发布/修订稿 vN.md |
| 发布检查 | `content-release-checker` | 发布检查员 | 修订稿、审稿意见、证据台账 | 06_修订与发布/发布检查.md |
| 标题 | `content-title-strategist` | 标题策略编辑 | 修订稿、发布检查、标题搜索 | 07_传播终审与标题/标题分析卡.md |
| 插图 | `content-illustration-planner` | 插图策划编辑 | 修订稿、最终标题 | 08_插图/插图方案.md、prompts.json |
| HTML | `content-html-producer` | 排版工程师 | 修订稿、标题、图片 | 09_终稿/终稿.html |

---

## 六、质量闸门

### 1. 事实闸门

如果 P0 事实存在待核、冲突未解决或来源不足，不进入洞察、大纲和写作阶段。

### 2. 方向闸门

如果 `02_洞察及主题/方向把控.md` 判断“暂不进入文风卡和大纲”“返回洞察阶段”或“返回事实补充”，不得强行进入文风卡和大纲。

方向把控只读取必要的上游结论，优先依据传播学分析卡、结构命题分析卡、事实核查清单、README、总计划和系列配置，不重新做洞察、传播或结构分析。

### 3. 大纲闸门

如果大纲审阅存在必改项，不进入草稿阶段。大纲编辑必须根据 `03_文风与大纲/大纲审阅.md` 修订 `03_文风与大纲/大纲.md`；若审阅结论为“大修后复审”，修订后必须再次运行大纲审阅；若结论为“退回上游”，不得强行修订大纲。

### 4. 审稿闸门

每轮修订后必须检查读者必改项和主编必改项是否清零。

### 5. 三轮失败机制

审稿修订最多三轮。

如果第 3 轮后仍有必改项，停止流程，输出：

```text
06_修订与发布/三轮失败报告.md
```

不继续强行生成终稿。

### 6. 发布闸门

发布检查未通过，不进入标题、插图和 HTML 阶段。

---

## 七、上下文隔离检查清单

启动任何 subagent 前，主 agent 必须检查：

1. 是否给了当前文章路径？
2. 是否只列出了必要输入文件？
3. 是否明确禁止引用其他文章？
4. 是否明确禁止使用主对话历史？
5. 是否明确输出文件？
6. 是否明确当前阶段不做下一阶段工作？
7. 是否存在可能污染当前任务的旧材料？如有，不传给 subagent。

---

## 八、工作方式总结

这套方法的关键不是让一个 agent 记住所有东西，而是让每个临时 subagent 只拿到它该拿的任务包。

正确方式：

```text
当前阶段需要什么文件 → 只传什么文件 → 新 subagent 完成任务 → 产物写回文件 → 下一阶段重新开 subagent
```

错误方式：

```text
一个对话里一直凭记忆写所有文章 → 不同文章事实和结构互相污染
```

最终目标：

> 每篇文章都有独立任务包，每个阶段都有独立角色，每个产物都能回到文件依据。
