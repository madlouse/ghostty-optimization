# OpenClaw 可借鉴的方法

## 1. Prompt Contracts 机制

### Output Contract（输出契约）
- 严格按要求顺序返回指定章节
- 长度限制只作用于对应章节
- 特定格式（JSON/Markdown）只输出该格式

### Completeness Contract（完整性契约）
- 所有项目覆盖或标注 [受阻] 前视为未完成
- 内部维护交付物清单
- 列表/批量/分页结果：确定预期范围、追踪已处理项目、最终确认前核实覆盖率
- 受阻时标注 [受阻] 并说明缺少什么

### Tool Persistence Rules（工具持续使用规则）
- **工具能提升准确度就持续使用**
- **不在"还差一步"时停下**
- **工具返回空？换策略重试**

## 2. Research Mode（研究模式）

三步研究法：
1. **规划**：列出 3-6 个子问题
2. **检索**：每个子问题搜索，追踪 1-2 条二阶线索
3. **综合**：解决矛盾，写带引用的答案
4. **继续搜索不太可能改变结论时才停止**

## 3. SOUL.md 模式

为每个 agent/skill 定义：
- 身份
- 核心职责
- 工作标准
- 输出格式
- 安全规则

## 4. 多 Agent 协作架构

- **Orchestrator**: 协调者
- **Researcher**: 深度研究
- **PM**: 项目管理
- **Evolver**: 知识提取和整合

## 应用到当前问题

### 问题：获取 X 文章内容

**应用 Tool Persistence Rules**：
1. ✅ 已尝试：WebFetch, WebSearch, bb-browser, curl, 截图
2. ❌ 未尝试：
   - 使用不同的浏览器配置
   - 尝试 Twitter API
   - 使用代理或不同的 User-Agent
   - 检查是否有 Twitter MCP 工具

**应用 Research Mode**：
1. **规划子问题**：
   - 如何绕过 X/Twitter 的反爬虫？
   - 是否有官方 API 可用？
   - 是否有第三方工具？
2. **检索方案**
3. **综合最佳方案**

## 建议改进

### 1. 创建 bb-browser skill
为 bb-browser 创建专门的 skill，明确何时使用它。

### 2. 创建 web-research skill
借鉴 OpenClaw Researcher 的模式，创建结构化的网页研究 skill。

### 3. 添加 Tool Persistence 提醒
在遇到工具失败时，提醒自己尝试其他策略。
