# 增量优化方案

> 基于 BruceBlue 文章和当前配置的对比分析

## 当前配置 vs BruceBlue 建议

### ✅ 已实现的优化

1. **字体配置** - 已优化
   - 当前: JetBrainsMono Nerd Font, 16pt, ligatures
   - BruceBlue: 推荐连字字体 ✓

2. **主题** - 已优化
   - 当前: Catppuccin (自动切换 Light/Dark)
   - BruceBlue: Catppuccin Mocha ✓

3. **分屏管理** - 已实现
   - 当前: `cmd+alt+d` (右分屏), `cmd+alt+shift+d` (下分屏)
   - BruceBlue: `cmd+d` (右分屏), `cmd+shift+d` (下分屏)
   - **差异**: 快捷键不同

4. **放大功能** - 已实现
   - 当前: `cmd+alt+enter` (toggle_split_zoom)
   - BruceBlue: `cmd+shift+enter`
   - **差异**: 快捷键不同

5. **Quick Terminal** - 已实现
   - 当前: `ctrl+grave_accent` (全局热键)
   - BruceBlue: 提到下拉幽灵终端 ✓

6. **布局保存** - 已实现
   - 当前: `window-save-state = always`
   - BruceBlue: 推荐永久保存 ✓

### 🔄 可优化项

1. **快捷键统一** (可选)
   - 考虑是否改为 BruceBlue 的快捷键方案
   - 当前方案: `cmd+alt+...` (避免冲突)
   - BruceBlue: `cmd+...` (更简洁)

2. **滚动缓冲区**
   - 当前: 10MB (10000000)
   - BruceBlue: 未明确提及
   - **建议**: 保持当前配置（适合 AI 输出）

3. **透明度和模糊** (可选)
   - 当前: 未配置
   - BruceBlue: 提到透明毛玻璃
   - **可添加**:
     ```
     background-opacity = 0.95
     background-blur-radius = 20
     ```

### ➕ 新增建议

1. **Starship 状态栏**
   ```bash
   brew install starship
   starship preset catppuccin-powerline -o ~/.config/starship.toml
   ```

   在 `~/.zshrc` 添加:
   ```bash
   eval "$(starship init zsh)"
   ```

2. **监控工具**
   ```bash
   brew install fastfetch btop
   ```

## 优化优先级

### 高优先级
- [ ] 安装 Starship 状态栏（视觉提升明显）
- [ ] 安装 fastfetch 和 btop（监控工具）

### 中优先级
- [ ] 考虑添加透明度和模糊效果
- [ ] 评估是否调整快捷键（当前方案已经很好）

### 低优先级
- [ ] 探索 Kitty 图形协议的使用场景

## 下一步行动

1. **立即可做**:
   ```bash
   # 安装 Starship
   brew install starship
   starship preset catppuccin-powerline -o ~/.config/starship.toml
   echo 'eval "$(starship init zsh)"' >> ~/.zshrc

   # 安装监控工具
   brew install fastfetch btop
   ```

2. **可选配置** (添加到 config):
   ```
   # 透明度和模糊
   background-opacity = 0.95
   background-blur-radius = 20
   ```

3. **测试场景**:
   - 左: `claude` (Claude Code)
   - 右上: `fastfetch` (系统信息)
   - 右下: `btop` (CPU 监控)

## 总结

你的当前配置已经非常优秀，包含了 BruceBlue 建议的大部分核心功能。主要差异在于：
- 快捷键方案不同（你的更安全，避免冲突）
- 缺少 Starship 状态栏（纯视觉增强）
- 可选添加透明度效果

**建议**: 保持当前配置，只添加 Starship 和监控工具即可。
