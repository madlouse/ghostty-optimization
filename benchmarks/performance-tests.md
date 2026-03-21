# 性能基准测试

## 测试方法

### 1. 启动时间测试
```bash
time ghostty
```

### 2. 大文件渲染测试
```bash
# 生成测试文件
seq 1 10000 > test.txt

# 测试渲染性能
time cat test.txt
```

### 3. 内存使用测试
```bash
# 查看 Ghostty 内存占用
ps aux | grep ghostty
```

### 4. CPU 使用率测试
```bash
# 运行压力测试
while true; do echo "test"; done
# 观察 Activity Monitor 中的 CPU 使用率
```

## 基准数据

### 优化前
- 启动时间: ___ ms
- 内存占用: ___ MB
- CPU 使用率: ___ %
- 渲染帧率: ___ fps

### 优化后
- 启动时间: ___ ms
- 内存占用: ___ MB
- CPU 使用率: ___ %
- 渲染帧率: ___ fps

## 测试环境
- 设备: MacBook Pro M4
- 内存: 24GB
- macOS 版本: ___
- Ghostty 版本: ___
