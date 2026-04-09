---
name: team-flow
description: >
  Team development workflow for AI-assisted software projects.
  Defines roles (Product, Design, Dev, QA), card lifecycle (PLAN→COMPLETE),
  quality gates (拆卡/开卡/结卡/QA验收/集成测试), and collaboration rules.
  TRIGGER when: user mentions "任务卡", "拆卡", "开卡", "结卡", "卡片状态",
  "sprint", "阶段", "QA", "验收", "集成测试", "bug卡", "团队流程",
  or asks about task management, card workflow, quality assurance process,
  or team collaboration for development projects.
  Also trigger when working on multi-phase projects and need to plan,
  track, or validate work across team roles.
license: MIT
metadata:
  author: daxiongya
  version: "1.0.0"
  type: workflow
  mode: assistive
---

# Team Flow

AI 辅助团队开发工作流。**严格执行卡片状态机**，每次状态转移必须通过对应关卡验证。

## 核心原则

**状态转移是受控的。** 任何卡片状态变更前，必须：
1. 确认当前状态的所有工作已完成
2. 通过该转移的关卡检查（见下方状态转移表）
3. 向用户说明转移原因和验证结果
4. 获得对应角色的确认

**不允许跳过状态。** 不允许从 DEVING 直接到 QA，必须经过 DEV DONE（自测）和结卡验收。

## 角色

| 角色 | 职责 | 详细指南 |
|------|------|---------|
| **产品 (PM)** | 需求定义、验收标准、优先级 | `references/plan.md` |
| **设计 (Design)** | 设计规范、UI 设计、交互规范、设计验收 | `references/design.md` |
| **开发 (Dev)** | 实现、自测、bug 修复 | `references/dev.md` |
| **开发负责人 (Dev Lead)** | 技术方案、任务分配、bug 卡审查 | — |
| **QA** | 测试、bug 发现、测试报告 | `references/qa.md` |

## 状态转移规则

**这是 team-flow 的核心。每次转移前必须逐条验证关卡条件。**

详见 `references/transitions.md`

```
PLAN ──①──> TODO ──②──> DEVING ──③──> DEV DONE ──④──> QA ──⑤──> QA DONE ──⑥──> COMPLETE
                          ↑                         ↑
                          └──── BLOCK ──────────────┘
```

| 转移 | 关卡名 | 核心要求 |
|------|--------|---------|
| ① PLAN→TODO | 拆卡完成 | 卡片要素齐全，三方无异议 |
| ② TODO→DEVING | 开卡 | PM+Design+Dev 对齐上下文，Dev 无疑问 |
| ③ DEVING→DEV DONE | 开发自测 | debug-kit 截图+日志验证，验收标准逐条自查 |
| ④ DEV DONE→QA | 结卡 | PM 功能验收 + Design 设计审查 + Dev 演示，三方确认通过 |
| ⑤ QA→QA DONE | QA 验收 | 测试报告输出，所有 bug 卡关闭 |
| ⑥ QA DONE→COMPLETE | 完成确认 | QA 签收，无遗留问题 |
| 任意→BLOCK | 阻塞 | 说明阻塞原因和依赖 |
| BLOCK→原状态 | 解除阻塞 | 阻塞原因已解决 |

## 阶段流程

每个开发阶段循环：

1. **设计规范** → `references/design.md` — 建立 DESIGN.md，Pencil MCP 出设计稿
2. **拆卡** → `references/plan.md` — PM+Design+Dev 拆分任务卡
3. **开卡→执行→结卡** → `references/dev.md` — 每张卡片的开发生命周期
4. **QA 验收** → `references/qa.md` — 功能/UI/交互/安全测试
5. **集成测试** → `references/integration.md` — 阶段全面回归

## 与 debug-kit 集成

| 环节 | debug-kit 用途 |
|------|---------------|
| 开发自测 (③) | 截图验证 UI、日志检查功能、交互操作验证 |
| 结卡验收 (④) | 截图审查设计还原度 |
| QA 测试 (⑤) | 操作测试、截图记录、日志分析、性能/安全检查 |
| 集成测试 | 全面功能验证、回归测试 |
