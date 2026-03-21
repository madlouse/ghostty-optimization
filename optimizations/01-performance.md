# 性能优化方案

## 01. GPU 渲染优化

### 配置项
```
# 启用 Metal 渲染（macOS）
macos-titlebar-style = native

# 减少渲染延迟
cursor-style = block
cursor-style-blink = false
```

### 效果
- 降低 CPU 使用率
- 提升渲染帧率
- 减少输入延迟

### 验证
```bash
# 测试大量输出性能
cat large_file.log
```

---

## 02. 内存优化

### 配置项
```
# 限制滚动缓冲区
scrollback-limit = 10000

# 禁用不必要的功能
shell-integration = false
```

### 效果
- 减少内存占用
- 提升长时间运行稳定性

---

## 03. 字体渲染优化

### 配置项
```
font-family = "JetBrains Mono"
font-size = 14
font-thicken = true
font-feature = -calt  # 禁用连字（可选）
```

### 效果
- 更清晰的字体显示
- 减少字体渲染开销
