#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import hashlib
import html
import json
import shutil
import subprocess
from pathlib import Path


TRANSCRIPT = [
    ("旁白", "欢迎来到 Voice Studio 的对话生成示例。"),
    ("创作者", "我先用创造音色做出角色声音，再把它保存成可复用的参考音。"),
    ("产品", "接着在 Script Studio 里绑定多个角色，逐句生成，并合并成一段完整音频。"),
    ("旁白", "这就是先创造，再克隆复用的多角色工作流。"),
]

DEMO_NOTES = [
    "VoiceDesign 先创造角色参考音色。",
    "Base Clone 复用参考音色逐句生成。",
    "Script Studio 将多角色片段合并为完整 WebM。",
]


def main() -> int:
    parser = argparse.ArgumentParser(description="Build a self-contained Voice Studio demo player HTML.")
    parser.add_argument("--audio", required=True, help="Path to the WebM demo audio.")
    parser.add_argument("--output", required=True, help="Path to the output HTML file.")
    parser.add_argument("--transcript-json", help="Optional JSON transcript: [{\"speaker\":\"旁白\",\"text\":\"...\"}].")
    args = parser.parse_args()

    audio_path = Path(args.audio).expanduser().resolve()
    output_path = Path(args.output).expanduser().resolve()
    if not audio_path.is_file():
        raise SystemExit(f"audio file not found: {audio_path}")

    audio_bytes = audio_path.read_bytes()
    audio_base64 = base64.b64encode(audio_bytes).decode("ascii")
    audio_sha256 = hashlib.sha256(audio_bytes).hexdigest()
    duration = probe_duration(audio_path)
    transcript = load_transcript(args.transcript_json)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        render_html(
            audio_filename=audio_path.name,
            audio_base64=audio_base64,
            audio_sha256=audio_sha256,
            audio_size=len(audio_bytes),
            duration=duration,
            transcript=transcript,
        ),
        encoding="utf-8",
    )
    return 0


def load_transcript(path: str | None) -> list[tuple[str, str]]:
    if not path:
        return TRANSCRIPT
    transcript_path = Path(path).expanduser().resolve()
    payload = json.loads(transcript_path.read_text(encoding="utf-8"))
    if not isinstance(payload, list):
        raise SystemExit("transcript JSON must be a list")

    transcript: list[tuple[str, str]] = []
    for item in payload:
        if isinstance(item, dict):
            speaker = str(item.get("speaker") or item.get("role") or "").strip()
            text = str(item.get("text") or item.get("content") or "").strip()
        elif isinstance(item, (list, tuple)) and len(item) >= 2:
            speaker = str(item[0]).strip()
            text = str(item[1]).strip()
        else:
            raise SystemExit("transcript items must be dicts or [speaker, text] pairs")
        if not text:
            continue
        transcript.append((speaker or "旁白", text))
    if not transcript:
        raise SystemExit("transcript JSON did not contain any usable lines")
    return transcript


def probe_duration(audio_path: Path) -> str:
    ffprobe = shutil.which("ffprobe")
    if ffprobe is None:
        return "未知"
    try:
        result = subprocess.run(
            [
                ffprobe,
                "-v",
                "error",
                "-show_entries",
                "format=duration",
                "-of",
                "json",
                str(audio_path),
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        payload = json.loads(result.stdout)
        seconds = float(payload["format"]["duration"])
    except Exception:
        return "未知"
    return f"{seconds:.1f} 秒"


def render_html(
    audio_filename: str,
    audio_base64: str,
    audio_sha256: str,
    audio_size: int,
    duration: str,
    transcript: list[tuple[str, str]],
) -> str:
    transcript_items = "\n".join(
        f"""
        <article class="line">
          <span class="speaker">{html.escape(speaker)}</span>
          <p>{html.escape(text)}</p>
        </article>
        """.strip()
        for speaker, text in transcript
    )
    note_items = "\n".join(f"<li>{html.escape(note)}</li>" for note in DEMO_NOTES)
    size_label = f"{audio_size / 1024:.1f} KB"
    return f"""<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Voice Studio 0.01 对话生成示例</title>
  <style>
    :root {{
      color-scheme: light;
      --text: #1d1d1f;
      --muted: #6e6e73;
      --line: #d9d9df;
      --panel: #ffffff;
      --soft: #f5f5f7;
      --accent: #2563eb;
      --accent-soft: #e8f0ff;
      --success: #24a148;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC", "Hiragino Sans GB", sans-serif;
      background: var(--soft);
      color: var(--text);
    }}
    main {{
      max-width: 1180px;
      margin: 0 auto;
      padding: 40px 28px;
    }}
    header {{
      margin-bottom: 22px;
    }}
    h1 {{
      margin: 0 0 8px;
      font-size: 30px;
      line-height: 1.2;
      letter-spacing: 0;
    }}
    .subtitle {{
      max-width: 760px;
      margin: 0;
      color: var(--muted);
      line-height: 1.7;
      font-size: 15px;
    }}
    .layout {{
      display: grid;
      grid-template-columns: minmax(320px, 0.85fr) minmax(380px, 1.15fr);
      gap: 18px;
      align-items: start;
    }}
    section {{
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 12px;
      padding: 20px;
    }}
    h2 {{
      margin: 0 0 14px;
      font-size: 17px;
      letter-spacing: 0;
    }}
    audio {{
      width: 100%;
      margin: 8px 0 16px;
    }}
    .meta {{
      display: grid;
      gap: 8px;
      margin: 0;
    }}
    .meta div {{
      display: grid;
      grid-template-columns: 90px minmax(0, 1fr);
      gap: 8px;
      font-size: 13px;
      line-height: 1.5;
    }}
    .meta dt {{
      color: var(--muted);
    }}
    .meta dd {{
      margin: 0;
      overflow-wrap: anywhere;
    }}
    .badge {{
      display: inline-flex;
      align-items: center;
      width: fit-content;
      padding: 4px 8px;
      margin-bottom: 14px;
      border-radius: 999px;
      background: #e8f8ee;
      color: var(--success);
      font-weight: 700;
      font-size: 12px;
    }}
    .notes {{
      margin: 16px 0 0;
      padding-left: 18px;
      color: var(--muted);
      line-height: 1.7;
      font-size: 14px;
    }}
    .transcript {{
      display: grid;
      gap: 10px;
    }}
    .line {{
      display: grid;
      grid-template-columns: 76px minmax(0, 1fr);
      gap: 12px;
      align-items: start;
      padding: 12px;
      border: 1px solid #ececf1;
      border-radius: 10px;
      background: #fbfbfd;
    }}
    .speaker {{
      display: inline-flex;
      justify-content: center;
      padding: 5px 8px;
      border-radius: 8px;
      background: var(--accent-soft);
      color: var(--accent);
      font-size: 13px;
      font-weight: 700;
      white-space: nowrap;
    }}
    .line p {{
      margin: 2px 0 0;
      line-height: 1.75;
      font-size: 15px;
    }}
    footer {{
      margin-top: 18px;
      color: var(--muted);
      font-size: 12px;
      line-height: 1.6;
    }}
    @media (max-width: 820px) {{
      main {{ padding: 24px 16px; }}
      .layout {{ grid-template-columns: 1fr; }}
      h1 {{ font-size: 24px; }}
      .line {{ grid-template-columns: 1fr; }}
      .speaker {{ justify-content: flex-start; }}
    }}
  </style>
</head>
<body>
  <main>
    <header>
      <h1>Voice Studio 0.01 对话生成示例</h1>
      <p class="subtitle">这是一段自包含 demo：音频已经嵌入在当前 HTML 文件中，旁边保留对应脚本，便于 release 页面、网盘预览或本地双击检查。</p>
    </header>
    <div class="layout">
      <section>
        <span class="badge">内嵌 WebM 可播放</span>
        <h2>音频</h2>
        <audio controls preload="metadata" src="data:audio/webm;base64,{audio_base64}"></audio>
        <dl class="meta">
          <div><dt>文件名</dt><dd>{html.escape(audio_filename)}</dd></div>
          <div><dt>时长</dt><dd>{html.escape(duration)}</dd></div>
          <div><dt>大小</dt><dd>{html.escape(size_label)}</dd></div>
          <div><dt>SHA256</dt><dd>{html.escape(audio_sha256)}</dd></div>
          <div><dt>生成链路</dt><dd>VoiceDesign 参考音色 -> Base Clone 逐句生成 -> WebM 合并</dd></div>
        </dl>
        <ul class="notes">
          {note_items}
        </ul>
      </section>
      <section>
        <h2>对应文本</h2>
        <div class="transcript">
          {transcript_items}
        </div>
      </section>
    </div>
    <footer>示例音频由本地 MLX / Qwen3-TTS 运行时生成，用于 Voice Studio 0.01 发布展示。</footer>
  </main>
</body>
</html>
"""


if __name__ == "__main__":
    raise SystemExit(main())
