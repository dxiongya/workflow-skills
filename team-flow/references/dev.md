# 开发执行（开卡 → 执行 → 结卡）

## 一、开卡

### 参与角色
PM + Design + 本卡执行开发

### 目的
确保执行开发对卡片的需求、交互、验收标准完全理解，消除信息差。

### 流程
1. PM 讲解需求背景和目标
2. Design 说明交互细节和设计规范
3. Dev 确认技术可行性，提出疑问
4. 三方对齐验收标准
5. 状态变更：**TODO → DEVING**

### 开卡产出
- Dev 对卡片内容无疑问
- 如发现需求不清或设计缺失，当场补充或标记 BLOCK

---

## 二、执行任务

### 角色
执行开发（Dev）

### 流程

1. **分析阶段**
   - 评估当前项目状态和代码结构
   - 拆分开发细节为 TODO 列表
   - 识别技术风险和依赖

2. **开发阶段**
   - 按 TODO 列表逐项实现
   - 遵循项目编码规范

3. **自测阶段（debug-kit 介入）**
   - 使用 debug-kit 启动应用
   - 截图验证 UI 是否符合设计稿
   - 日志检查功能逻辑是否正确
   - 逐条对照卡片验收标准自查
   - 交互操作验证（tap、type 等）

4. **自测通过**
   - 状态变更：**DEVING → DEV DONE**
   - 通知 PM + Design 准备结卡

### 开发自测 checklist
```
[ ] 功能实现完整，覆盖卡片所有需求点
[ ] UI 与设计稿一致（debug-kit screenshot 对比）
[ ] 交互行为正确（debug-kit tap/type 验证）
[ ] 无控制台错误（debug-kit console/log 检查）
[ ] 边界情况处理（空数据、异常输入等）
```

> 自测证据必须使用 `references/transitions.md §证据语法` 的格式，不接受模糊描述。

---

## Card ↔ Commit 映射约定

一张卡 = 一个或多个 atomic commit，commit 与卡片必须有明确的追溯关系。

### 规则

1. **Commit message 首行必须引用卡片 ID**，格式：
   ```
   <type>(<CARD-ID>): <短描述>
   ```
   例子：
   ```
   feat(REFACTOR-01): design/ config layer + semantic classes
   fix(BUG-023): resolve race condition in session switch
   chore(CHORE-05): bump dependencies
   ```

2. **DEV DONE 前必须 commit**。DEVING → DEV DONE 转移的前置条件是"所有改动已提交到本地分支"，否则结卡无 diff 可查。

3. **Atomic**：一个 commit 只做一件事。如果一张卡需要多步（如先加 token、再改组件），应拆成多个 commit，但每个 commit message 都引用同一个 `CARD-ID`。

4. **卡片范围外的改动禁止塞进同一 commit**。如果自测时顺手修了无关的 typo，新建一张 `CHORE-XX` 卡或单独 commit，message 不引用本卡 ID。

5. **Body 引用卡片路径**（可选但推荐）：
   ```
   feat(REFACTOR-01): design/ config layer + semantic classes

   Moves tokens into design/ as canonical source. Creates components.css
   with 13 semantic classes. No components reference the new classes yet.

   Card: tasks/REFACTOR-01.md
   ```

### 结卡时的 commit 审查（④ 关卡的一部分）

- PM/Design/Dev 结卡时，用 `git log --oneline <base>..HEAD -- tasks/ src/` 快速确认本卡所有 commit
- 如果发现 commit message 没引用卡片 ID，**结卡不通过**，要求 Dev 用 `git commit --amend` 或交互式 rebase 修正

### 分支策略（建议，非强制）

- 单张 P0 大卡：建议 `<card-id>` 独立分支（如 `refactor-01`），完成后 merge
- 同一阶段的连续小卡：可在同一阶段分支上顺序推进
- Bug 卡：紧急 hotfix 另开分支，非紧急在当前阶段分支内

---

## 三、结卡

### 参与角色
PM + Design + 执行开发

### 目的
团队验收开发成果，确认符合卡片要求。

### 流程

1. **Dev 演示**
   - 展示实现结果（可用 debug-kit screenshot 提供截图）
   - 说明实现方案和注意事项

2. **PM 验收**
   - 对照验收标准逐条确认
   - 检查功能是否满足需求

3. **Design 验收（debug-kit 截图审查）**
   - 使用 debug-kit screenshot 获取实际截图
   - 对比设计稿审查：布局、间距、颜色、字体、交互动效
   - 标记设计问题（如有）

4. **结果判定**

| 结果 | 后续动作 |
|------|---------|
| 通过 | 状态 **DEV DONE → QA**，进入 QA 验收 |
| 不通过 | 状态保持 **DEVING**，Dev 继续修改，修完再次结卡 |

### 关键规则
- 结卡不通过时**不创建新卡**，在原卡上继续迭代
- 结卡通过后才进入 QA 环节
- 设计问题和功能问题都在结卡阶段解决
