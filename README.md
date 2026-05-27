# Voice Studio

English | [中文](README_CN.md)

Voice Studio is a local voice creation workspace for Apple Silicon Macs. It brings premium voice generation, voice cloning, voice design, dialogue generation, and dialogue rewrite into one desktop app for novels, audio drama, narration, character dialogue, and multi-role voice projects.

Current release: `0.01`.

## Download

- [Download the macOS DMG](https://github.com/cosmicrealm/VoiceStudio/releases/download/v0.01/Voice-Studio-0.01-macOS-arm64.dmg)

## Audio Demo

The `0.01` release includes a multi-role dialogue sample generated in Voice Studio. It demonstrates role binding, per-line synthesis, and final full-audio export.

<table>
  <thead>
    <tr>
      <th>Synthesis Text</th>
      <th>Audio Sample</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td width="64%" valign="top">
        <details>
          <summary>Show the demo text excerpt</summary>
          <pre>旁白: 航行又持续了两个多小时，如果在三维，太空艇已经航行了二十万千米左右。突然间，硬币大小的“魔戒”顶天立地地出现在前方。
卓文: 紧急转向！
旁白: 卓文用目光操纵太空艇紧急转向，使撞向环箍的太空艇从“魔戒”的圆环中穿过。从艇中看去，像是通过了太空中一道巨大的拱门。
关一帆: 我看不出后六个数的规律。
韦斯特: 那就假设没有规律。前六个数是我们发送的，最可能的含义就是表示我们，后六个数没有规律且不断出现不同的组合，可能代表“一切”，我们的一切。
魔戒: 我是墓地。
关一帆: 谁的墓地？
魔戒: 这个墓地的建造者的墓地。
褚岩: 立刻返回，登上“魔戒”的计划取消了。</pre>
        </details>
      </td>
      <td width="36%" valign="top">
        <a href="https://cosmicrealm.github.io/VoiceStudio/dialogue-demo.html">
          <img alt="Open audio demo" src="https://img.shields.io/badge/%E2%96%B6-Open_Audio_Demo-0969da?style=for-the-badge">
        </a>
      </td>
    </tr>
  </tbody>
</table>

## Product Preview

### Script Studio Dialogue Generation

![Script Studio dialogue generation](docs/assets/voice-studio-dialogue-generation.png)

### VoiceDesign Voice Creation

![VoiceDesign voice creation](docs/assets/voice-studio-voice-design.png)

### DeepSeek Dialogue Rewrite

![DeepSeek dialogue rewrite](docs/assets/voice-studio-dialogue-rewrite.png)

## Highlights

- Premium voice generation: choose a built-in voice and generate narration, explainer audio, spoken content, or character speech.
- Voice cloning: import or record reference audio, confirm local authorization, and save reusable local voices.
- Voice design: describe a new voice in natural language, generate a reference voice, and save it to the voice library.
- Dialogue generation: bind different voices to narration and multiple characters, synthesize line by line, and export a complete dialogue track.
- Dialogue rewrite: use DeepSeek to turn long prose into a structured script with narration and character lines while preserving the original meaning.
- Multi-role voice composition: combine several saved or designed voices in one project and bind them to different roles.
- Playback and export: play, pause, scrub progress, review generation history, export single segments, and export full dialogue audio.
- Voice Tools: import common audio formats and merge them into a unified WebM workflow.
- Interface languages: System, English, Simplified Chinese, Traditional Chinese, Japanese, Korean, German, French, Russian, Portuguese, Spanish, and Italian.

## Installation and First Run

If macOS shows an unidentified developer warning on first launch, allow Voice Studio from System Settings > Privacy & Security.

Open the app, go to `Models`, install or repair the local runtime, download the models you need, then return to `Script Studio` to generate audio.

The default local workspace is:

```text
~/VoiceStudio/Workspace/
```

Models, projects, reference audio, generated audio, the local database, and configuration files are stored in this workspace by default.

If runtime setup fails, see [Runtime Setup](docs/runtime-setup.md).

## Workflows

### Premium Generation

Use built-in voices for quick narration, spoken content, explainers, and single-character speech. Voice instructions can adjust delivery style.

### Voice Cloning

Import or record reference audio, enter the matching reference text, confirm authorization, and save the voice locally for reuse.

### Voice Design

Create new character voices from natural language descriptions such as age, tone, pace, emotion, narration style, and personality.

### Dialogue Generation

Bind voices to narration and character roles, then generate each line and merge the results into one full audio file. A key `0.01` feature is the official Qwen3-TTS style workflow: create voices first, then reuse those voices for cloned-style multi-role dialogue generation.

### Dialogue Rewrite

Rewrite prose into a Voice Studio script format:

```text
Narrator: ...
Character A: ...
Character B: ...
```

The rewrite workflow keeps the original meaning and information points, while making narration carry actions and context and making character lines carry conflict and emotion. DeepSeek API configuration is available in `Settings`.

### Voice Tools

Voice Tools supports common audio formats such as `wav`, `mp3`, `m4a`, `aac`, `flac`, `ogg`, `opus`, `aiff`, `aif`, `caf`, and `webm`. File extensions are handled case-insensitively.

## System Requirements

- Apple Silicon Mac.
- macOS 14 or newer.
- Network access for first-time runtime setup and model downloads.
- Python 3.12. Homebrew `python@3.12` is recommended; the model page installer uses it to create a dedicated Voice Studio runtime when available.
- `ffmpeg`, used for audio export, conversion, and merging.
- Local voice runtime packages installed into the Voice Studio Python environment: `mlx`, `mlx_audio`, `transformers`, `numpy`, `huggingface_hub[cli]`, and `hf_transfer`.

To use a specific Python interpreter before launch:

```bash
export MACQWENVOICE_PYTHON="/path/to/python3"
open "dist/Voice Studio.app"
```

## Run from Source

```bash
swift run MacQwenVoice
```

Build a local app bundle:

```bash
scripts/build_app_bundle.sh
open "dist/Voice Studio.app"
```

Create a release package:

```bash
scripts/package_release.sh
```

Release artifacts are written to `dist/`.

## Privacy and Data

- Reference audio, generated audio, project data, and the local database stay on the user's Mac by default.
- The DeepSeek API key is saved in the local workspace configuration.
- Voice cloning requires an explicit local authorization purpose.
- Model weights are not bundled with the app and must be downloaded by the user from the model page.

## Development Checks

```bash
swift test
python3 -m unittest discover -s backend/tests -v
```

## Known Limitations

- `0.01` is a preview release; UI and local data structures may change.
- Only Apple Silicon Macs are targeted. Intel Macs are not supported.
- The release package currently uses ad-hoc codesign and is not notarized.
- DeepSeek dialogue rewrite and instruction enhancement require network access and the user's own API key.
- Voice design quality depends on model behavior and prompt wording. For complex characters, generate several versions, audition them, and save the best result before dialogue generation.
