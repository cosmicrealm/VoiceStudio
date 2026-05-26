from __future__ import annotations

import argparse
import contextlib
import dataclasses
import hashlib
import importlib.util
import inspect
import json
import math
import os
import random
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import threading
import time
import uuid
import wave
from pathlib import Path
from typing import Any


MODEL_CATALOG: list[dict[str, Any]] = [
    {
        "id": "qwen3-tts-12hz-0.6b-customvoice",
        "repository": "mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-8bit",
        "scale": "0.6B",
        "variant": "CustomVoice",
        "capability": "custom_voice",
        "bundle": "lite",
        "quantization": "8bit",
    },
    {
        "id": "qwen3-tts-12hz-0.6b-base",
        "repository": "mlx-community/Qwen3-TTS-12Hz-0.6B-Base-8bit",
        "scale": "0.6B",
        "variant": "Base",
        "capability": "voice_clone",
        "bundle": "lite",
        "quantization": "8bit",
    },
    {
        "id": "qwen3-tts-12hz-1.7b-customvoice",
        "repository": "mlx-community/Qwen3-TTS-12Hz-1.7B-CustomVoice-8bit",
        "scale": "1.7B",
        "variant": "CustomVoice",
        "capability": "custom_voice",
        "bundle": "pro",
        "quantization": "8bit",
    },
    {
        "id": "qwen3-tts-12hz-1.7b-base",
        "repository": "mlx-community/Qwen3-TTS-12Hz-1.7B-Base-8bit",
        "scale": "1.7B",
        "variant": "Base",
        "capability": "voice_clone",
        "bundle": "pro",
        "quantization": "8bit",
    },
    {
        "id": "qwen3-tts-12hz-1.7b-voicedesign",
        "repository": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-8bit",
        "scale": "1.7B",
        "variant": "VoiceDesign",
        "capability": "voice_design",
        "bundle": "advanced",
        "quantization": "8bit",
    },
]

USER_AUDIO_SUFFIX = ".webm"
LEGACY_AUDIO_SUFFIX = ".wav"
SUPPORTED_CONCAT_AUDIO_SUFFIXES = {
    USER_AUDIO_SUFFIX,
    LEGACY_AUDIO_SUFFIX,
    ".mp3",
    ".m4a",
    ".aac",
    ".flac",
    ".ogg",
    ".opus",
    ".aiff",
    ".aif",
    ".caf",
}


def segment_text(text: str, max_chars: int = 420) -> list[dict[str, Any]]:
    max_chars = max(1, max_chars)
    paragraphs = [part.strip() for part in normalize_synthesis_text(text).replace("\r\n", "\n").split("\n\n") if part.strip()]
    result: list[dict[str, Any]] = []
    for paragraph in paragraphs:
        for chunk in _chunks(paragraph, max_chars):
            result.append({"index": len(result), "text": chunk})
    return result


def _chunks(paragraph: str, max_chars: int) -> list[str]:
    if len(paragraph) <= max_chars:
        return [paragraph]
    units = _sentence_units(paragraph)
    if len(units) <= 1:
        return _hard_chunks(paragraph, max_chars)

    result: list[str] = []
    current = ""
    for unit in units:
        if len(unit) > max_chars:
            if current:
                result.append(current)
                current = ""
            result.extend(_hard_chunks(unit, max_chars))
        elif not current:
            current = unit
        elif len(current) + len(unit) <= max_chars:
            current += unit
        else:
            result.append(current)
            current = unit
    if current:
        result.append(current)
    return result


def _sentence_units(paragraph: str) -> list[str]:
    delimiters = set("。！？；，.!?;,")
    units: list[str] = []
    current = ""
    for char in paragraph:
        current += char
        if char in delimiters:
            unit = current.strip()
            if unit:
                units.append(unit)
            current = ""
    tail = current.strip()
    if tail:
        units.append(tail)
    return units


def _hard_chunks(text: str, max_chars: int) -> list[str]:
    return [text[start : start + max_chars].strip() for start in range(0, len(text), max_chars) if text[start : start + max_chars].strip()]


def _optional_int(value: Any) -> int | None:
    if value is None or value == "":
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _parent_process_is_alive(parent_pid: int | None) -> bool:
    if parent_pid is None or parent_pid <= 0:
        return True
    if os.getppid() == 1:
        return False
    try:
        os.kill(parent_pid, 0)
    except OSError:
        return False
    return True


def _start_parent_watchdog(parent_pid: int | None) -> None:
    if parent_pid is None or parent_pid <= 0:
        return

    def watch_parent() -> None:
        while True:
            time.sleep(1.0)
            if not _parent_process_is_alive(parent_pid):
                os._exit(0)

    thread = threading.Thread(target=watch_parent, name="parent-watchdog", daemon=True)
    thread.start()


def normalize_synthesis_text(text: str) -> str:
    lines: list[str] = []
    for raw_line in text.replace("\r\n", "\n").split("\n"):
        if not raw_line.strip():
            lines.append("")
            continue
        parsed = _normalize_synthesis_line(raw_line)
        if parsed is not None:
            lines.append(parsed)
    return "\n".join(lines).strip()


def _normalize_synthesis_line(raw_line: str) -> str | None:
    line = raw_line.strip()
    if not line:
        return None
    delimiter_index = _first_role_delimiter_index(line)
    if delimiter_index is None:
        return line
    raw_label = line[:delimiter_index].strip()
    rest = line[delimiter_index + 1 :].strip()
    if not rest or rest.startswith("//"):
        return line
    label = _unquoted(raw_label)
    if not _is_likely_speaker_label(raw_label, label):
        return line
    if _is_quoted(raw_label) and _is_quoted(rest):
        return None
    return rest


def _first_role_delimiter_index(line: str) -> int | None:
    candidates = [index for index in (line.find(":"), line.find("：")) if index >= 0]
    return min(candidates) if candidates else None


def _is_likely_speaker_label(raw_label: str, label: str) -> bool:
    if not label or len(label) > 20:
        return False
    if any(char in raw_label for char in "/\\{}[]()=+-"):
        return False
    if any(char.isdigit() for char in raw_label):
        return False
    if any(char.isspace() for char in raw_label) and not _is_quoted(raw_label):
        return False
    return True


def _is_quoted(value: str) -> bool:
    stripped = value.strip()
    if len(stripped) < 2:
        return False
    return (stripped[0], stripped[-1]) in {('"', '"'), ("'", "'"), ("“", "”"), ("‘", "’")}


def _unquoted(value: str) -> str:
    stripped = value.strip()
    if _is_quoted(stripped):
        return stripped[1:-1].strip()
    return stripped


@dataclasses.dataclass(frozen=True)
class ConsentRecord:
    audio_source: str
    purpose: str
    id: str = dataclasses.field(default_factory=lambda: str(uuid.uuid4()))
    created_at: float = dataclasses.field(default_factory=time.time)


@dataclasses.dataclass(frozen=True)
class GenerationRequest:
    mode: str
    text: str
    language: str
    model_id: str
    voice: dict[str, Any]
    instruct: str = ""
    voice_asset_id: str | None = None
    model_path: str | None = None
    route: str = ""
    seed: int | None = None


class QwenVoiceBackend:
    def __init__(self, data_dir: str | Path):
        self.data_dir = Path(data_dir)
        self.outputs_dir = self.data_dir / "outputs"
        self.outputs_dir.mkdir(parents=True, exist_ok=True)
        self.references_dir = self.data_dir / "references"
        self.references_dir.mkdir(parents=True, exist_ok=True)
        self.clone_prompts_dir = self.data_dir / "clone_prompts"
        self.clone_prompts_dir.mkdir(parents=True, exist_ok=True)
        self.database_dir = self.data_dir / "database"
        self.database_dir.mkdir(parents=True, exist_ok=True)
        legacy_db_path = self.data_dir / "backend.sqlite"
        self.db_path = self.database_dir / "backend.sqlite"
        if legacy_db_path.exists() and not self.db_path.exists():
            shutil.copy2(legacy_db_path, self.db_path)
        self._db = sqlite3.connect(self.db_path)
        self._db.row_factory = sqlite3.Row
        self._model_cache: dict[str, Any] = {}
        self._last_runtime_error = ""
        self._migrate()

    def close(self) -> None:
        self._model_cache.clear()
        self._db.close()

    def record_consent(self, consent: ConsentRecord) -> str:
        self._db.execute(
            """
            INSERT OR REPLACE INTO consent_records (id, audio_source, purpose, created_at)
            VALUES (?, ?, ?, ?)
            """,
            (consent.id, consent.audio_source, consent.purpose, consent.created_at),
        )
        self._db.commit()
        return consent.id

    def runtime_health(self, model_paths: dict[str, Any] | None = None) -> dict[str, Any]:
        dependencies = {
            "mlx_audio": self._module_available("mlx_audio"),
            "mlx": self._module_available("mlx"),
            "transformers": self._module_available("transformers"),
            "ffmpeg": self._ffmpeg_binary() is not None,
            "hf": self._binary_path("hf") is not None,
        }
        hardware = self._mlx_hardware_info()
        optional_dependencies = {
            "qwen_tts": self._module_available("qwen_tts"),
        }
        models = []
        for spec in MODEL_CATALOG:
            override = str((model_paths or {}).get(spec["id"], "")).strip()
            local_path = Path(override).expanduser() if override else self._model_local_path(spec)
            path_exists = local_path.exists()
            ready = self._model_directory_ready(local_path)
            models.append(
                {
                    "id": spec["id"],
                    "repository": spec["repository"],
                    "local_path": str(local_path),
                    "exists": ready,
                    "path_exists": path_exists,
                    "missing_files": self._model_missing_files(local_path),
                    "variant": spec["variant"],
                    "capability": spec["capability"],
                }
            )
        inference_dependencies = ["mlx_audio", "mlx", "transformers"]
        return {
            "runtime": "mlx-audio",
            "real_inference_available": all(dependencies.get(name) for name in inference_dependencies),
            "audio_tools_available": dependencies["ffmpeg"],
            "download_tools_available": dependencies["hf"],
            "dependencies": dependencies,
            "optional_dependencies": optional_dependencies,
            "hardware": hardware,
            "runtime_summary": self._runtime_summary(dependencies, hardware),
            "models": models,
            "diagnostic_mode_available": True,
        }

    def generate(self, request: GenerationRequest) -> dict[str, Any]:
        normalized_text = normalize_synthesis_text(request.text)
        if normalized_text != request.text:
            request = dataclasses.replace(request, text=normalized_text)
        if request.mode == "custom_voice":
            return self.generate_custom_voice(request)
        if request.mode == "voice_clone":
            return self.generate_voice_clone(request)
        if request.mode == "voice_design":
            return self.generate_voice_design(request)
        return self._failure(request, "INVALID_REQUEST", f"Unsupported TTS mode: {request.mode}")

    def generate_custom_voice(self, request: GenerationRequest) -> dict[str, Any]:
        error = self._validate_common(request)
        if error:
            return error
        if not request.language.strip():
            return self._failure(request, "INVALID_REQUEST", "CustomVoice requires language.")
        if not str(request.voice.get("speaker", "")).strip():
            return self._failure(request, "INVALID_REQUEST", "CustomVoice requires speaker.")
        return self._generate_real(request)

    def generate_voice_clone(self, request: GenerationRequest) -> dict[str, Any]:
        error = self._validate_common(request)
        if error:
            return error
        consent_id = self._consent_id(request)
        if not consent_id or not self._has_consent(consent_id):
            return self._failure(request, "CONSENT_REQUIRED", "Voice clone requires local consent.")
        if not self._reference_audio(request):
            return self._failure(request, "INVALID_REQUEST", "Voice clone requires ref_audio.")
        if not self._reference_text(request):
            return self._failure(request, "INVALID_REQUEST", "Voice clone requires ref_text.")
        return self._generate_real(request)

    def generate_voice_design(self, request: GenerationRequest) -> dict[str, Any]:
        error = self._validate_common(request)
        if error:
            return error
        if not request.language.strip():
            return self._failure(request, "INVALID_REQUEST", "VoiceDesign requires language.")
        if not request.instruct.strip():
            return self._failure(request, "INVALID_REQUEST", "VoiceDesign requires natural-language instruct.")
        return self._generate_real(request)

    def create_voice_clone_prompt(self, params: dict[str, Any]) -> dict[str, Any]:
        ref_audio = str(params.get("ref_audio") or params.get("reference_audio") or "").strip()
        ref_text = str(params.get("ref_text") or params.get("reference_text") or "").strip()
        consent_id = str(params.get("consent_id") or "").strip()
        name = str(params.get("name") or "Reusable Clone Voice").strip()
        language = str(params.get("language") or "Chinese").strip()
        if not consent_id or not self._has_consent(consent_id):
            return {"ok": False, "error": {"code": "CONSENT_REQUIRED", "message": "Voice clone prompt requires local consent."}}
        if not ref_audio or not ref_text:
            return {"ok": False, "error": {"code": "INVALID_REQUEST", "message": "ref_audio and ref_text are required."}}

        prompt = {
            "id": str(uuid.uuid4()),
            "name": name,
            "language": language,
            "prompt_kind": "mlx_reference_metadata",
            "reuse_method": "ref_audio_ref_text",
            "ref_audio": ref_audio,
            "ref_text": ref_text,
            "consent_id": consent_id,
            "created_at": time.time(),
        }
        prompt_path = self.clone_prompts_dir / f"{prompt['id']}.json"
        prompt_path.write_text(json.dumps(prompt, ensure_ascii=False, indent=2), encoding="utf-8")
        relative_prompt_path = str(prompt_path.relative_to(self.data_dir))
        voice_asset_id = str(uuid.uuid4())
        self._db.execute(
            """
            INSERT INTO voice_assets
            (id, type, speaker, language, instruct, ref_audio_path, ref_text, clone_prompt_path, consent_id, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (voice_asset_id, "clonedVoice", name, language, "", ref_audio, ref_text, relative_prompt_path, consent_id, time.time()),
        )
        self._db.commit()
        return {
            "ok": True,
            "result": {
                "voice_asset_id": voice_asset_id,
                "clone_prompt_path": relative_prompt_path,
                "prompt_kind": "mlx_reference_metadata",
                "reuse_method": "ref_audio_ref_text",
            },
        }

    def import_reference(self, params: dict[str, Any]) -> dict[str, Any]:
        source = Path(str(params.get("path") or params.get("audio_path") or "")).expanduser()
        transcript = str(params.get("transcript") or "")
        consent_id = str(params.get("consent_id") or "")
        if not source.exists() or not source.is_file():
            return {"ok": False, "error": {"code": "INVALID_REQUEST", "message": f"Reference audio does not exist: {source}"}}
        suffix = source.suffix or ".wav"
        destination = self.references_dir / f"{uuid.uuid4().hex}{suffix}"
        shutil.copy2(source, destination)
        relative_path = str(destination.relative_to(self.data_dir))
        duration = self._audio_duration(destination)
        recording_id = str(uuid.uuid4())
        self._db.execute(
            """
            INSERT INTO reference_recordings (id, path, duration, transcript, consent_id, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (recording_id, relative_path, duration, transcript, consent_id or None, time.time()),
        )
        self._db.commit()
        return {
            "ok": True,
            "result": {
                "id": recording_id,
                "path": relative_path,
                "duration": duration,
                "transcript": transcript,
                "consent_id": consent_id or None,
            },
        }

    def generation_list(self) -> dict[str, Any]:
        rows = self._db.execute(
            """
            SELECT id, mode, model_id, voice_asset_id, text, instruct, audio_path, runtime, status, error, created_at
            FROM generations ORDER BY created_at DESC
            """
        ).fetchall()
        return {"generations": [dict(row) for row in rows]}

    def concat_audio(self, params: dict[str, Any]) -> dict[str, Any]:
        raw_paths = params.get("paths") or []
        if not isinstance(raw_paths, list) or not raw_paths:
            return {"ok": False, "error": {"code": "INVALID_REQUEST", "message": "paths must be a non-empty list."}}
        try:
            gap_seconds = max(0.0, min(float(params.get("gap_seconds") or 0.0), 5.0))
        except (TypeError, ValueError):
            return {"ok": False, "error": {"code": "INVALID_REQUEST", "message": "gap_seconds must be a number."}}

        audio_paths: list[Path] = []
        for raw in raw_paths:
            resolved = self._workspace_file(str(raw))
            if resolved is None or not resolved.is_file() or resolved.suffix.lower() not in SUPPORTED_CONCAT_AUDIO_SUFFIXES:
                return {"ok": False, "error": {"code": "INVALID_REQUEST", "message": f"Invalid audio path: {raw}"}}
            audio_paths.append(resolved)

        output_name = str(params.get("name") or f"{uuid.uuid4().hex}{USER_AUDIO_SUFFIX}").strip() or f"{uuid.uuid4().hex}{USER_AUDIO_SUFFIX}"
        output_name = Path(output_name).name
        if not output_name.lower().endswith(USER_AUDIO_SUFFIX):
            output_name = f"{Path(output_name).stem}{USER_AUDIO_SUFFIX}"
        output_path = self.outputs_dir / output_name
        if output_path.exists():
            output_path = self.outputs_dir / f"{Path(output_name).stem}-{uuid.uuid4().hex[:8]}{USER_AUDIO_SUFFIX}"

        try:
            self._concat_audio_files(audio_paths, output_path, gap_seconds=gap_seconds)
        except Exception as exc:
            return {"ok": False, "error": {"code": "CONCAT_FAILED", "message": str(exc)}}

        return {
            "ok": True,
            "result": {
                "audio_path": str(output_path.resolve().relative_to(self.data_dir.resolve())),
                "sample_rate": self._audio_sample_rate(output_path),
                "runtime": "webm-concat",
            },
        }

    def generate_diagnostic_tone(self, params: dict[str, Any]) -> dict[str, Any]:
        request = GenerationRequest(
            mode="diagnostic",
            text=str(params.get("text") or "diagnostic tone"),
            language=str(params.get("language") or "Chinese"),
            model_id=str(params.get("model_id") or "diagnostic-tone"),
            voice={},
            instruct=str(params.get("instruct") or ""),
        )
        output = self._finalize_user_audio(request, self._write_stub_wav(request))
        if output is None:
            return self._failure(request, "AUDIO_ENCODING_UNAVAILABLE", self._last_runtime_error or "Unable to encode diagnostic tone as WebM.")
        self._persist_generation(request, output, runtime="diagnostic-tone", status="ready", error="")
        return {"ok": True, "result": {"audio_path": output, "sample_rate": self._audio_sample_rate(self.data_dir / output), "runtime": "diagnostic-tone"}}

    def handle_json(self, line: str) -> str:
        try:
            payload = json.loads(line)
            method = payload["method"]
            params = payload.get("params") or {}
            result = self._dispatch(method, params)
            return json.dumps({"jsonrpc": "2.0", "id": payload.get("id"), "result": result}, ensure_ascii=False)
        except Exception as exc:  # Keep the backend process alive for UI diagnostics.
            return json.dumps(
                {
                    "jsonrpc": "2.0",
                    "id": self._safe_id(line),
                    "error": {"code": "BACKEND_ERROR", "message": str(exc)},
                },
                ensure_ascii=False,
            )

    def _dispatch(self, method: str, params: dict[str, Any]) -> dict[str, Any]:
        if method == "models.list":
            return {"models": MODEL_CATALOG}
        if method == "runtime.health":
            raw_paths = params.get("model_paths") or {}
            return self.runtime_health(raw_paths if isinstance(raw_paths, dict) else {})
        if method == "text.segment":
            return {"segments": segment_text(str(params.get("text", "")), int(params.get("max_chars", 420)))}
        if method == "consent.record":
            consent = ConsentRecord(
                audio_source=str(params["audio_source"]),
                purpose=str(params.get("purpose", "local voice clone")),
            )
            return {"consent_id": self.record_consent(consent)}
        if method in {"tts.generate", "tts.generate_custom_voice", "tts.generate_voice_clone", "tts.generate_voice_design"}:
            mode = str(params.get("mode") or "")
            if method == "tts.generate_custom_voice":
                mode = "custom_voice"
            elif method == "tts.generate_voice_clone":
                mode = "voice_clone"
            elif method == "tts.generate_voice_design":
                mode = "voice_design"
            request = GenerationRequest(
                mode=mode,
                text=str(params["text"]),
                language=str(params.get("language", "Auto")),
                model_id=str(params["model_id"]),
                voice=dict(params.get("voice") or {}),
                instruct=str(params.get("instruct", "")),
                voice_asset_id=params.get("voice_asset_id"),
                model_path=params.get("model_path"),
                route=str(params.get("route", "")),
                seed=_optional_int(params.get("seed")),
            )
            return self.generate(request)
        if method == "tts.create_voice_clone_prompt":
            return self.create_voice_clone_prompt(params)
        if method == "audio.import_reference":
            return self.import_reference(params)
        if method == "generation.list":
            return self.generation_list()
        if method in {"audio.concat_audio", "audio.concat_wav"}:
            return self.concat_audio(params)
        if method == "diagnostic.generate_tone":
            return self.generate_diagnostic_tone(params)
        raise ValueError(f"Unknown method: {method}")

    def _migrate(self) -> None:
        self._db.execute(
            """
            CREATE TABLE IF NOT EXISTS consent_records (
                id TEXT PRIMARY KEY,
                audio_source TEXT NOT NULL,
                purpose TEXT NOT NULL,
                created_at REAL NOT NULL
            )
            """
        )
        self._db.execute(
            """
            CREATE TABLE IF NOT EXISTS generations (
                id TEXT PRIMARY KEY,
                mode TEXT NOT NULL,
                model_id TEXT NOT NULL,
                voice_asset_id TEXT,
                text TEXT NOT NULL,
                instruct TEXT,
                audio_path TEXT NOT NULL,
                runtime TEXT NOT NULL DEFAULT '',
                status TEXT NOT NULL DEFAULT 'ready',
                error TEXT,
                created_at REAL NOT NULL
            )
            """
        )
        self._ensure_column("generations", "voice_asset_id", "TEXT")
        self._ensure_column("generations", "instruct", "TEXT")
        self._ensure_column("generations", "runtime", "TEXT NOT NULL DEFAULT ''")
        self._ensure_column("generations", "status", "TEXT NOT NULL DEFAULT 'ready'")
        self._ensure_column("generations", "error", "TEXT")
        self._db.execute(
            """
            CREATE TABLE IF NOT EXISTS voice_assets (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL,
                speaker TEXT,
                language TEXT NOT NULL,
                instruct TEXT,
                ref_audio_path TEXT,
                ref_text TEXT,
                clone_prompt_path TEXT,
                consent_id TEXT,
                created_at REAL NOT NULL
            )
            """
        )
        self._db.execute(
            """
            CREATE TABLE IF NOT EXISTS reference_recordings (
                id TEXT PRIMARY KEY,
                path TEXT NOT NULL,
                duration REAL NOT NULL,
                transcript TEXT,
                consent_id TEXT,
                created_at REAL NOT NULL
            )
            """
        )
        self._db.commit()

    def _ensure_column(self, table: str, column: str, definition: str) -> None:
        columns = {row["name"] for row in self._db.execute(f"PRAGMA table_info({table})").fetchall()}
        if column not in columns:
            self._db.execute(f"ALTER TABLE {table} ADD COLUMN {column} {definition}")

    def _has_consent(self, consent_id: str) -> bool:
        cursor = self._db.execute("SELECT 1 FROM consent_records WHERE id = ?", (consent_id,))
        return cursor.fetchone() is not None

    def _validate_common(self, request: GenerationRequest) -> dict[str, Any] | None:
        if not request.text.strip():
            return self._failure(request, "INVALID_REQUEST", "Text is required.")
        if not request.model_id.strip():
            return self._failure(request, "INVALID_REQUEST", "model_id is required.")
        return None

    def _generate_real(self, request: GenerationRequest) -> dict[str, Any]:
        health = self.runtime_health()
        if not health["real_inference_available"]:
            return self._failure(
                request,
                "RUNTIME_UNAVAILABLE",
                "Real Qwen3-TTS runtime is unavailable. Install mlx-audio and mlx, then retry.",
                details=health,
            )

        model_source = self._model_source_path(request)
        if model_source is None or not self._model_directory_ready(model_source):
            return self._failure(
                request,
                "MODEL_NOT_READY",
                "Selected model is not available locally or is incomplete. Download it or choose a complete model path before generation.",
                details={
                    "model_id": request.model_id,
                    "model_path": str(model_source) if model_source is not None else "",
                    "missing_files": self._model_missing_files(model_source) if model_source is not None else ["model directory"],
                },
            )

        self._last_runtime_error = ""
        output = self._try_mlx_generate(request)
        if output is None:
            message = "Real Qwen3-TTS runtime did not produce an audio file. No diagnostic stub was generated."
            if self._last_runtime_error:
                message = f"{message} Runtime error: {self._last_runtime_error}"
            return self._failure(
                request,
                "RUNTIME_UNAVAILABLE",
                message,
                details=health,
            )

        user_output = self._finalize_user_audio(request, output)
        if user_output is None:
            return self._failure(
                request,
                "AUDIO_ENCODING_UNAVAILABLE",
                self._last_runtime_error or "Real Qwen3-TTS output was generated but could not be encoded as WebM.",
                details=health,
            )

        self._persist_generation(request, user_output, runtime="mlx-audio", status="ready", error="")
        return {"ok": True, "result": {"audio_path": user_output, "sample_rate": self._audio_sample_rate(self.data_dir / user_output), "runtime": "mlx-audio"}}

    def _failure(
        self,
        request: GenerationRequest,
        code: str,
        message: str,
        details: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        error = {"code": code, "message": message}
        if details is not None:
            error["details"] = details
        self._persist_generation(request, "", runtime="none", status="failed", error=f"{code}: {message}")
        return {"ok": False, "error": error}

    def _persist_generation(
        self,
        request: GenerationRequest,
        audio_path: str,
        runtime: str,
        status: str,
        error: str,
    ) -> None:
        self._db.execute(
            """
            INSERT INTO generations
            (id, mode, model_id, voice_asset_id, text, instruct, audio_path, runtime, status, error, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                str(uuid.uuid4()),
                request.route or request.mode,
                request.model_id,
                request.voice_asset_id,
                request.text,
                request.instruct,
                audio_path,
                runtime,
                status,
                error,
                time.time(),
            ),
        )
        self._db.commit()

    def _module_available(self, module_name: str) -> bool:
        return importlib.util.find_spec(module_name) is not None

    def _mlx_hardware_info(self) -> dict[str, Any]:
        info: dict[str, Any] = {
            "mlx_default_device": "unavailable",
            "metal_available": False,
            "gpu_available": False,
        }
        try:
            import mlx.core as mx  # type: ignore
        except Exception as exc:
            info["error"] = f"{type(exc).__name__}: {exc}"
            return info

        try:
            default_device = mx.default_device()
            info["mlx_default_device"] = str(default_device)
            info["gpu_available"] = "gpu" in str(default_device).lower()
        except Exception as exc:
            info["mlx_default_device"] = f"unknown ({type(exc).__name__}: {exc})"

        metal = getattr(mx, "metal", None)
        if metal is not None:
            checker = getattr(metal, "is_available", None)
            if callable(checker):
                try:
                    info["metal_available"] = bool(checker())
                except Exception:
                    info["metal_available"] = True
            else:
                info["metal_available"] = True
        return info

    @staticmethod
    def _runtime_summary(dependencies: dict[str, bool], hardware: dict[str, Any]) -> str:
        missing = [name for name in ["mlx_audio", "mlx", "transformers"] if not dependencies.get(name)]
        if missing:
            return f"MLX runtime unavailable: install {', '.join(missing)}."
        device = str(hardware.get("mlx_default_device") or "unknown")
        metal = "available" if hardware.get("metal_available") else "unavailable"
        gpu = "GPU" if hardware.get("gpu_available") else "CPU/unknown"
        ffmpeg = "available" if dependencies.get("ffmpeg") else "unavailable"
        hf = "available" if dependencies.get("hf") else "unavailable"
        return f"mlx-audio on {device} ({gpu}); Metal {metal}; ffmpeg {ffmpeg}; hf {hf}."

    def _model_local_path(self, spec: dict[str, Any]) -> Path:
        slug = str(spec["repository"]).replace("/", "__")
        return self.data_dir / "models" / slug

    def _reference_audio(self, request: GenerationRequest) -> str:
        direct = str(request.voice.get("ref_audio") or request.voice.get("reference_audio") or "").strip()
        if direct:
            return direct
        return str(self._clone_prompt_payload(request).get("ref_audio") or "").strip()

    def _reference_text(self, request: GenerationRequest) -> str:
        direct = str(request.voice.get("ref_text") or request.voice.get("reference_text") or "").strip()
        if direct:
            return direct
        return str(self._clone_prompt_payload(request).get("ref_text") or "").strip()

    def _consent_id(self, request: GenerationRequest) -> str:
        direct = str(request.voice.get("consent_id") or "").strip()
        if direct:
            return direct
        return str(self._clone_prompt_payload(request).get("consent_id") or "").strip()

    def _clone_prompt_path(self, request: GenerationRequest) -> Path | None:
        raw = str(
            request.voice.get("clone_prompt_path")
            or request.voice.get("voice_clone_prompt")
            or request.voice.get("clone_prompt")
            or ""
        ).strip()
        if not raw:
            return None
        candidate = Path(raw).expanduser()
        if not candidate.is_absolute():
            candidate = self.data_dir / candidate
        try:
            resolved = candidate.resolve()
            resolved.relative_to(self.data_dir.resolve())
        except Exception:
            return None
        return resolved if resolved.is_file() else None

    def _clone_prompt_payload(self, request: GenerationRequest) -> dict[str, Any]:
        path = self._clone_prompt_path(request)
        if path is None:
            return {}
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            return {}
        return payload if isinstance(payload, dict) else {}

    def _workspace_file(self, raw_path: str) -> Path | None:
        raw_path = raw_path.strip()
        if not raw_path:
            return None
        candidate = Path(raw_path).expanduser()
        if not candidate.is_absolute():
            candidate = self.data_dir / candidate
        try:
            resolved = candidate.resolve()
            resolved.relative_to(self.data_dir.resolve())
        except Exception:
            return None
        return resolved

    def _concat_wav_files(self, wav_paths: list[Path], output_path: Path, gap_seconds: float = 0.0) -> None:
        params: tuple[int, int, int, str, str] | None = None
        frames: list[bytes] = []
        for wav_path in wav_paths:
            with wave.open(str(wav_path), "rb") as wav:
                current = (
                    wav.getnchannels(),
                    wav.getsampwidth(),
                    wav.getframerate(),
                    wav.getcomptype(),
                    wav.getcompname(),
                )
                if params is None:
                    params = current
                elif current != params:
                    raise ValueError("All WAV files must have matching channels, sample width, frame rate, and compression.")
                frames.append(wav.readframes(wav.getnframes()))

        if params is None:
            raise ValueError("No WAV files to concatenate.")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with wave.open(str(output_path), "wb") as output:
            output.setnchannels(params[0])
            output.setsampwidth(params[1])
            output.setframerate(params[2])
            output.setcomptype(params[3], params[4])
            gap_frames = int(round(params[2] * gap_seconds))
            silence = b"\0" * (gap_frames * params[0] * params[1])
            for index, chunk in enumerate(frames):
                if index > 0 and silence:
                    output.writeframes(silence)
                output.writeframes(chunk)

    def _concat_audio_files(self, audio_paths: list[Path], output_path: Path, gap_seconds: float = 0.0) -> None:
        cache_dir = self.data_dir / "cache" / "audio-concat"
        cache_dir.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=cache_dir) as tmp_dir:
            tmp_path = Path(tmp_dir)
            wav_paths: list[Path] = []
            for index, audio_path in enumerate(audio_paths):
                if audio_path.suffix.lower() == LEGACY_AUDIO_SUFFIX:
                    wav_paths.append(audio_path)
                    continue
                decoded = tmp_path / f"input-{index}.wav"
                self._decode_audio_to_wav(audio_path, decoded)
                wav_paths.append(decoded)
            merged_wav = tmp_path / "merged.wav"
            self._concat_wav_files(wav_paths, merged_wav, gap_seconds=gap_seconds)
            self._encode_wav_to_webm(merged_wav, output_path)

    def _audio_duration(self, path: Path) -> float:
        if path.suffix.lower() == USER_AUDIO_SUFFIX:
            return self._probe_audio_float(path, "format=duration")
        if path.suffix.lower() != LEGACY_AUDIO_SUFFIX:
            return 0.0
        try:
            with wave.open(str(path), "rb") as wav:
                return wav.getnframes() / float(wav.getframerate())
        except Exception:
            return 0.0

    def _audio_sample_rate(self, path: Path) -> int:
        if path.suffix.lower() == USER_AUDIO_SUFFIX:
            return int(self._probe_audio_float(path, "stream=sample_rate"))
        try:
            with wave.open(str(path), "rb") as wav:
                return wav.getframerate()
        except Exception:
            return 0

    def _finalize_user_audio(self, request: GenerationRequest, relative_audio_path: str) -> str | None:
        source = self._workspace_file(relative_audio_path)
        if source is None or not source.is_file():
            self._last_runtime_error = f"Generated audio file does not exist: {relative_audio_path}"
            return None
        if source.suffix.lower() == USER_AUDIO_SUFFIX:
            return str(source.resolve().relative_to(self.data_dir.resolve()))
        if source.suffix.lower() != LEGACY_AUDIO_SUFFIX:
            self._last_runtime_error = f"Unsupported generated audio format: {source.suffix}"
            return None
        output_path = source.with_suffix(USER_AUDIO_SUFFIX)
        if output_path.exists():
            output_path = source.with_name(f"{source.stem}-{uuid.uuid4().hex[:8]}{USER_AUDIO_SUFFIX}")
        try:
            self._encode_wav_to_webm(source, output_path)
            with contextlib.suppress(Exception):
                source.unlink()
            return str(output_path.resolve().relative_to(self.data_dir.resolve()))
        except Exception as exc:
            self._last_runtime_error = f"{type(exc).__name__}: {exc}"
            return None

    def _encode_wav_to_webm(self, source: Path, output: Path) -> None:
        output.parent.mkdir(parents=True, exist_ok=True)
        self._run_ffmpeg(
            [
                "-y",
                "-i",
                str(source),
                "-vn",
                "-c:a",
                "libopus",
                "-b:a",
                "48k",
                "-application",
                "audio",
                str(output),
            ]
        )

    def _decode_audio_to_wav(self, source: Path, output: Path) -> None:
        output.parent.mkdir(parents=True, exist_ok=True)
        self._run_ffmpeg(["-y", "-i", str(source), "-ac", "1", "-ar", "24000", "-f", "wav", str(output)])

    def _run_ffmpeg(self, arguments: list[str]) -> None:
        ffmpeg = self._ffmpeg_binary()
        if ffmpeg is None:
            raise RuntimeError("ffmpeg is required to write WebM audio. Install ffmpeg or bundle it with Voice Studio.")
        completed = subprocess.run(
            [ffmpeg, "-hide_banner", "-loglevel", "error", *arguments],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=180,
            check=False,
        )
        if completed.returncode != 0:
            raise RuntimeError((completed.stderr or completed.stdout or "ffmpeg failed").strip())

    def _probe_audio_float(self, path: Path, entry: str) -> float:
        ffprobe = self._ffprobe_binary()
        if ffprobe is None:
            return 0.0
        completed = subprocess.run(
            [
                ffprobe,
                "-v",
                "error",
                "-select_streams",
                "a:0",
                "-show_entries",
                entry,
                "-of",
                "default=noprint_wrappers=1:nokey=1",
                str(path),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=20,
            check=False,
        )
        if completed.returncode != 0:
            return 0.0
        try:
            return float(completed.stdout.strip().splitlines()[0])
        except Exception:
            return 0.0

    def _ffmpeg_binary(self) -> str | None:
        return self._binary_path("ffmpeg")

    def _ffprobe_binary(self) -> str | None:
        return self._binary_path("ffprobe")

    @staticmethod
    def _binary_path(name: str) -> str | None:
        runtime_dir = os.environ.get("VOICE_STUDIO_RUNTIME_DIR", "").strip()
        if runtime_dir:
            runtime_binary = Path(runtime_dir) / "bin" / name
            if runtime_binary.is_file():
                return str(runtime_binary)
        discovered = shutil.which(name)
        if discovered:
            return discovered
        for path in [f"/opt/homebrew/bin/{name}", f"/usr/local/bin/{name}"]:
            if Path(path).is_file():
                return path
        return None

    def _write_stub_wav(self, request: GenerationRequest) -> str:
        digest = hashlib.sha256(f"{request.model_id}:{request.text}".encode("utf-8")).digest()
        frequency = 220 + digest[0]
        duration_seconds = min(4.0, max(0.8, len(request.text) / 18.0))
        sample_rate = 24000
        frame_count = int(sample_rate * duration_seconds)
        filename = f"{uuid.uuid4().hex}.wav"
        path = self.outputs_dir / filename

        with wave.open(str(path), "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(sample_rate)
            frames = bytearray()
            for i in range(frame_count):
                envelope = min(1.0, i / 1200) * min(1.0, (frame_count - i) / 1200)
                sample = int(9000 * envelope * math.sin(2 * math.pi * frequency * i / sample_rate))
                frames += sample.to_bytes(2, "little", signed=True)
            wav.writeframes(bytes(frames))
        return str(path.resolve().relative_to(self.data_dir.resolve()))

    def _try_mlx_generate(self, request: GenerationRequest) -> str | None:
        try:
            from mlx_audio.tts.generate import generate_audio  # type: ignore
            from mlx_audio.tts.utils import load_model  # type: ignore
        except Exception as exc:
            self._last_runtime_error = f"{type(exc).__name__}: {exc}"
            return None

        model_source = self._model_source_path(request)
        if model_source is None or not self._model_directory_ready(model_source):
            return None
        output_prefix = self.outputs_dir / uuid.uuid4().hex
        try:
            with contextlib.redirect_stdout(sys.stderr):
                if request.seed is not None:
                    self._apply_generation_seed(request.seed)
                model = self._cached_model(str(model_source), load_model)
                kwargs: dict[str, Any] = {
                    "model": model,
                    "text": request.text,
                    "file_prefix": str(output_prefix),
                    "lang_code": self._lang_code(request.language),
                    "instruct": None if request.mode == "voice_clone" else request.instruct,
                    "voice": request.voice.get("speaker"),
                    "ref_audio": self._reference_audio(request) or None,
                    "ref_text": self._reference_text(request) or None,
                    "verbose": False,
                }
                supported = inspect.signature(generate_audio).parameters
                supports_var_kwargs = any(param.kind == inspect.Parameter.VAR_KEYWORD for param in supported.values())
                if supports_var_kwargs:
                    filtered_kwargs = {key: value for key, value in kwargs.items() if value is not None}
                else:
                    filtered_kwargs = {key: value for key, value in kwargs.items() if key in supported and value is not None}
                if request.seed is not None and supports_var_kwargs:
                    filtered_kwargs["seed"] = request.seed
                generate_audio(**filtered_kwargs)
        except Exception as exc:
            self._last_runtime_error = f"{type(exc).__name__}: {exc}"
            return None

        for wav_path in [output_prefix.with_suffix(".wav"), output_prefix.parent / f"{output_prefix.name}_000.wav"]:
            if wav_path.exists():
                return str(wav_path.resolve().relative_to(self.data_dir.resolve()))
        return None

    def _apply_generation_seed(self, seed: int) -> None:
        normalized = int(seed) % (2**32)
        random.seed(normalized)
        try:
            import numpy as np  # type: ignore

            np.random.seed(normalized)
        except Exception:
            pass
        try:
            import mlx.core as mx  # type: ignore

            mx.random.seed(normalized)
        except Exception:
            pass

    def _cached_model(self, model_path: str, load_model: Any) -> Any:
        cached = self._model_cache.get(model_path)
        if cached is not None:
            return cached
        model = load_model(Path(model_path))
        self._model_cache.clear()
        self._model_cache[model_path] = model
        return model

    def _model_source_path(self, request: GenerationRequest) -> Path | None:
        if request.model_path:
            return Path(request.model_path).expanduser()
        model_spec = next((item for item in MODEL_CATALOG if item["id"] == request.model_id), None)
        if model_spec is None:
            return None
        return self._model_local_path(model_spec)

    def _model_directory_ready(self, path: Path) -> bool:
        return path.is_dir() and not self._model_missing_files(path)

    def _model_missing_files(self, path: Path) -> list[str]:
        if not path.exists():
            return ["model directory"]
        if not path.is_dir():
            return ["model directory"]
        missing: list[str] = []
        if not (path / "config.json").exists():
            missing.append("config.json")
        if not any(path.glob("*.safetensors")):
            missing.append("*.safetensors")
        return missing

    @staticmethod
    def _lang_code(language: str) -> str:
        normalized = (language or "").strip()
        if not normalized:
            return "chinese"
        key = normalized.lower().replace("-", "_").replace(" ", "_")
        mapping = {
            "auto": "auto",
            "automatic": "auto",
            "chinese": "chinese",
            "zh": "chinese",
            "zh_cn": "chinese",
            "中文": "chinese",
            "普通话": "chinese",
            "english": "english",
            "en": "english",
            "英语": "english",
            "英文": "english",
            "japanese": "japanese",
            "ja": "japanese",
            "日语": "japanese",
            "日本語": "japanese",
            "korean": "korean",
            "ko": "korean",
            "韩语": "korean",
            "한국어": "korean",
            "german": "german",
            "de": "german",
            "德语": "german",
            "french": "french",
            "fr": "french",
            "法语": "french",
            "russian": "russian",
            "ru": "russian",
            "俄语": "russian",
            "portuguese": "portuguese",
            "pt": "portuguese",
            "葡萄牙语": "portuguese",
            "spanish": "spanish",
            "es": "spanish",
            "西班牙语": "spanish",
            "italian": "italian",
            "it": "italian",
            "意大利语": "italian",
            "beijing_dialect": "beijing_dialect",
            "北京话": "beijing_dialect",
            "sichuan_dialect": "sichuan_dialect",
            "四川话": "sichuan_dialect",
        }
        return mapping.get(key, key)

    @staticmethod
    def _safe_id(line: str) -> Any:
        try:
            return json.loads(line).get("id")
        except Exception:
            return None


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", default=str(Path.home() / "Library/Application Support/MacQwenVoice"))
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--parent-pid", type=int)
    args = parser.parse_args(argv)

    _start_parent_watchdog(args.parent_pid)
    backend = QwenVoiceBackend(args.data_dir)
    try:
        for line in sys.stdin:
            print(backend.handle_json(line), flush=True)
            if args.once:
                break
    finally:
        backend.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
