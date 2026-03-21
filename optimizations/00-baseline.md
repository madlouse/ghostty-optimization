# 基础配置 (Baseline)

## 配置文件位置
- macOS: `~/.config/ghostty/config`

## 核心基础配置

### 字体设置
```
font-family = "JetBrains Mono"
font-size = 14
font-thicken = true
```

### 性能优化
```
# GPU 加速
macos-option-as-alt = true

# 滚动性能
scrollback-limit = 10000
```

### 外观
```
# 主题
theme = dark

# 窗口
window-padding-x = 8
window-padding-y = 8
window-decoration = true
```

## 验证方法
1. 重启 Ghostty
2. 检查字体渲染是否清晰
3. 测试滚动流畅度
