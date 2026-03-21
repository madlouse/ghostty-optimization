# Setup — 快速部署

## 一键安装

```bash
# 方式 1: Homebrew (推荐)
brew tap madlouse/ghostty https://github.com/madlouse/homebrew-ghostty
brew install ghostty-cmux

# 方式 2: 手动
git clone https://github.com/madlouse/ghostty-optimization.git ~/dev/ghostty-optimization
bash ~/dev/ghostty-optimization/setup/bootstrap.sh
```

## 部署流程

```
bootstrap.sh
├── 1. 检查 Homebrew
├── 2. brew bundle install (Brewfile)
├── 3. 部署全部配置
│   ├── Ghostty / Cmux
│   ├── Starship
│   ├── Zed
│   ├── .zprofile
│   ├── Zsh Completions
│   └── Claude Code Hooks
├── 4. 兼容性检查
└── 5. 验证
```

## 同步配置到仓库

当前机器改完配置后：

```bash
cd ~/dev/ghostty-optimization
cp ~/.config/ghostty/config setup/backup/ghostty-config
cp ~/.config/starship.toml setup/backup/starship.toml
cp ~/.config/zed/settings.json setup/backup/zed/settings.json
cp ~/.zprofile setup/backup/zprofile
cp ~/.zsh/completions/_opencli setup/backup/zsh-completions/_opencli
cp ~/.claude/hooks/cmux-notify-hook.sh setup/backup/claude-hooks/
git add -A && git commit -m "sync configs" && git push
```

新电脑 `brew upgrade ghostty-cmux` 即自动拉取。

## 包含的备份

| 文件 | 说明 |
|------|------|
| `Brewfile` | 全部 brew 包 (公式 + cask) |
| `ghostty-config` | Ghostty / Cmux 配置 |
| `starship.toml` | Starship prompt |
| `zprofile` | .zprofile |
| `zshrc-append` | .zshrc 追加内容 |
| `zed/settings.json` | Zed 配置 |
| `zsh-completions/_opencli` | Zsh 补全 |
| `claude-hooks/cmux-notify-hook.sh` | Claude Code 通知 Hook |

## 敏感信息

以下内容需在新机器手动配置（不在仓库中）：
- API Keys (`GROK_API_KEY`, `JONE_AUTH_TOKEN` 等)
- 代理设置
- SSH / GPG 密钥
