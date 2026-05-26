# MacQwenVoice Project Instructions

- 默认使用中文写面向人的说明文档；代码标识、模型名、CLI 参数保持英文。
- 目标是 Apple Silicon Mac 上的离线 Qwen3-TTS 创作者工作台，不承诺 Intel Mac。
- 模型默认来自 `mlx-community` 的 Qwen3-TTS MLX 量化权重；下载后运行态必须能离线。
- 不把模型权重、用户音频、生成音频、SQLite 数据库或缓存提交进 git。
- SwiftUI 前端负责项目、音色、模型、历史和播放；Python 后端负责 MLX 推理与 JSON-RPC。
- 声音克隆必须经过本地授权确认，并保存本地 consent record。
