# 反馈汇总目录（项目负责人使用）

## 说明

**测试人员请忽略本目录**。本目录是项目负责人收集多人反馈用的。

## 工作流程

### 测试人员侧（你的电脑）
1. 直接用Agent，**不需要写任何反馈文件**
2. Agent会在合适时机自动询问/捕获反馈
3. 试用结束后说"导出反馈"，得到一个 `feedback-export-{你的名字}-{日期}.md`
4. 把这个文件用钉钉/微信/邮件发给项目负责人

### 项目负责人侧
1. 收到各工程师发来的 `feedback-export-*.md`
2. 把所有文件放到本目录的 `imports/` 子目录
3. 对Agent说"合并反馈"
4. Agent自动合并 + 识别共性问题 + 生成 `merged-feedback-{日期}.md`
5. 进一步用 `#feedback-review` 生成HTML改进报告

## 目录结构

```
feedback/
├── README.md                              ← 本文件
├── imports/                               ← 工程师发来的导出文件放这里
│   ├── feedback-export-zhangsan-20260530.md
│   ├── feedback-export-lisi-20260530.md
│   └── ...
├── merged-feedback-20260530.md            ← Agent合并后的汇总
└── feedback-review-report-20260530.html   ← Agent生成的改进报告
```

## 注意事项

- 所有反馈文件由Agent自动生成，无需手工编辑
- 测试人员的电脑是独立的，没有git/云，靠"导出+发送"的方式汇总
- 隐私：导出时可让Agent去标识化（用代号代替真实姓名）
