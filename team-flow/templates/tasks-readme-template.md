# Tasks — <Phase Name>

> Copy to `tasks/README.md` at the start of each phase. Delete this blockquote.

**阶段名**：<Phase Name>  
**目标**：<one-line goal>  
**基线**：<path to design doc or spec>  
**开始日期**：<YYYY-MM-DD>

## 卡片列表

| ID | 标题 | 分类 | 状态 | 依赖 | 优先级 |
|----|------|------|------|------|--------|
| FEAT-01 | <title> | structural | PLAN | — | P0 |
| FEAT-02 | <title> | visual | PLAN | 01 | P0 |
| FEAT-03 | <title> | behavioral | PLAN | 02 | P1 |

## 依赖图

```mermaid
graph LR
  FEAT-01 --> FEAT-02
  FEAT-02 --> FEAT-03
```

## 状态机

```
PLAN ──①──> TODO ──②──> DEVING ──③──> DEV DONE ──④──> QA ──⑤──> QA DONE ──⑥──> COMPLETE
```

每次状态转移必须通过 `~/.claude/skills/team-flow/references/transitions.md` 定义的关卡。

## 建议池快照

> 本阶段开始时从 `proposals/` 池中选入的建议，以及本阶段结束时新增的待评审建议。

- [ ] <proposal>
- [ ] <proposal>
