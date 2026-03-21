# BruceBlue Ghostty 优化建议

> 来源: https://x.com/BruceBlue/status/2032703807189299694
> 作者: BruceBlue 🌊
> 日期: 2026-03-14

## 核心优化建议

### 1. 性能优化
- **GPU 加速**: macOS 使用 Metal 渲染
- **滚动性能**: 即使 Claude 输出再长也不卡，滚动丝滑

### 2. 视觉优化
- **主题**: Catppuccin Mocha（紫色主题）
- **透明毛玻璃**: 原生 macOS 界面
- **字体连字**: 完美连字字体支持
- **图形协议**: 支持 Kitty 图形协议（图片直接在终端显示）

### 3. 分屏管理（核心功能）

**快捷键配置**:
```
# 左右分屏
keybind = cmd+d=new_split:right

# 上下分屏
keybind = cmd+shift+d=new_split:down

# 一键放大当前屏幕
keybind = cmd+shift+enter=toggle_split_zoom

# 关闭当前屏幕
keybind = cmd+w=close_surface

# 重载配置
keybind = cmd+shift+comma=reload_config
```

### 4. Quick Terminal（下拉幽灵终端）
- 全局快捷键呼出
- 自动隐藏
- 适合快速命令

### 5. 布局永久保存
```
window-save-state = always
```

## 推荐配置仓库

BruceBlue 的完整配置: https://github.com/BruceLanLan/bruceblue-ghostty-config

## 美化建议

### Starship 彩虹状态栏
```bash
brew install starship
starship preset catppuccin-powerline -o ~/.config/starship.toml
```

在 `~/.zshrc` 添加:
```bash
eval "$(starship init zsh)"
```

### 监控工具
```bash
brew install fastfetch btop
```

## 使用场景

### Claude Code 最佳实践
1. **左右分屏**: 左边 Claude 写代码，右边 debug
2. **一键放大**: `Cmd + Shift + Enter` 查看 Claude 长输出
3. **多屏监控**:
   - 左: Claude 开发
   - 右上: fastfetch（系统信息）
   - 右下: btop（实时 CPU 监控）

## 核心优势

1. **速度**: GPU 加速，不卡顿
2. **美观**: 原生界面 + 主题支持
3. **实用**: 分屏管理 + 图形协议
4. **稳定**: 布局永久保存

---

**提取日期**: 2026-03-16
**提取人**: Claude (via bb-browser)
