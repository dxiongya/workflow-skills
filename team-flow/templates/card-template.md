# [CARD-ID] 卡片标题

> Copy this file to `tasks/<PREFIX>-<NN>.md` and fill in. Delete this blockquote.
> Naming: `REFACTOR-01`, `FEAT-03`, `BUG-017` etc. — uppercase prefix, zero-padded.

**状态**: PLAN  
**分类**: visual / behavioral / structural  
**优先级**: P0 / P1 / P2 / P3  
**执行者**: <name>  
**依赖**: <CARD-ID> / 无  
**设计引用**: `design/design.md` §<section>  <!-- required if visual -->

## 任务需求

<!-- What to build. Be specific: new files, deleted files, modified symbols. -->

## 交互方式

<!-- How the user interacts: clicks, inputs, navigation, state changes. -->

## 验收标准

<!--
  Each item must be verifiable. Use the evidence syntax from
  references/transitions.md §证据语法:
    - grep:<pattern>@<path>    → structural
    - file:<path>              → existence
    - compile:<cmd>            → build/type check
    - screenshot:<path>        → visual
    - log:<path>:<line>        → runtime
  Avoid vague wording like "加载快" or "体验好".
-->

- [ ] <criterion 1>
- [ ] <criterion 2>
- [ ] <criterion 3>

## 相关资源

<!-- Design doc sections, API docs, reference files, external links. -->

- `design/design.md` §<section>
- <other refs>

## 技术注意

<!-- Non-obvious constraints, gotchas, framework quirks. Optional. -->
