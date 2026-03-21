# Ghostty 故障排除

## 常见问题

### 1. 启动时报错 "failed to launch the requested command"

**症状**：
```
Ghostty failed to launch the requested command:
/usr/bin/login -flp jeking exit
```

**原因**：Ghostty 保存了错误的窗口状态

**解决方案**：
```bash
# 清除保存的状态
rm -rf ~/Library/Saved\ Application\ State/com.mitchellh.ghostty.savedState

# 重新打开 Ghostty
open -a Ghostty
```

---

### 2. 快捷键不生效

**症状**：按 `Cmd + Option + D` 没有分屏

**解决方案**：
```bash
# 重载配置
Cmd + Shift + ,

# 或完全重启
Cmd + Q
然后重新打开
```

---

### 3. 配置修改后没效果

**检查步骤**：
1. 确认配置文件位置：`~/.config/ghostty/config`
2. 检查语法错误
3. 重载配置：`Cmd + Shift + ,`

---

### 4. 恢复默认配置

```bash
# 使用备份恢复
cp ~/dev/ghostty-optimization/current-config/config.backup ~/.config/ghostty/config
```

---

## 快速诊断

```bash
# 检查配置文件
cat ~/.config/ghostty/config

# 检查 Ghostty 进程
ps aux | grep ghostty

# 查看日志（如果有）
ls ~/Library/Logs/Ghostty/
```
