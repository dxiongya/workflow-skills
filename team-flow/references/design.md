# 设计角色指南

## 设计师的核心职责

设计不是"嘴上说说"，而是输出可执行、可验收的设计资产。每个功能卡片都需要对应的设计内容。

## 一、设计规范体系（Design System）

每个项目必须建立设计规范，作为所有设计和开发的唯一标准。

### 规范文件：DESIGN.md

参照业界标准（Stripe、Linear、Vercel、Airbnb 等），项目根目录维护一份 `DESIGN.md`，包含以下章节：

| 章节 | 内容 | 示例 |
|------|------|------|
| **1. 视觉主题** | 整体风格定义、品牌调性 | "简洁专业、科技感、温暖友好" |
| **2. 色彩系统** | 主色、辅助色、功能色、中性色，含语义角色 | Primary `#533afd`、Success `#15be53`、Border `#e5edf5` |
| **3. 字体层级** | 字体族、大小、字重、行高、字间距 | Display 48px/300、Body 16px/400、Caption 12px |
| **4. 组件样式** | 按钮、卡片、输入框、徽章、导航的完整规格 | Button: padding 8px 16px, radius 4px, bg #533afd |
| **5. 布局原则** | 间距系统、栅格、最大宽度、留白哲学 | 8px 基准单位、max-width 1080px |
| **6. 层级阴影** | 各级阴影值、使用场景 | Level 2: `rgba(50,50,93,0.25) 0px 30px 45px -30px` |
| **7. Do's/Don'ts** | 设计准则和禁忌 | Do: 使用 navy 而非纯黑; Don't: 圆角不超过 8px |
| **8. 响应式** | 断点、触摸目标、折叠策略 | Mobile <640px、Tablet 640-1024px |
| **9. Agent 提示** | AI 可直接使用的组件生成 prompt | 含精确色值、字号、间距的组件描述 |

### 获取设计灵感

使用 `npx getdesign@latest add <name>` 获取业界设计规范参考：

```bash
# 获取知名产品的设计规范
npx getdesign@latest add stripe    # 金融科技标杆
npx getdesign@latest add linear    # 项目管理工具
npx getdesign@latest add vercel    # 开发者工具
npx getdesign@latest add airbnb    # 消费者产品
npx getdesign@latest add notion    # 生产力工具
npx getdesign@latest add figma     # 设计工具
npx getdesign@latest add apple     # 品牌设计
```

完整列表见 https://github.com/VoltAgent/awesome-design-md （58 个设计系统）

### 建立项目 DESIGN.md

1. 参考 2-3 个风格接近的设计系统
2. 根据项目品牌定制色彩、字体、组件规格
3. 写入项目根目录 `DESIGN.md`
4. 所有设计和开发以此文件为唯一标准

---

## 二、设计工具：Pencil MCP

使用 Pencil MCP 工具在 `.pen` 文件中创建实际设计稿。

### 核心工具

| 工具 | 用途 |
|------|------|
| `get_editor_state` | 获取当前编辑器状态和 schema |
| `open_document` | 打开或创建 .pen 文件 |
| `get_guidelines` | 加载设计指南和样式 |
| `batch_get` | 搜索/读取节点，了解现有设计 |
| `batch_design` | 执行 insert/update/replace/delete 操作 |
| `get_screenshot` | 截图验证设计效果 |
| `get_variables` | 获取设计变量和主题 |
| `set_variables` | 设置设计变量 |
| `export_nodes` | 导出节点为图片 |

### 设计工作流

```
1. get_editor_state(include_schema: true)     ← 首次必须，获取 schema
2. open_document("designs/feature-x.pen")     ← 打开或创建设计文件
3. get_guidelines()                           ← 加载设计系统指南
4. batch_design(operations)                   ← 创建设计，每批最多 25 个操作
5. get_screenshot(nodeId)                     ← 截图验证
6. 发现问题 → batch_design 修正 → 再次截图
```

---

## 三、每张卡片的设计交付物

### 功能卡片的设计内容

每张任务卡中，设计需要提供：

| 交付物 | 说明 | 格式 |
|--------|------|------|
| **页面布局** | 整体结构、组件排列 | .pen 文件或标注图 |
| **组件规格** | 用到的组件及其状态（默认/hover/active/disabled） | 引用 DESIGN.md 组件规范 |
| **交互说明** | 点击、输入、切换等操作的视觉反馈 | 文字描述 + 状态对比图 |
| **响应式适配** | 不同屏幕尺寸的布局变化 | 标注关键断点的布局差异 |
| **边界状态** | 空数据、加载中、错误、长文本等 | 每种状态的设计稿 |
| **设计标注** | 间距、色值、字号等精确数值 | 直接引用 DESIGN.md token |

### 设计标注示例

```
登录按钮:
  - 类型: Primary Button (DESIGN.md §4 Buttons)
  - 文字: "登录"
  - 背景: var(--color-primary) → #533afd
  - 文字色: #ffffff
  - 字号: 16px, weight 400
  - padding: 12px 24px
  - border-radius: 4px
  - hover: #4434d4
  - disabled: opacity 0.5, cursor not-allowed

  空状态:
  - 插图: 居中, max-width 200px
  - 标题: 18px, weight 300, color var(--color-heading)
  - 描述: 14px, weight 400, color var(--color-body)
  - 操作按钮: Secondary Button
```

---

## 四、设计验收标准

### 结卡时设计审查（Design Review）

设计师在结卡环节使用 debug-kit 截图审查：

```bash
P=~/.claude/skills/debug-kit/scripts

# 截取实际运行效果
bash $P/ios-ctl.sh screenshot /tmp/review-actual.png

# 或 web 项目
bash $P/web-ctl.sh screenshot /tmp/review-actual.png
```

### 审查维度

| 维度 | 检查项 |
|------|--------|
| **布局** | 组件位置、间距是否与设计稿一致 |
| **色彩** | 颜色是否使用 DESIGN.md 定义的 token |
| **字体** | 字号、字重、行高是否正确 |
| **交互** | hover/active/focus 状态是否实现 |
| **边界** | 空数据、长文本、加载状态是否处理 |
| **响应式** | 不同屏幕尺寸是否适配 |

### 审查结论

| 结果 | 说明 |
|------|------|
| **通过** | 设计还原度达标，允许进入 QA |
| **微调** | 有细节偏差（间距差 2-4px 等），不阻塞但需记录 |
| **不通过** | 布局错误、颜色错误、交互缺失，返回开发修正 |

---

## 五、设计一致性维护

### DESIGN.md 作为单一真相源

- 开发直接读 DESIGN.md 中的 token 值来写代码
- 设计变更必须先更新 DESIGN.md，再通知开发
- 禁止"口头约定"颜色/间距——必须写入 DESIGN.md
- QA 审查时也参照 DESIGN.md 判断是否为 bug

### 设计系统演进

- 新组件先在 DESIGN.md 定义规格，再创建设计稿
- 现有组件修改需要评估影响范围（哪些页面使用了）
- 每个阶段结束后 review DESIGN.md 是否需要更新
