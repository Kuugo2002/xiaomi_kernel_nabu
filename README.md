# 小米平板5 (nabu) 非官方内核源码

欢迎来到小米平板5 (代号: `nabu`) 的定制内核源码仓库。本仓库提供基于 HyperOS 1.0 和 HyperOS 2.0 的内核源码，并提供了多种 KernelSU 集成版本以供选择。

## ✨ 核心特性

- 🚀 **全面支持 Droidspaces**：**所有分支**的 `defconfig` 中均已默认添加了对 **Droidspaces** 的支持，完美满足相关容器/虚拟化环境的需求。
- 🛡️ **丰富的 Root 方案**：提供纯净版、KernelSU、KernelSU-Next 以及 ReSuKisu 等多种分支，满足不同用户的玩机需求。
- ⚡ **自带自动化编译脚本**：提供功能完善的 `build.sh` 脚本，支持高度自定义的编译参数。

## 🌿 分支说明

本仓库包含 6 个主要分支，分别对应不同的系统版本和 Root 方案需求：

| 系统版本 | 纯净版 (无Root修补) | KernelSU-Next | ReSuKisu |
| :--- | :--- | :--- | :--- |
| **HyperOS 1.0** | `HyperOS1` | `HyperOS1-ksu-next` | `HyperOS1-resukisu` |
| **HyperOS 2.0** | `HyperOS2` | `HyperOS2-ksu-next` | `HyperOS2-resukisu` |

> **💡 提示**：
> - **不带任何后缀**的分支（如 `HyperOS1`、`HyperOS2`）为纯净版内核，未进行任何 Root 相关的代码修补。
> - 所有分支均已针对 **Droidspaces** 进行了内核配置优化。

## ⚠️ 兼容性与注意事项

- **Android 16**：**不支持**任何 Android 16 的版本。
- **HyperOS 2**：原装键盘无法使用，手写笔断触，有部分位置手写笔写不上。
- **v0.1 版本**：仅支持 cgroup v1。
- **v0.2 版本**：支持 cgroup v2，但 KernelSU 管理器无法更改应用 root 权限。


## 🛠️ 编译指南

仓库自带了一键编译脚本 `build.sh`，在编译前请确保你的环境已准备就绪。

### 1. 环境准备
- **Clang 编译器**：本仓库所需的 Clang 工具链已上传至本仓库的 **Release** 页面，请下载并解压到本地。脚本默认期望路径为 `$HOME/toolchains/clang-A15/bin`，你可以根据实际情况修改 `build.sh` 中的 `CLANG_PATH` 变量。
- **Make 版本要求**：编译 **HyperOS2** 系列分支时，**必须使用 Make 4.3 版本**。你可以在 Release 页面下载对应的 Make 4.3 并配置到环境变量中。

### 2. 修改编译脚本
打开 `build.sh`，根据你的本地环境修改相关路径（如有需要）：
```bash
# 修改 Clang 路径 (默认在 $HOME/toolchains/clang-A15/bin)
CLANG_PATH=${CLANG_PATH:-/你的/实际/clang/路径/bin}
```

### 3. 命令行参数说明
`build.sh` 支持丰富的命令行参数，你可以通过以下格式进行调用：
```bash
./build.sh [设备代号] [选项参数]
```

**参数列表：**

| 参数 | 说明 |
| :--- | :--- |
| `[设备代号]` | 指定目标设备，默认为 `nabu`。 |
| `-j <线程数>` | 指定编译使用的 CPU 线程数（默认使用全部核心 `nproc --all`）。 |
| `--noclean` | 跳过编译前的清理步骤（保留旧的构建目录，适合增量编译）。 |
| `--` | 分隔符，其后的所有参数将直接传递给底层的 `make` 命令。 |

**编译示例：**
```bash
# 赋予执行权限
chmod +x build.sh

# 使用默认配置编译 nabu
./build.sh 

# 指定 16 线程编译，并跳过清理步骤（增量编译）
./build.sh nabu -j16 --noclean
```

## 📦 下载与刷入

如果你不想自行编译，可以直接前往本仓库的 **Release** 页面下载已经编译好的 **AnyKernel3** 刷机包。
- 请在 Recovery (如 TWRP / OrangeFox) 中直接刷入对应的 ZIP 文件即可。

## 🙏 源码致谢

本仓库的内核源码基于以下优秀的开源项目进行移植和维护：

- **HyperOS 1.0 源码来源**：[Rave-Project / android_kernel_nabu_sm8150-ac](https://github.com/Rave-Project/android_kernel_nabu_sm8150-ac)
- **HyperOS 2.0 源码来源**：[sticpaper / sticpaper_kernel_source](https://github.com/sticpaper/sticpaper_kernel_source)
