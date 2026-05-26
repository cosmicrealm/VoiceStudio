# Voice Studio

Voice Studio 是面向 Apple Silicon Mac 的本地语音创作工具，提供精品音色生成、音色克隆、创造音色、对话生成和对话改写等能力。项目重点服务小说、短剧、旁白、角色对白和多角色音频创作，让用户可以在一个桌面 App 内完成从文本改写、角色配音到完整音频导出的流程。

当前发布版本：`0.01`。

## 核心功能

- 精品音色生成：选择内置音色，输入文本后快速生成旁白、讲解、口播或角色语音。
- 音色克隆：导入或录制参考音频，保存为本地可复用音色。
- 创造音色：用自然语言描述一个角色声音，生成参考音色并保存到音色库。
- 对话生成：为旁白和多个角色绑定不同音色，逐句生成并合并成完整对话音频。
- 对话改写：把小说或长文本改写成“旁白 + 角色台词”的结构，便于直接进入对话生成。
- 多角色音色组合：同一个项目里可以组合多个已保存音色，为不同角色绑定不同声线。
- 播放与导出：支持播放、暂停、拖动进度、生成历史、单段导出和全文导出。
- Voice Tools：支持导入常见音频格式，并合并为统一的 WebM 音频。

## 截图

### Script Studio 对话生成

![Script Studio 对话生成](docs/assets/voice-studio-dialogue-generation.png)

### VoiceDesign 创造音色

![VoiceDesign 创造音色](docs/assets/voice-studio-voice-design.png)

### DeepSeek 对话改写

![DeepSeek 对话改写](docs/assets/voice-studio-dialogue-rewrite.png)

## 对话音频示例

0.01 发布版附带一段多角色对话生成示例，展示从角色音色绑定、逐句生成到完整音频合并的效果。

- [在线播放示例音频](../../releases/download/v0.01/Voice-Studio-0.01-dialogue-demo.webm)
- Release 附件：`Voice-Studio-0.01-dialogue-demo.webm`
- 离线预览页：`Voice-Studio-0.01-dialogue-demo.html`
- 对应文本：`Voice-Studio-0.01-dialogue-demo.transcript.json`

离线预览页内嵌同一段示例音频，并在页面右侧展示对应文本，适合在未联网或未打开 Release 页面时核对音频与脚本。

## 安装与运行

### 下载发布版

从 Release 页面下载：

```text
Voice-Studio-0.01-macOS-arm64.zip
```

解压后打开 `Voice Studio.app`。首次打开如果 macOS 提示未验证开发者，请在系统安全设置中允许打开。

### 从源码运行

```bash
swift run MacQwenVoice
```

### 打包本地 App

```bash
scripts/build_app_bundle.sh
open "dist/Voice Studio.app"
```

### 生成发布包

```bash
scripts/package_release.sh
```

发布包会生成到 `dist/` 目录。

## 首次使用

1. 打开 `Voice Studio.app`。
2. 进入 `模型` 页面，下载需要的语音模型。
3. 回到 `Script Studio`，选择精品生成、克隆生成、创造生成或对话生成。
4. 输入文本、选择音色并生成音频。

默认工作区位于：

```text
~/Documents/VoiceStudio/Workspace/
```

模型、项目、参考音频、生成音频、数据库和配置都会保存在本机工作区内。

## 工作流

### 精品生成

适合快速生成旁白、口播、讲解和单角色语音。选择内置音色后输入文本即可生成，也可以使用控制指令调整声音表现。

### 克隆生成

适合复用已有声音。用户导入或录制参考音频，填写对应文本和授权用途后保存为本地音色；后续可以在克隆生成和对话生成中复用。

### 创造音色

适合创建新角色声音。用户用自然语言描述年龄、气质、语速、情绪、叙事风格等特征，生成满意后保存为角色音色。

### 对话生成

适合短剧、小说片段和多角色对白。用户可以为旁白、主角、配角分别绑定音色，系统会按角色逐句生成，并合并为完整音频。

这是 0.01 的重点能力：先为角色创造音色，再把这些音色作为可复用参考，用于多角色对话生成。

### 对话改写

对话改写可以把长文本整理为 Voice Studio 更容易识别的脚本格式：

```text
旁白: ...
角色A: ...
角色B: ...
```

改写会尽量保留原意和信息点，让旁白负责环境、动作和信息承接，让角色台词负责冲突推进和情绪表达。DeepSeek API key 可在 `设置` 页面配置。

### Voice Tools

Voice Tools 用于音频整理和合并。支持 `wav`、`mp3`、`m4a`、`aac`、`flac`、`ogg`、`opus`、`aiff`、`aif`、`caf`、`webm` 等常见格式，扩展名大小写不敏感。

## 系统要求

- Apple Silicon Mac。
- macOS 14 或更新版本。
- Python 3.10+。
- `ffmpeg`。
- `hf` CLI。
- 本地语音运行依赖，包括 `mlx`、`mlx_audio`、`transformers`、`numpy`。

如需指定 Python 环境，可以在启动前设置：

```bash
export MACQWENVOICE_PYTHON="/path/to/python3"
open "dist/Voice Studio.app"
```

## 隐私与数据

- 参考音频、生成音频、项目数据和本地数据库默认保存在用户本机。
- DeepSeek API key 保存在本地工作区配置中。
- 音色克隆需要用户明确填写授权用途。
- 模型权重不随 App 分发，需要用户自行在模型页下载。

## 开发验证

```bash
swift test
python3 -m unittest discover -s backend/tests -v
```

## 已知限制

- 0.01 是预发布版本，界面和数据结构后续仍可能调整。
- 当前仅面向 Apple Silicon Mac，不承诺 Intel Mac。
- 发布包使用 ad-hoc codesign，尚未 notarize。
- DeepSeek 对话改写和指令增强需要联网和用户自己的 API key。
- 创造音色的稳定性受模型和提示词影响，复杂角色建议多次生成、试听并保存后再用于对话生成。
