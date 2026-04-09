# QA 角色指南

## QA 的核心职责

QA 不是"点一下看看能不能用"，而是系统性地验证功能逻辑、UI 还原、交互体验、安全性和稳定性。每一步测试都需要 **debug-kit 工具辅助 + 自主思考判断**。

## 参与角色
QA（主导）+ 执行开发（bug 修复）

## 触发条件
卡片状态为 **QA**（结卡通过后）

---

## 一、测试准备

### 1. 理解卡片
- 阅读卡片需求、验收标准、交互说明、设计标注
- 理解这个功能**应该**做什么，**不应该**做什么
- 识别关键路径和边界场景

### 2. 制定测试计划
- 列出需要验证的测试用例（正常流程 + 异常流程）
- 准备测试数据（正常数据、极端数据、非法数据）
- 确认前置条件（登录状态、数据状态、设备状态等）

### 3. 环境准备（debug-kit）

```bash
P=~/.claude/skills/debug-kit/scripts

# 启动应用（根据平台）
bash $P/ios-ctl.sh run /path/to/project        # iOS
bash $P/web-ctl.sh serve /path/to/project       # Web
bash $P/rn-ctl.sh run /path/to/project          # React Native

# 确认应用正常启动
bash $P/ios-ctl.sh health
```

---

## 二、功能逻辑测试

验证功能是否按需求正确工作。这是测试的核心。

### 测试思路
- **正向流程**：按正常操作路径走一遍，每步截图记录
- **反向流程**：故意操作错误，验证错误处理
- **边界值**：极端输入（空、超长、特殊字符、最大最小值）
- **状态转换**：功能涉及的状态变化是否正确

### debug-kit 操作方法

```bash
# 操作 → 截图 → 验证，形成证据链
bash $P/ios-ctl.sh tap 195 300          # 操作
bash $P/ios-ctl.sh screenshot /tmp/qa-step1.png  # 截图记录
bash $P/ios-ctl.sh tap identifier "submitBtn"     # 按标识操作
bash $P/ios-ctl.sh screenshot /tmp/qa-step2.png   # 截图验证结果

# 日志检查——功能执行后是否有异常
bash $P/ios-ctl.sh log 5                # 查看设备日志
bash $P/web-ctl.sh console 10           # 监控控制台输出

# 文本输入测试
bash $P/ios-ctl.sh tap 195 400          # 聚焦输入框
bash $P/ios-ctl.sh type "测试文本"       # 输入
bash $P/ios-ctl.sh screenshot /tmp/qa-input.png
```

### 逻辑验证要点

| 场景 | 验证方法 |
|------|---------|
| 数据提交 | 操作后检查 UI 变化（screenshot）+ 日志确认（console/log） |
| 状态切换 | 切换前截图 → 操作 → 切换后截图，对比变化 |
| 数据持久化 | 操作 → 关闭应用 → 重新打开 → 截图确认数据还在 |
| 错误处理 | 输入非法数据 → 截图确认错误提示正确显示 |
| 权限控制 | 不同角色/状态下操作，验证权限是否生效 |

---

## 三、UI 测试

验证界面是否与 DESIGN.md 规范和设计稿一致。

### 审查维度

| 维度 | 具体检查 | debug-kit 工具 |
|------|---------|---------------|
| **布局** | 组件位置、间距、对齐 | `screenshot` 对比设计稿 |
| **色彩** | 是否使用 DESIGN.md 定义的色值 | `screenshot` + 肉眼对比 |
| **字体** | 字号、字重、行高、颜色 | `screenshot` 放大检查 |
| **图标** | 大小、颜色、位置 | `screenshot` |
| **响应式** | 不同屏幕尺寸的适配 | `viewport`（Web）或不同设备 |

### Web 响应式测试

```bash
# 桌面
bash $P/web-ctl.sh viewport desktop
bash $P/web-ctl.sh screenshot /tmp/qa-desktop.png

# 平板
bash $P/web-ctl.sh viewport tablet
bash $P/web-ctl.sh screenshot /tmp/qa-tablet.png

# 手机
bash $P/web-ctl.sh viewport mobile
bash $P/web-ctl.sh screenshot /tmp/qa-mobile.png
```

### 边界 UI 状态

必须检查的 UI 边界场景：

| 状态 | 说明 |
|------|------|
| **空数据** | 列表为空、搜索无结果时显示什么 |
| **加载中** | 是否有 loading 指示 |
| **长文本** | 超长标题/内容是否截断、换行、溢出 |
| **错误状态** | 网络错误、服务端错误的展示 |
| **首次使用** | 没有历史数据时的引导 |

---

## 四、交互测试

验证用户操作的响应是否符合交互规范。

### 交互验证清单

| 交互类型 | 验证内容 | debug-kit 方法 |
|---------|---------|---------------|
| **点击/触摸** | 点击区域是否合理、反馈是否即时 | `tap` + `screenshot` |
| **输入** | 聚焦、输入、失焦的视觉反馈 | `tap` → `type` → `screenshot` |
| **滚动** | 列表滚动是否流畅、加载更多 | `swipe`（Android）/ 多次截图 |
| **导航** | 页面跳转、返回是否正确 | `tap` 导航元素 → `screenshot` 确认页面 |
| **动画/过渡** | 是否有适当的过渡效果 | 连续截图或观察 |
| **键盘** | 键盘弹出/收起、输入框是否被遮挡 | `tap` 输入框 → `screenshot` |
| **手势** | 左滑删除、下拉刷新等 | `swipe` + `screenshot` |

### 操作连续性测试

模拟真实用户的连续操作流程：

```bash
# 模拟完整用户旅程：登录 → 操作 → 验证
bash $P/ios-ctl.sh tap 195 300          # 点击用户名输入框
bash $P/ios-ctl.sh type "testuser"       # 输入用户名
bash $P/ios-ctl.sh tap 195 380          # 点击密码输入框
bash $P/ios-ctl.sh type "password123"    # 输入密码
bash $P/ios-ctl.sh tap 195 460          # 点击登录按钮
bash $P/ios-ctl.sh screenshot /tmp/qa-after-login.png  # 截图验证登录结果

# 检查日志确认没有异常
bash $P/ios-ctl.sh log 5
```

---

## 五、安全与稳定性测试

### 安全检查

| 项目 | 测试方法 |
|------|---------|
| **XSS** | 输入 `<script>alert(1)</script>` 等，检查是否被转义 |
| **注入** | 输入 SQL/NoSQL 注入字符串，检查响应 |
| **权限绕过** | 直接访问需要权限的页面/接口 |
| **敏感数据** | 检查控制台日志是否泄露敏感信息（`console` 命令） |
| **网络请求** | 监控请求是否携带不必要的敏感数据（`network` 命令） |

```bash
# 监控网络请求，检查是否有敏感数据泄露
bash $P/web-ctl.sh network 15

# 检查控制台是否有报错或敏感信息输出
bash $P/web-ctl.sh console 10

# 性能检查
bash $P/web-ctl.sh perf

# 可访问性检查
bash $P/web-ctl.sh a11y
```

### 稳定性检查

- 快速反复点击同一按钮，是否重复提交
- 网络断开时的行为（如果适用）
- 长时间使用后是否有内存泄漏（`perf` 命令检查 heap）

---

## 六、测试报告

### 报告格式

```
## 测试报告 — [卡片标题]
测试人：[QA]
测试日期：[日期]
测试环境：[平台/设备/版本]

### 一、验收标准验证
- [x] 标准1：通过（截图：/tmp/qa-ac1.png）
- [x] 标准2：通过（截图：/tmp/qa-ac2.png）
- [ ] 标准3：未通过（见 BUG-001）

### 二、功能逻辑
- [x] 正向流程：通过
- [x] 反向流程（错误处理）：通过
- [ ] 边界值测试：发现问题（见 BUG-002）

### 三、UI 审查
- [x] 布局与设计稿一致
- [x] 色彩符合 DESIGN.md 规范
- [ ] 响应式适配：手机端列表间距偏大（见 BUG-003）

### 四、交互测试
- [x] 点击反馈正常
- [x] 输入交互正常
- [x] 导航跳转正确

### 五、安全与稳定性
- [x] 无 XSS 风险
- [x] 控制台无敏感信息泄露
- [x] 连续操作无异常

### 六、发现的问题
| Bug ID | 描述 | 严重程度 | 类型 | 截图 |
|--------|------|---------|------|------|
| BUG-001 | 提交空表单未显示错误提示 | P1 | 逻辑 | /tmp/bug-001.png |
| BUG-002 | 输入超过100字符后文本溢出 | P2 | UI | /tmp/bug-002.png |
| BUG-003 | 手机端列表项间距 24px 应为 16px | P2 | UI | /tmp/bug-003.png |

### 七、结论
[ ] 通过 / [x] 不通过（3 个 bug 待修复）
```

---

## 七、Bug 处理流程

### Bug 卡创建

每个 bug 卡必须包含：

| 字段 | 内容 |
|------|------|
| **标题** | 简明描述问题 |
| **复现步骤** | 从哪个页面开始、具体操作步骤（附 debug-kit 命令） |
| **预期结果** | 应该看到什么（引用验收标准或 DESIGN.md） |
| **实际结果** | 实际看到什么（附截图） |
| **截图/日志** | debug-kit screenshot 截图 + console/log 日志 |
| **严重程度** | P0/P1/P2/P3 |
| **类型** | 逻辑 bug / UI bug / 交互 bug / 安全问题 |
| **环境** | 平台、设备、系统版本 |

### Bug 修复循环

```
QA 发现 bug → 创建 bug 卡（含截图+复现步骤）
    → Dev 修复 → Dev 自测（debug-kit 截图验证）
    → QA 复验（同样用 debug-kit 按原复现步骤操作）
        ↓
    通过 → 关闭 bug 卡
    不通过 → Dev 继续修复（QA 补充新截图说明仍存在的问题）
```

### Bug 严重程度

| 等级 | 定义 | 示例 | 处理时效 |
|------|------|------|---------|
| **P0** | 崩溃、数据丢失、核心功能不可用 | 点击提交后应用崩溃 | 立即修复 |
| **P1** | 功能异常但有 workaround | 搜索结果排序错误 | 当前阶段必须修复 |
| **P2** | 体验问题、UI 偏差 | 间距不对、颜色偏差 | 建议修复 |
| **P3** | 优化建议、极端边界 | 超长文本未截断 | 可延后 |

### Bug 类型分类

| 类型 | 说明 | 判断方式 |
|------|------|---------|
| **逻辑 bug** | 功能行为与需求不符 | 对照验收标准 |
| **UI bug** | 界面与设计稿/DESIGN.md 不符 | 截图对比 |
| **交互 bug** | 操作反馈不正确或缺失 | 操作后截图验证 |
| **安全问题** | 存在安全风险 | 注入测试、日志审查 |
| **性能问题** | 响应过慢、内存泄漏 | perf 命令检测 |

---

## 八、验收结果

| 结果 | 后续 |
|------|------|
| 全部通过 | 状态 **QA → QA DONE → COMPLETE** |
| 发现 bug | 创建 bug 卡，原卡保持 **QA** 状态，所有 bug 卡关闭后标记 **COMPLETE** |

## 关键规则

- QA 对原始任务卡验收通过后，才标记 **QA DONE**
- Bug 卡是独立卡片，有自己的 DEVING → DEV DONE → QA 生命周期
- 所有 bug 卡关闭后，原任务卡标记 **COMPLETE**
- 每个 bug 必须有 debug-kit 截图作为证据，不接受"口头描述"
- QA 复验时必须按原 bug 的复现步骤操作，确认修复有效
