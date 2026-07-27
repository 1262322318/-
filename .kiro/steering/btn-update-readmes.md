---
inclusion: manual
description: "一键扫描所有目录并同步更新README文件清单"
---

请执行README更新。按照 .kiro/skills/update-readmes.md 中定义的步骤：1.扫描以下目录的当前文件列表：.kiro/steering/、.kiro/skills/、.kiro/hooks/、.kiro/settings/、.kiro/specs/、.kiro/data/、requirements/、audit-feedback/；2.读取每个目录的README.md；3.对比文件清单与实际文件的差异；4.向用户展示差异并询问是否更新；5.用户确认后执行更新（保留README结构，只同步文件清单表格）。
