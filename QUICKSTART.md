# 快速开始指南

## 1. 查看项目结构

```bash
cd ~/dev/ghostty-optimization
tree
```

## 2. 备份当前配置（已完成）

✅ 当前配置已备份到 `current-config/config.backup`

## 3. 提取 BruceBlue 文章内容

**手动步骤**:
1. 在浏览器打开: https://x.com/BruceBlue/status/2032703807189299694
2. 阅读完整内容
3. 将优化建议填写到 `resources/bruceblue-tips.md`

## 4. 应用优化

### 方法 A: 逐步应用
```bash
# 查看各个优化方案
cat optimizations/01-performance.md
cat optimizations/02-ux.md
cat optimizations/03-theme.md

# 选择性添加到配置文件
vim ~/.config/ghostty/config
```

### 方法 B: 测试新配置
```bash
# 创建测试配置
cp current-config/config.backup test-config.txt
# 编辑添加新优化
vim test-config.txt
# 应用测试
cp test-config.txt ~/.config/ghostty/config
```

## 5. 验证效果

```bash
# 重启 Ghostty
# 运行性能测试
cd benchmarks
# 按照 performance-tests.md 中的步骤测试
```

## 6. 记录结果

```bash
# 更新 CHANGELOG.md
vim CHANGELOG.md
```

## 项目文件说明

- `README.md` - 项目总览
- `ITERATION.md` - 迭代优化流程
- `CHANGELOG.md` - 变更历史
- `current-config/` - 当前配置备份
- `optimizations/` - 各类优化方案
- `benchmarks/` - 性能测试方法
- `resources/` - 参考资料
