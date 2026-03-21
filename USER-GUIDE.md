# Ghostty 实用指南

> 从使用者角度出发的日常使用手册

## 🚀 日常启动

### 方式一：Spotlight 启动
1. 按 `Cmd + 空格`
2. 输入 "Ghostty"
3. 回车

### 方式二：Quick Terminal（推荐）
- 按 `Ctrl + ~`（波浪号键）
- 全局快捷键，随时呼出
- 再按一次自动隐藏

## ⌨️ 核心快捷键（必记）

### 分屏管理
```
Cmd + Alt + D          # 右侧新增分屏
Cmd + Alt + Shift + D  # 下方新增分屏
Cmd + Alt + Enter      # 放大/还原当前分屏
Cmd + W                # 关闭当前分屏
```

### 分屏导航
```
Cmd + Alt + ←/→/↑/↓   # 切换到左/右/上/下分屏
```

### 其他常用
```
Cmd + K                # 清屏
Cmd + Shift + ,        # 重载配置
Cmd + Q                # 退出 Ghostty
```

## 💡 实用场景

### 场景 1：Claude Code 开发
```
1. Cmd + Alt + D        # 右侧分屏
2. 左边：claude         # 启动 Claude Code
3. 右边：btop           # 监控系统资源
4. Cmd + Alt + Enter    # 需要时放大 Claude 输出
```

### 场景 2：系统监控
```
1. Cmd + Alt + D              # 右侧分屏
2. 左边：fastfetch            # 系统信息
3. 右边：btop                 # 实时监控
4. Cmd + Alt + Shift + D      # 下方再加一屏
5. 下方：tail -f app.log      # 查看日志
```

### 场景 3：多项目开发
```
1. Cmd + Alt + D        # 右侧分屏
2. 左边：cd project-a   # 项目 A
3. 右边：cd project-b   # 项目 B
4. 鼠标点击切换焦点
```

## 🎨 个性化调整

### 修改配置
```bash
open ~/.config/ghostty/config
```

### 常用调整项
```
# 字体大小
font-size = 16

# 窗口内边距
window-padding-x = 14
window-padding-y = 10

# 透明度（可选）
background-opacity = 0.95
background-blur-radius = 20
```

### 应用配置
修改后按 `Cmd + Shift + ,` 重载

## 🔧 实用命令

### 系统信息
```bash
fastfetch              # 快速查看系统信息
```

### 资源监控
```bash
btop                   # 实时 CPU/内存/进程监控
# 按 q 退出
```

### 测试分屏
```bash
# 左边
echo "Left pane"

# 右边（Cmd + Alt + D 后）
echo "Right pane"
```

## 🎯 效率技巧

### 1. 布局自动保存
- 分屏布局会自动保存
- 下次打开自动恢复
- 无需手动配置

### 2. 快速清屏
- `Cmd + K` 比 `clear` 更快
- 保留滚动历史

### 3. 复制粘贴
- 选中文本自动复制到剪贴板
- `Cmd + V` 粘贴
- 自动清理尾随空格

### 4. 搜索历史
- `Ctrl + R` 搜索命令历史
- 配合 Starship 状态栏更直观

## ⚠️ 常见问题

### Q: 启动时出现两个窗口？
A: 一个是主窗口，一个是 Quick Terminal。按 `Ctrl + ~` 隐藏 Quick Terminal。

### Q: 分屏后字体太小？
A: 修改 `font-size` 配置，或使用 `Cmd + Alt + Enter` 放大单个分屏。

### Q: 配置修改后没生效？
A: 按 `Cmd + Shift + ,` 重载配置。

### Q: 如何恢复默认配置？
A: 备份在 `~/dev/ghostty-optimization/current-config/config.backup`

## 📚 进阶使用

### 自定义快捷键
在 config 中添加：
```
keybind = cmd+t=new_tab
keybind = cmd+1=goto_tab:1
```

### 主题切换
```
# 自动切换
theme = light:Catppuccin Latte,dark:Catppuccin Mocha

# 固定主题
theme = Catppuccin Mocha
```

## 🎓 学习资源

- 官方文档: https://ghostty.org/
- BruceBlue 配置: https://github.com/BruceLanLan/bruceblue-ghostty-config
- 本地优化项目: `~/dev/ghostty-optimization/`
