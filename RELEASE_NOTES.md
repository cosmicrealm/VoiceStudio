# Voice Studio 0.01 Release Notes

Voice Studio 0.01 是 Apple Silicon Mac 上的本地语音创作工具首个预发布版本，面向小说、短剧、旁白、角色对白和多角色音频创作。

## 核心亮点

- 支持精品音色生成、音色克隆和创造音色。
- 支持“先创造，再克隆复用”的多角色对话生成：
  - 用 VoiceDesign 为旁白、主角、配角创建角色音色。
  - 保存为可复用音色后，在对话生成中按角色绑定。
  - 逐句生成并合并为完整音频。
- 支持多角色音色组合创建：
  - 同一个对话项目可以组合多个已保存角色声线。
  - 支持选择全部创造音色、按角色名匹配绑定、逐角色试听和生成。
- 支持 DeepSeek 对话改写：
  - 把小说或长文本改写成自然的“旁白 + 角色台词”脚本。
  - 强调保持原意和信息点，不做摘要式删减。
  - 旁白负责环境、动作、心理和信息承接，角色台词负责冲突推进和情绪表达。

## 新增功能

- Script Studio 四工作流：精品生成、克隆生成、创造生成、对话生成。
- 内置 CustomVoice 精品音色列表和中文显示名。
- VoiceDesign 创造音色页面：语言、控制指令、合成文本、DeepSeek 增强、保存为角色音色。
- 对话生成：角色声线绑定、角色音色池、逐句生成、合并完整音频。
- 对话改写：DeepSeek 生成多角色脚本和角色声音建议。
- Voice Tools：导入主流音频格式并统一转码合并。
- 播放体验：播放/暂停、进度显示、生成结果进度条拖动。
- 页面草稿状态保留：切到设置或其他页面再回来，不再重置创造音色和对话改写输入。
- 模型页一键安装/修复本机运行环境，优先使用 Homebrew `python@3.12` 创建 Voice Studio 专用 Python venv，并显示安装进度、实时日志、旧 venv 重建提示和 SSL/LibreSSL 兼容提示。
- 模型下载页：支持官方源、镜像源和自定义下载源。
- 设置页：集中管理 DeepSeek API key。

## 下载与安装

发布包：

```text
Voice-Studio-0.01-macOS-arm64.dmg
Voice-Studio-0.01-macOS-arm64.dmg.sha256
```

Release 展示资源：

```text
Voice-Studio-0.01-dialogue-demo.mp3
Voice-Studio-0.01-dialogue-demo.mp3.sha256
```

Release 页面提供 `Voice-Studio-0.01-dialogue-demo.mp3` 对话音频示例。源码 README 已加入合成文本、HTML 播放页入口和 Script Studio 对话生成、VoiceDesign、DeepSeek 对话改写界面预览。

打开 DMG 后，将 App 拖入 Applications，再启动：

```bash
open "/Applications/Voice Studio.app"
```

首次打开如果 macOS 提示未验证开发者，请在系统安全设置中允许打开。当前 0.01 使用 ad-hoc codesign，尚未 notarize。

## 运行依赖

- Apple Silicon Mac，macOS 14+。
- Python 3.12，推荐 Homebrew `python@3.12`。
- 网络连接，用于首次安装运行环境和下载模型。
- `ffmpeg`；模型页的一键安装会在 Homebrew 可用时自动安装。
- `mlx`、`mlx_audio`、`transformers`、`numpy`；模型页的一键安装会装到 Voice Studio 专用 Python venv。

可用 `MACQWENVOICE_PYTHON` 指定 Python：

```bash
export MACQWENVOICE_PYTHON="/path/to/python3"
open "Voice Studio.app"
```

## 模型

模型权重不随 App 分发，需要在 `模型` 页面下载。

默认模型：

- `mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-8bit`
- `mlx-community/Qwen3-TTS-12Hz-0.6B-Base-8bit`
- `mlx-community/Qwen3-TTS-12Hz-1.7B-CustomVoice-8bit`
- `mlx-community/Qwen3-TTS-12Hz-1.7B-Base-8bit`
- `mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-8bit`

## 已知限制

- 仅面向 Apple Silicon Mac，不承诺 Intel Mac。
- 当前是 `0.01` 预发布版本，UI 和数据结构仍可能继续调整。
- 发布包尚未 notarize。
- DeepSeek 对话改写和指令增强需要联网和用户自己的 API key。
- TTS 推理本身以本地模型为主，模型下载完成后可离线运行。
- VoiceDesign 输出稳定性依赖模型和提示词；复杂角色建议先多次生成、试听、保存，再用于多角色对话生成。

## 验证命令

```bash
swift test
python3 -m unittest discover -s backend/tests -v
scripts/package_release.sh
```
