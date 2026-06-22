# MEMORY.md - 项目长期记忆

## 内容创作工作流（v1）
- 单篇文章从 0 到 HTML 的标准执行手册：`_工作流/02_单篇文章从0到HTML成稿执行手册.md`
- 27 个 subagent 定义在 `_工作流/03_subagents/`，已一对一转为 WorkBuddy Agent 专家（见 `~/.workbuddy/plugins/marketplaces/my-experts/plugins/`）
- 每个专家的 agent md 顶部带「角色定位 + 源 subagent」指针
- 批量转化脚本：`scripts/batch_create_pipeline.py`、`scripts/batch_validate_register.py`、`scripts/batch_rename_avatars.py`
- 流水线常见踩坑：subagent 并发 ImageGen output_dir 失效 / Python GBK 编码 / init_expert emoji 半失败

## 已注册的 27 个专家目录
见 `~/.workbuddy/plugins/marketplaces/my-experts/plugins/`，按阶段排列：
- 0: project-setup
- 1: source-research, evidence-ledger, fact-check
- 2: ecosystem-scan, insight-select, communication-criteria, communication-analyze, structure-criteria, structure-analyze, direction-decide
- 3: style-guide, reader-criteria, outline-plan, outline-review
- 4: draft-write
- 5: free-review, reader-review, density-edit, editor-review
- 6: release-check, format-final-check, draft-revise
- 7: title-ecosystem, title-write
- 8: illustration-plan
- 9: html-build