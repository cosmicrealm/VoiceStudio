# Voice Studio 运行环境安装说明

Voice Studio 的 App 包不内置模型权重，也不直接内置完整 Python 推理环境。首次在一台新 Mac 上使用时，需要准备本机运行环境和模型文件。

## 推荐方式

打开 Voice Studio，进入 `模型` 页面，点击 `安装/修复运行环境`。

安装器会执行以下工作：

1. 检查当前 macOS、CPU 架构、Python 和 SSL 信息。
2. 优先使用 Homebrew `python@3.12` 创建独立运行环境，避免系统 Python 3.9 + LibreSSL 导致的 `urllib3` 兼容问题。
3. 创建专用 Python 环境：

```text
~/Library/Application Support/VoiceStudio/runtime/venv/
```

如果检测到旧环境仍然是 Python 3.9、或 SSL 仍然来自 LibreSSL，安装器会自动删除并重建这个 venv，避免继续复用旧依赖。

4. 安装推理和下载依赖：

```text
mlx
mlx-audio
transformers
numpy
huggingface_hub[cli]
hf_transfer
soundfile
```

其中 `huggingface_hub[cli]` 会提供模型下载命令 `hf`。安装器会把 venv 中的 `hf` 固定链接到：

```text
~/Library/Application Support/VoiceStudio/runtime/bin/hf
```

5. 检查 `ffmpeg` / `ffprobe`。如果 Homebrew 可用，会尝试自动安装 `ffmpeg`，并把可执行文件记录到 Voice Studio 的 runtime/bin 目录。
6. 验证 Python 依赖能否正常 import。

安装器会直接查找 `/opt/homebrew/bin/brew` 和 `/usr/local/bin/brew`，所以即使从 Finder 打开 App、系统 PATH 没有 Homebrew，也能识别常见 Homebrew 安装位置。

## 手动运行安装脚本

如果 App 内按钮没有显示完整日志，可以在终端运行同一个安装脚本。

从已安装 App 运行：

```bash
/bin/bash "/Applications/Voice Studio.app/Contents/Resources/scripts/install_runtime.sh"
```

从源码目录运行：

```bash
scripts/install_runtime.sh
```

## SSL / LibreSSL 问题

如果日志出现类似内容：

```text
urllib3 v2 only supports OpenSSL 1.1.1+, currently the ssl module is compiled with LibreSSL 2.8.3
```

说明当前 Python 使用的是系统自带 LibreSSL。推荐处理方式：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install python@3.12 ffmpeg
/bin/bash "/Applications/Voice Studio.app/Contents/Resources/scripts/install_runtime.sh"
```

如果不能安装 Homebrew，但系统里已经有可用的 Python 3.12，安装器会继续创建专用环境；如果只有系统 Python 3.9 或其他非 3.12 版本，安装器会停止并在日志里给出 Homebrew / `python@3.12` 的安装命令。这样做是为了避免用系统 Python 3.9 + LibreSSL 创建出不可用的运行环境。

## hf 命令缺失

如果模型下载日志出现：

```text
env: hf: No such file or directory
```

说明当前 App 进程找不到 Hugging Face CLI。推荐先重新运行 `安装/修复运行环境`。也可以手动安装：

```bash
python3.12 -m pip install --upgrade "huggingface_hub[cli]" hf_transfer
```

如果你已经在 Anaconda/Miniconda 里安装了 `hf`，新版 App 也会尝试查找常见路径，例如 `~/opt/anaconda3/bin/hf`、`~/anaconda3/bin/hf` 和 `~/miniconda3/bin/hf`。但正式运行仍建议使用 Voice Studio 自己的 runtime venv，避免 Finder 启动时 PATH 不一致。

## 模型下载

运行环境安装完成后，再回到 `模型` 页面下载模型。模型会保存在当前 workspace：

```text
~/Documents/VoiceStudio/Workspace/models/
```

如果模型下载失败，优先查看每个模型卡片下方的下载日志。常见原因包括网络不可达、Hugging Face 访问受限、镜像源不可用、workspace 路径无写权限。
