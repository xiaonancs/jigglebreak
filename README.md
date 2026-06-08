# JiggleBreak

一个轻量的 macOS 菜单栏小工具，集成了三个常用功能：

- **Mouse Jiggler**：定时模拟鼠标微动，防止系统因为闲置而休眠 / 锁屏。
- **Keep Awake**：保持系统唤醒状态。
- **Break Reminder**：定时弹出久坐提醒气泡，提醒你起身休息。

## 系统要求

- macOS 13.0 或更高版本
- 部分功能需要授予「辅助功能（Accessibility）」权限

## 安装

### 方式一：直接下载安装包（推荐）

从 [Releases](../../releases) 页面下载最新的 `JiggleBreak-x.y.z.zip`，解压后将 `JiggleBreak.app` 拖入 `/Applications`。

仓库内也提供了一份打包好的安装包：[`dist/JiggleBreak-0.1.0.zip`](dist/JiggleBreak-0.1.0.zip)。

> 首次打开时，如果系统提示「无法验证开发者」，可在「系统设置 → 隐私与安全性」中点击「仍要打开」。

### 方式二：从源码构建

需要安装 Xcode / Swift 工具链：

```bash
# 构建 .app
./scripts/build-app.sh

# 构建并安装到 /Applications
./scripts/install-app.sh
```

## 项目结构

```
Sources/JiggleBreak/      Swift 源码
  Features/               各功能模块（Jiggler / Awake / Reminder）
  Permissions/            辅助功能权限处理
  Settings/               设置项
Resources/                应用图标等资源
scripts/                  构建 / 安装 / 校验脚本
dist/                     打包好的安装包
```

## 构建命令

```bash
swift build -c release        # 编译可执行文件
./scripts/build-app.sh        # 打包成 JiggleBreak.app
./scripts/install-app.sh      # 安装到 /Applications
./scripts/verify.sh           # 校验
```

## License

Copyright 2026.
