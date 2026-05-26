import json
import os
import sys
import types
import unittest
import wave
from unittest import mock

from backend.server import ConsentRecord, GenerationRequest, QwenVoiceBackend, _parent_process_is_alive, normalize_synthesis_text, segment_text


class BackendContractTests(unittest.TestCase):
    def test_parent_process_watchdog_detects_missing_parent(self):
        self.assertTrue(_parent_process_is_alive(None))
        self.assertTrue(_parent_process_is_alive(os.getpid()))
        self.assertFalse(_parent_process_is_alive(999_999_999))

    def test_segment_text_preserves_short_paragraphs_and_splits_long_input(self):
        text = "第一段。\n\n第二段需要被切开，因为长文本应该按段落和长度拆分，避免一次生成失败影响全部结果。"

        segments = segment_text(text, max_chars=18)

        self.assertEqual(segments[0]["text"], "第一段。")
        self.assertTrue(all(item["text"].strip() for item in segments))
        self.assertTrue(all(len(item["text"]) <= 18 for item in segments))

    def test_normalize_synthesis_text_strips_speaker_labels_and_role_definitions(self):
        text = '''"旁白": "沉稳客观。"
"小林": "年轻紧张。"

旁白: 小林今天第三次走神了。
小林：我、我其实不太会喝酒。'''

        self.assertEqual(
            normalize_synthesis_text(text),
            "小林今天第三次走神了。\n我、我其实不太会喝酒。",
        )

    def test_normalize_synthesis_text_keeps_urls_and_ratios(self):
        self.assertEqual(
            normalize_synthesis_text("https://qwen.ai/blog?id=qwen3tts-0115"),
            "https://qwen.ai/blog?id=qwen3tts-0115",
        )
        self.assertEqual(normalize_synthesis_text("画面比例 1:2，背景保持干净。"), "画面比例 1:2，背景保持干净。")

    def test_normalize_synthesis_text_preserves_paragraph_breaks(self):
        self.assertEqual(normalize_synthesis_text("第一段。\n\n旁白: 第二段。"), "第一段。\n\n第二段。")

    def test_runtime_health_reports_real_inference_availability(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)

            response = json.loads(
                backend.handle_json(json.dumps({"id": 2, "method": "runtime.health", "params": {}}))
            )

            result = response["result"]
            self.assertIn("real_inference_available", result)
            self.assertIn("dependencies", result)
            self.assertIn("mlx_audio", result["dependencies"])
            self.assertNotIn("qwen_tts", result["dependencies"])
            self.assertIn("qwen_tts", result["optional_dependencies"])
            backend.close()

    def test_runtime_health_reports_mlx_gpu_and_metal_diagnostics(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)

            result = backend.runtime_health()

            self.assertIn("hardware", result)
            self.assertIn("mlx_default_device", result["hardware"])
            self.assertIn("metal_available", result["hardware"])
            self.assertIn("gpu_available", result["hardware"])
            self.assertIn("runtime_summary", result)
            backend.close()

    def test_custom_voice_requires_speaker_and_language(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)

            response = json.loads(
                backend.handle_json(
                    json.dumps(
                        {
                            "id": 3,
                            "method": "tts.generate_custom_voice",
                            "params": {
                                "text": "缺少 speaker 和 instruct 时不能生成。",
                                "language": "Chinese",
                                "model_id": "qwen3-tts-12hz-0.6b-customvoice",
                                "voice": {},
                            },
                        }
                    )
                )
            )

            self.assertFalse(response["result"]["ok"])
            self.assertEqual(response["result"]["error"]["code"], "INVALID_REQUEST")
            backend.close()

    def test_custom_voice_allows_blank_instruct(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            model_path = tmp_path / "models" / "customvoice"
            model_path.mkdir(parents=True)
            (model_path / "config.json").write_text("{}", encoding="utf-8")
            (model_path / "model.safetensors").write_text("weights", encoding="utf-8")
            request = GenerationRequest(
                mode="custom_voice",
                text="没有控制指令时也应使用内置 speaker 生成。",
                language="Chinese",
                model_id="qwen3-tts-12hz-0.6b-customvoice",
                model_path=str(model_path),
                voice={"speaker": "Serena"},
                instruct="",
            )

            with mock.patch.object(
                backend,
                "_generate_real",
                return_value={"ok": True, "result": {"audio_path": str(tmp_path / "outputs" / "blank.wav")}},
            ):
                response = backend.generate(request)

            self.assertTrue(response["ok"])
            backend.close()

    def test_custom_voice_accepts_auto_language_for_mixed_text(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            model_path = tmp_path / "custom-model"
            model_path.mkdir()
            (model_path / "config.json").write_text("{}", encoding="utf-8")
            (model_path / "model.safetensors").write_text("weights", encoding="utf-8")
            captured_kwargs = {}

            def fake_generate_audio(model, text, file_prefix, lang_code=None, **kwargs):
                captured_kwargs["lang_code"] = lang_code
                output_path = f"{file_prefix}.wav"
                with wave.open(output_path, "wb") as wav:
                    wav.setnchannels(1)
                    wav.setsampwidth(2)
                    wav.setframerate(24_000)
                    wav.writeframes(b"\0\0" * 1200)

            fake_generate_module = types.ModuleType("mlx_audio.tts.generate")
            fake_generate_module.generate_audio = fake_generate_audio
            fake_utils_module = types.ModuleType("mlx_audio.tts.utils")
            fake_utils_module.load_model = lambda path: {"model_path": str(path)}
            fake_tts_module = types.ModuleType("mlx_audio.tts")
            fake_root_module = types.ModuleType("mlx_audio")
            request = GenerationRequest(
                mode="custom_voice",
                text="中文 and English mixed.",
                language="Auto",
                model_id="qwen3-tts-12hz-0.6b-customvoice",
                voice={"speaker": "Serena"},
                instruct="自然",
                model_path=str(model_path),
            )

            with mock.patch.dict(
                sys.modules,
                {
                    "mlx_audio": fake_root_module,
                    "mlx_audio.tts": fake_tts_module,
                    "mlx_audio.tts.generate": fake_generate_module,
                    "mlx_audio.tts.utils": fake_utils_module,
                },
            ), mock.patch.object(backend, "runtime_health", return_value={"real_inference_available": True}):
                response = backend.generate(request)

            self.assertTrue(response["ok"])
            self.assertEqual(captured_kwargs["lang_code"], "auto")
            backend.close()

    def test_real_generation_returns_webm_user_audio(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            model_path = tmp_path / "custom-model"
            model_path.mkdir()
            (model_path / "config.json").write_text("{}", encoding="utf-8")
            (model_path / "model.safetensors").write_text("weights", encoding="utf-8")

            def fake_generate_audio(model, text, file_prefix, **kwargs):
                output_path = f"{file_prefix}.wav"
                with wave.open(output_path, "wb") as wav:
                    wav.setnchannels(1)
                    wav.setsampwidth(2)
                    wav.setframerate(24_000)
                    wav.writeframes(b"\0\0" * 2400)

            fake_generate_module = types.ModuleType("mlx_audio.tts.generate")
            fake_generate_module.generate_audio = fake_generate_audio
            fake_utils_module = types.ModuleType("mlx_audio.tts.utils")
            fake_utils_module.load_model = lambda path: {"model_path": str(path)}
            fake_tts_module = types.ModuleType("mlx_audio.tts")
            fake_root_module = types.ModuleType("mlx_audio")
            request = GenerationRequest(
                mode="custom_voice",
                text="生成结果应该保存为 WebM。",
                language="Chinese",
                model_id="qwen3-tts-12hz-0.6b-customvoice",
                voice={"speaker": "Serena"},
                instruct="自然",
                model_path=str(model_path),
            )

            with mock.patch.dict(
                sys.modules,
                {
                    "mlx_audio": fake_root_module,
                    "mlx_audio.tts": fake_tts_module,
                    "mlx_audio.tts.generate": fake_generate_module,
                    "mlx_audio.tts.utils": fake_utils_module,
                },
            ), mock.patch.object(backend, "runtime_health", return_value={"real_inference_available": True}):
                response = backend.generate(request)

            self.assertTrue(response["ok"])
            audio_path = response["result"]["audio_path"]
            self.assertTrue(audio_path.endswith(".webm"))
            self.assertTrue((tmp_path / audio_path).exists())
            self.assertFalse((tmp_path / audio_path).with_suffix(".wav").exists())
            backend.close()

    def test_qwen_language_mapping_preserves_full_language_and_dialect_keys(self):
        self.assertEqual(QwenVoiceBackend._lang_code("Chinese"), "chinese")
        self.assertEqual(QwenVoiceBackend._lang_code("English"), "english")
        self.assertEqual(QwenVoiceBackend._lang_code("英文"), "english")
        self.assertEqual(QwenVoiceBackend._lang_code("Japanese"), "japanese")
        self.assertEqual(QwenVoiceBackend._lang_code("Korean"), "korean")
        self.assertEqual(QwenVoiceBackend._lang_code("German"), "german")
        self.assertEqual(QwenVoiceBackend._lang_code("French"), "french")
        self.assertEqual(QwenVoiceBackend._lang_code("Russian"), "russian")
        self.assertEqual(QwenVoiceBackend._lang_code("Portuguese"), "portuguese")
        self.assertEqual(QwenVoiceBackend._lang_code("Spanish"), "spanish")
        self.assertEqual(QwenVoiceBackend._lang_code("Italian"), "italian")
        self.assertEqual(QwenVoiceBackend._lang_code("北京话"), "beijing_dialect")
        self.assertEqual(QwenVoiceBackend._lang_code("四川话"), "sichuan_dialect")
        self.assertEqual(QwenVoiceBackend._lang_code("beijing_dialect"), "beijing_dialect")
        self.assertEqual(QwenVoiceBackend._lang_code("sichuan_dialect"), "sichuan_dialect")
        self.assertEqual(QwenVoiceBackend._lang_code("Auto"), "auto")

    def test_missing_runtime_fails_without_creating_stub_audio(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            model_path = tmp_path / "models" / "mlx-community__Qwen3-TTS-12Hz-0.6B-CustomVoice-8bit"
            model_path.mkdir(parents=True)
            (model_path / "config.json").write_text("{}", encoding="utf-8")
            (model_path / "model.safetensors").write_text("weights", encoding="utf-8")
            request = GenerationRequest(
                mode="custom_voice",
                text="真实推理不可用时不能静默生成测试音。",
                language="Chinese",
                model_id="qwen3-tts-12hz-0.6b-customvoice",
                voice={"speaker": "Serena"},
                instruct="温柔、清晰、自然",
            )

            with mock.patch.object(backend, "_try_mlx_generate", return_value=None):
                response = backend.generate(request)

            self.assertFalse(response["ok"])
            self.assertEqual(response["error"]["code"], "RUNTIME_UNAVAILABLE")
            self.assertEqual(list((tmp_path / "outputs").glob("*.wav")), [])
            backend.close()

    def test_missing_model_path_fails_before_runtime_generation(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            request = GenerationRequest(
                mode="voice_design",
                text="没有下载 VoiceDesign 模型时应明确失败。",
                language="Chinese",
                model_id="qwen3-tts-12hz-1.7b-voicedesign",
                voice={},
                instruct="年轻女性声音，语速中等。",
            )

            with mock.patch.object(backend, "runtime_health", return_value={"real_inference_available": True}), \
                 mock.patch.object(backend, "_try_mlx_generate", return_value="outputs/should-not-run.wav") as generate:
                response = backend.generate(request)

            self.assertFalse(response["ok"])
            self.assertEqual(response["error"]["code"], "MODEL_NOT_READY")
            generate.assert_not_called()
            self.assertEqual(list((tmp_path / "outputs").glob("*.wav")), [])
            backend.close()

    def test_incomplete_model_directory_is_not_ready(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            model_path = tmp_path / "empty-model"
            model_path.mkdir()
            request = GenerationRequest(
                mode="custom_voice",
                text="空目录不能被当成模型。",
                language="Chinese",
                model_id="qwen3-tts-12hz-0.6b-customvoice",
                voice={"speaker": "Serena"},
                instruct="自然",
                model_path=str(model_path),
            )

            with mock.patch.object(backend, "runtime_health", return_value={"real_inference_available": True}), \
                 mock.patch.object(backend, "_try_mlx_generate", return_value="outputs/should-not-run.wav") as generate:
                response = backend.generate(request)

            self.assertFalse(response["ok"])
            self.assertEqual(response["error"]["code"], "MODEL_NOT_READY")
            self.assertIn("config.json", response["error"]["details"]["missing_files"])
            generate.assert_not_called()
            backend.close()

    def test_generation_request_accepts_model_path_override(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            custom_model_path = tmp_path / "custom-model"
            custom_model_path.mkdir()
            (custom_model_path / "config.json").write_text("{}", encoding="utf-8")
            (custom_model_path / "model.safetensors").write_text("weights", encoding="utf-8")
            request = GenerationRequest(
                mode="custom_voice",
                text="指定模型路径应该传入真实推理层。",
                language="Chinese",
                model_id="qwen3-tts-12hz-0.6b-customvoice",
                voice={"speaker": "Serena"},
                instruct="自然",
                model_path=str(custom_model_path),
            )

            def fake_generate(received):
                self.assertEqual(received.model_path, str(custom_model_path))
                output_path = tmp_path / "outputs" / "path-override.wav"
                with wave.open(str(output_path), "wb") as wav:
                    wav.setnchannels(1)
                    wav.setsampwidth(2)
                    wav.setframerate(24_000)
                    wav.writeframes(b"\0\0" * 1200)
                return "outputs/path-override.wav"

            with mock.patch.object(backend, "runtime_health", return_value={"real_inference_available": True}), \
                 mock.patch.object(backend, "_try_mlx_generate", side_effect=fake_generate):
                response = backend.generate(request)

            self.assertTrue(response["ok"])
            self.assertEqual(response["result"]["runtime"], "mlx-audio")
            backend.close()

    def test_voice_clone_requires_consent_reference_audio_and_reference_text(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            request = GenerationRequest(
                mode="voice_clone",
                text="授权后才可以生成。",
                language="Chinese",
                model_id="qwen3-tts-12hz-0.6b-base",
                voice={"reference_audio": str(tmp_path / "ref.wav"), "reference_text": "参考文本"},
            )

            response = backend.generate(request)

            self.assertFalse(response["ok"])
            self.assertEqual(response["error"]["code"], "CONSENT_REQUIRED")
            backend.close()

    def test_voice_clone_passes_reference_audio_and_text_to_mlx_audio(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            model_path = tmp_path / "base-model"
            model_path.mkdir()
            (model_path / "config.json").write_text("{}", encoding="utf-8")
            (model_path / "model.safetensors").write_text("weights", encoding="utf-8")
            ref_audio = tmp_path / "reference.wav"
            ref_audio.write_bytes(b"fake wav")
            consent_id = backend.record_consent(ConsentRecord(audio_source=str(ref_audio), purpose="local test"))
            captured_kwargs = {}

            def fake_generate_audio(
                model,
                text,
                file_prefix,
                lang_code=None,
                instruct=None,
                voice=None,
                ref_audio=None,
                ref_text=None,
                verbose=False,
            ):
                captured_kwargs.update(
                    {
                        "model": model,
                        "text": text,
                        "file_prefix": file_prefix,
                        "lang_code": lang_code,
                        "instruct": instruct,
                        "voice": voice,
                        "ref_audio": ref_audio,
                        "ref_text": ref_text,
                        "verbose": verbose,
                    }
                )
                output_path = f"{file_prefix}.wav"
                with wave.open(output_path, "wb") as wav:
                    wav.setnchannels(1)
                    wav.setsampwidth(2)
                    wav.setframerate(24_000)
                    wav.writeframes(b"\0\0" * 1200)

            fake_generate_module = types.ModuleType("mlx_audio.tts.generate")
            fake_generate_module.generate_audio = fake_generate_audio
            fake_utils_module = types.ModuleType("mlx_audio.tts.utils")
            fake_utils_module.load_model = lambda path: {"model_path": str(path)}
            fake_tts_module = types.ModuleType("mlx_audio.tts")
            fake_root_module = types.ModuleType("mlx_audio")

            request = GenerationRequest(
                mode="voice_clone",
                text="请用参考音色读这句话。",
                language="Chinese",
                model_id="qwen3-tts-12hz-0.6b-base",
                voice={"ref_audio": str(ref_audio), "ref_text": "这是参考音频。", "consent_id": consent_id},
                instruct="保持参考音色",
                model_path=str(model_path),
            )

            with mock.patch.dict(
                sys.modules,
                {
                    "mlx_audio": fake_root_module,
                    "mlx_audio.tts": fake_tts_module,
                    "mlx_audio.tts.generate": fake_generate_module,
                    "mlx_audio.tts.utils": fake_utils_module,
                },
            ), mock.patch.object(backend, "runtime_health", return_value={"real_inference_available": True}):
                response = backend.generate(request)

            self.assertTrue(response["ok"])
            self.assertEqual(captured_kwargs["ref_audio"], str(ref_audio))
            self.assertEqual(captured_kwargs["ref_text"], "这是参考音频。")
            self.assertIsNone(captured_kwargs["instruct"])
            backend.close()

    def test_voice_clone_prefers_reusable_clone_prompt_when_available(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            model_path = tmp_path / "base-model"
            model_path.mkdir()
            (model_path / "config.json").write_text("{}", encoding="utf-8")
            (model_path / "model.safetensors").write_text("weights", encoding="utf-8")
            ref_audio = tmp_path / "reference.wav"
            ref_audio.write_bytes(b"fake wav")
            consent_id = backend.record_consent(ConsentRecord(audio_source=str(ref_audio), purpose="local test"))
            clone_prompt = tmp_path / "clone_prompts" / "saved.json"
            clone_prompt.parent.mkdir(parents=True, exist_ok=True)
            clone_prompt.write_text(
                json.dumps(
                    {
                        "ref_audio": str(ref_audio),
                        "ref_text": "这是可复用参考文本。",
                        "consent_id": consent_id,
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )
            captured_kwargs = {}

            def fake_generate_audio(
                model,
                text,
                file_prefix,
                lang_code=None,
                instruct=None,
                voice=None,
                ref_audio=None,
                ref_text=None,
                verbose=False,
            ):
                captured_kwargs.update(
                    {
                        "instruct": instruct,
                        "ref_audio": ref_audio,
                        "ref_text": ref_text,
                    }
                )
                output_path = f"{file_prefix}.wav"
                with wave.open(output_path, "wb") as wav:
                    wav.setnchannels(1)
                    wav.setsampwidth(2)
                    wav.setframerate(24_000)
                    wav.writeframes(b"\0\0" * 1200)

            fake_generate_module = types.ModuleType("mlx_audio.tts.generate")
            fake_generate_module.generate_audio = fake_generate_audio
            fake_utils_module = types.ModuleType("mlx_audio.tts.utils")
            fake_utils_module.load_model = lambda path: {"model_path": str(path)}
            fake_tts_module = types.ModuleType("mlx_audio.tts")
            fake_root_module = types.ModuleType("mlx_audio")

            request = GenerationRequest(
                mode="voice_clone",
                text="请复用保存好的音色。",
                language="Chinese",
                model_id="qwen3-tts-12hz-0.6b-base",
                voice={
                    "clone_prompt_path": str(clone_prompt.relative_to(tmp_path)),
                    "consent_id": consent_id,
                },
                instruct="保持参考音色",
                model_path=str(model_path),
            )

            with mock.patch.dict(
                sys.modules,
                {
                    "mlx_audio": fake_root_module,
                    "mlx_audio.tts": fake_tts_module,
                    "mlx_audio.tts.generate": fake_generate_module,
                    "mlx_audio.tts.utils": fake_utils_module,
                },
            ), mock.patch.object(backend, "runtime_health", return_value={"real_inference_available": True}):
                response = backend.generate(request)

            self.assertTrue(response["ok"])
            self.assertIsNone(captured_kwargs["instruct"])
            self.assertEqual(captured_kwargs["ref_audio"], str(ref_audio))
            self.assertEqual(captured_kwargs["ref_text"], "这是可复用参考文本。")
            backend.close()

    def test_create_voice_clone_prompt_marks_mlx_metadata_reuse_honestly(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            ref_audio = tmp_path / "reference.wav"
            ref_audio.write_bytes(b"fake wav")
            consent_id = backend.record_consent(ConsentRecord(audio_source=str(ref_audio), purpose="local test"))

            response = backend.create_voice_clone_prompt(
                {
                    "name": "角色 · 小林",
                    "language": "Chinese",
                    "ref_audio": str(ref_audio),
                    "ref_text": "虽然有点紧张，但我会用清楚稳定的声音把这段话说完。",
                    "consent_id": consent_id,
                }
            )

            self.assertTrue(response["ok"])
            self.assertEqual(response["result"]["reuse_method"], "ref_audio_ref_text")
            payload_path = tmp_path / response["result"]["clone_prompt_path"]
            payload = json.loads(payload_path.read_text(encoding="utf-8"))
            self.assertEqual(payload["prompt_kind"], "mlx_reference_metadata")
            self.assertEqual(payload["reuse_method"], "ref_audio_ref_text")
            backend.close()

    def test_generation_route_overrides_history_mode_for_multi_role_reuse(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            model_path = tmp_path / "base-model"
            model_path.mkdir()
            (model_path / "config.json").write_text("{}", encoding="utf-8")
            (model_path / "model.safetensors").write_text("weights", encoding="utf-8")
            ref_audio = tmp_path / "reference.wav"
            ref_audio.write_bytes(b"fake wav")
            consent_id = backend.record_consent(ConsentRecord(audio_source=str(ref_audio), purpose="local test"))
            request = GenerationRequest(
                mode="voice_clone",
                route="multi_role_reuse",
                text="我先确认一下这件事。",
                language="Chinese",
                model_id="qwen3-tts-12hz-1.7b-base",
                model_path=str(model_path),
                voice={"ref_audio": str(ref_audio), "ref_text": "参考文本。", "consent_id": consent_id},
            )

            def fake_generate(_request):
                output_path = tmp_path / "outputs" / "multi.wav"
                with wave.open(str(output_path), "wb") as wav:
                    wav.setnchannels(1)
                    wav.setsampwidth(2)
                    wav.setframerate(24_000)
                    wav.writeframes(b"\0\0" * 1200)
                return "outputs/multi.wav"

            with mock.patch.object(backend, "runtime_health", return_value={"real_inference_available": True}), \
                 mock.patch.object(backend, "_try_mlx_generate", side_effect=fake_generate):
                response = backend.generate(request)

            self.assertTrue(response["ok"])
            history = backend.generation_list()["generations"]
            self.assertEqual(history[0]["mode"], "multi_role_reuse")
            backend.close()

    def test_generation_request_carries_seed_for_role_live_generation(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            captured: list[GenerationRequest] = []

            def fake_generate(request: GenerationRequest) -> dict:
                captured.append(request)
                return {"ok": True, "result": {"audio_path": "outputs/role.wav"}}

            with mock.patch.object(backend, "generate", side_effect=fake_generate):
                response = backend._dispatch(
                    "tts.generate_voice_design",
                    {
                        "text": "啊？",
                        "language": "Chinese",
                        "model_id": "qwen3-tts-12hz-1.7b-voicedesign",
                        "voice": {},
                        "instruct": "小林，25岁男性上班族。",
                        "route": "multi_role_live",
                        "seed": 314159,
                    },
                )

            self.assertTrue(response["ok"])
            self.assertEqual(captured[0].route, "multi_role_live")
            self.assertEqual(captured[0].seed, 314159)
            backend.close()

    def test_mlx_generation_receives_seed_when_supported(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            model_path = tmp_path / "voice-design-model"
            model_path.mkdir()
            (model_path / "config.json").write_text("{}", encoding="utf-8")
            (model_path / "model.safetensors").write_text("weights", encoding="utf-8")
            captured_kwargs = {}

            def fake_generate_audio(**kwargs):
                captured_kwargs.update(kwargs)
                output = f"{kwargs['file_prefix']}_000.wav"
                with wave.open(output, "wb") as wav:
                    wav.setnchannels(1)
                    wav.setsampwidth(2)
                    wav.setframerate(24000)
                    wav.writeframes(b"\x00\x00")

            request = GenerationRequest(
                mode="voice_design",
                route="multi_role_live",
                text="啊？",
                language="Chinese",
                model_id="qwen3-tts-12hz-1.7b-voicedesign",
                model_path=str(model_path),
                voice={},
                instruct="小林，25岁男性上班族。",
                seed=271828,
            )

            with mock.patch("mlx_audio.tts.generate.generate_audio", side_effect=fake_generate_audio), \
                 mock.patch("mlx_audio.tts.utils.load_model", return_value=object()):
                output = backend._try_mlx_generate(request)

            self.assertIsNotNone(output)
            self.assertEqual(captured_kwargs["seed"], 271828)
            backend.close()

    def test_mlx_clone_generation_receives_seed_for_multi_role_reuse(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            model_path = tmp_path / "base-model"
            model_path.mkdir()
            (model_path / "config.json").write_text("{}", encoding="utf-8")
            (model_path / "model.safetensors").write_text("weights", encoding="utf-8")
            ref_audio = tmp_path / "xiaolin.wav"
            ref_audio.write_bytes(b"fake wav")
            consent_id = backend.record_consent(ConsentRecord(audio_source=str(ref_audio), purpose="local test"))
            captured_kwargs = {}

            def fake_generate_audio(**kwargs):
                captured_kwargs.update(kwargs)
                output = f"{kwargs['file_prefix']}_000.wav"
                with wave.open(output, "wb") as wav:
                    wav.setnchannels(1)
                    wav.setsampwidth(2)
                    wav.setframerate(24000)
                    wav.writeframes(b"\x00\x00")

            request = GenerationRequest(
                mode="voice_clone",
                route="multi_role_reuse",
                text="啊？我、我其实不太会喝酒。",
                language="Chinese",
                model_id="qwen3-tts-12hz-1.7b-base",
                model_path=str(model_path),
                voice={"ref_audio": str(ref_audio), "ref_text": "我先确认一下这件事。", "consent_id": consent_id},
                instruct="不应该传给 Base",
                seed=13579,
            )

            with mock.patch("mlx_audio.tts.generate.generate_audio", side_effect=fake_generate_audio), \
                 mock.patch("mlx_audio.tts.utils.load_model", return_value=object()):
                output = backend._try_mlx_generate(request)

            self.assertIsNotNone(output)
            self.assertEqual(captured_kwargs["seed"], 13579)
            self.assertEqual(captured_kwargs["text"], "啊？我、我其实不太会喝酒。")
            self.assertEqual(captured_kwargs["ref_audio"], str(ref_audio))
            self.assertEqual(captured_kwargs["ref_text"], "我先确认一下这件事。")
            self.assertNotIn("instruct", captured_kwargs)
            backend.close()

    def test_real_generation_reuses_cached_model_for_same_model_path(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            model_path = tmp_path / "custom-model"
            model_path.mkdir()
            (model_path / "config.json").write_text("{}", encoding="utf-8")
            (model_path / "model.safetensors").write_text("weights", encoding="utf-8")
            load_calls = []

            def fake_generate_audio(model, text, file_prefix, **kwargs):
                output_path = f"{file_prefix}.wav"
                with wave.open(output_path, "wb") as wav:
                    wav.setnchannels(1)
                    wav.setsampwidth(2)
                    wav.setframerate(24_000)
                    wav.writeframes(b"\0\0" * 1200)

            fake_generate_module = types.ModuleType("mlx_audio.tts.generate")
            fake_generate_module.generate_audio = fake_generate_audio
            fake_utils_module = types.ModuleType("mlx_audio.tts.utils")

            def fake_load_model(path):
                load_calls.append(str(path))
                return {"model_path": str(path)}

            fake_utils_module.load_model = fake_load_model
            fake_tts_module = types.ModuleType("mlx_audio.tts")
            fake_root_module = types.ModuleType("mlx_audio")
            request = GenerationRequest(
                mode="custom_voice",
                text="同一个模型连续生成应该复用缓存。",
                language="Chinese",
                model_id="qwen3-tts-12hz-0.6b-customvoice",
                voice={"speaker": "Serena"},
                instruct="自然",
                model_path=str(model_path),
            )

            with mock.patch.dict(
                sys.modules,
                {
                    "mlx_audio": fake_root_module,
                    "mlx_audio.tts": fake_tts_module,
                    "mlx_audio.tts.generate": fake_generate_module,
                    "mlx_audio.tts.utils": fake_utils_module,
                },
            ), mock.patch.object(backend, "runtime_health", return_value={"real_inference_available": True}):
                first = backend.generate(request)
                second = backend.generate(request)

            self.assertTrue(first["ok"])
            self.assertTrue(second["ok"])
            self.assertEqual(load_calls, [str(model_path)])
            backend.close()

    def test_real_generation_never_passes_speaker_labels_to_mlx_audio(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            model_path = tmp_path / "custom-model"
            model_path.mkdir()
            (model_path / "config.json").write_text("{}", encoding="utf-8")
            (model_path / "model.safetensors").write_text("weights", encoding="utf-8")
            captured_kwargs = {}

            def fake_generate_audio(model, text, file_prefix, **kwargs):
                captured_kwargs["text"] = text
                output_path = f"{file_prefix}.wav"
                with wave.open(output_path, "wb") as wav:
                    wav.setnchannels(1)
                    wav.setsampwidth(2)
                    wav.setframerate(24_000)
                    wav.writeframes(b"\0\0" * 1200)

            fake_generate_module = types.ModuleType("mlx_audio.tts.generate")
            fake_generate_module.generate_audio = fake_generate_audio
            fake_utils_module = types.ModuleType("mlx_audio.tts.utils")
            fake_utils_module.load_model = lambda path: {"model_path": str(path)}
            fake_tts_module = types.ModuleType("mlx_audio.tts")
            fake_root_module = types.ModuleType("mlx_audio")
            request = GenerationRequest(
                mode="custom_voice",
                text="旁白: 小林今天第三次走神了。\n小林：我、我其实不太会喝酒。",
                language="Chinese",
                model_id="qwen3-tts-12hz-0.6b-customvoice",
                voice={"speaker": "Serena"},
                instruct="自然",
                model_path=str(model_path),
            )

            with mock.patch.dict(
                sys.modules,
                {
                    "mlx_audio": fake_root_module,
                    "mlx_audio.tts": fake_tts_module,
                    "mlx_audio.tts.generate": fake_generate_module,
                    "mlx_audio.tts.utils": fake_utils_module,
                },
            ), mock.patch.object(backend, "runtime_health", return_value={"real_inference_available": True}):
                response = backend.generate(request)

            self.assertTrue(response["ok"])
            self.assertEqual(captured_kwargs["text"], "小林今天第三次走神了。\n我、我其实不太会喝酒。")
            backend.close()

    def test_audio_concat_legacy_method_returns_webm_workspace_audio_file(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            first = tmp_path / "outputs" / "first.wav"
            second = tmp_path / "outputs" / "second.wav"
            for path, frames in [(first, 100), (second, 150)]:
                with wave.open(str(path), "wb") as wav:
                    wav.setnchannels(1)
                    wav.setsampwidth(2)
                    wav.setframerate(24_000)
                    wav.writeframes(b"\0\0" * frames)

            response = json.loads(
                backend.handle_json(
                    json.dumps(
                        {
                            "id": 9,
                            "method": "audio.concat_wav",
                            "params": {
                                "paths": ["outputs/first.wav", "outputs/second.wav"],
                                "name": "full.wav",
                            },
                        }
                    )
                )
            )

            self.assertTrue(response["result"]["ok"])
            output_path = tmp_path / response["result"]["result"]["audio_path"]
            self.assertTrue(output_path.exists())
            self.assertEqual(output_path.suffix, ".webm")
            backend.close()

    def test_audio_concat_wav_can_insert_inter_segment_silence(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            first = tmp_path / "outputs" / "first.wav"
            second = tmp_path / "outputs" / "second.wav"
            for path, frames in [(first, 100), (second, 150)]:
                with wave.open(str(path), "wb") as wav:
                    wav.setnchannels(1)
                    wav.setsampwidth(2)
                    wav.setframerate(24_000)
                    wav.writeframes(b"\0\0" * frames)

            response = json.loads(
                backend.handle_json(
                    json.dumps(
                        {
                            "id": 10,
                            "method": "audio.concat_wav",
                            "params": {
                                "paths": ["outputs/first.wav", "outputs/second.wav"],
                                "name": "dialogue-full.wav",
                                "gap_seconds": 0.5,
                            },
                        }
                    )
                )
            )

            self.assertTrue(response["result"]["ok"])
            output_path = tmp_path / response["result"]["result"]["audio_path"]
            self.assertEqual(output_path.suffix, ".webm")
            backend.close()

    def test_audio_concat_audio_returns_webm(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            first = tmp_path / "outputs" / "first.wav"
            second = tmp_path / "outputs" / "second.wav"
            for path, frames in [(first, 100), (second, 150)]:
                with wave.open(str(path), "wb") as wav:
                    wav.setnchannels(1)
                    wav.setsampwidth(2)
                    wav.setframerate(24_000)
                    wav.writeframes(b"\0\0" * frames)

            response = json.loads(
                backend.handle_json(
                    json.dumps(
                        {
                            "id": 11,
                            "method": "audio.concat_audio",
                            "params": {
                                "paths": ["outputs/first.wav", "outputs/second.wav"],
                                "name": "full",
                            },
                        }
                    )
                )
            )

            self.assertTrue(response["result"]["ok"])
            audio_path = response["result"]["result"]["audio_path"]
            self.assertTrue(audio_path.endswith(".webm"))
            self.assertTrue((tmp_path / audio_path).exists())
            backend.close()

    def test_audio_concat_accepts_supported_suffixes_case_insensitively(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            first = tmp_path / "outputs" / "UPPER.WEBM"
            second = tmp_path / "outputs" / "second.MP3"
            first.write_bytes(b"webm")
            second.write_bytes(b"mp3")
            captured_paths = []

            def fake_concat(audio_paths, output_path, gap_seconds=0.0):
                captured_paths.extend(path.name for path in audio_paths)
                output_path.write_bytes(b"webm")

            with mock.patch.object(backend, "_concat_audio_files", side_effect=fake_concat), \
                 mock.patch.object(backend, "_audio_sample_rate", return_value=24_000):
                response = json.loads(
                    backend.handle_json(
                        json.dumps(
                            {
                                "id": 12,
                                "method": "audio.concat_audio",
                                "params": {
                                    "paths": ["outputs/UPPER.WEBM", "outputs/second.MP3"],
                                    "name": "mixed.WEBM",
                                },
                            }
                        )
                    )
                )

            self.assertTrue(response["result"]["ok"])
            self.assertEqual(captured_paths, ["UPPER.WEBM", "second.MP3"])
            self.assertTrue(response["result"]["result"]["audio_path"].endswith(".WEBM"))
            backend.close()

    def test_diagnostic_tone_is_the_only_stub_path(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)

            response = json.loads(
                backend.handle_json(
                    json.dumps(
                        {
                            "id": 4,
                            "method": "diagnostic.generate_tone",
                            "params": {
                                "text": "这是一个显式诊断测试音。",
                                "model_id": "diagnostic-tone",
                            },
                        }
                    )
                )
            )

            self.assertTrue(response["result"]["ok"])
            output_path = tmp_path / response["result"]["result"]["audio_path"]
            self.assertTrue(output_path.exists())
            self.assertEqual(output_path.suffix, ".webm")
            backend.close()

    def test_generation_list_records_failed_generation(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)
            request = GenerationRequest(
                mode="custom_voice",
                text="失败也要进入历史，方便 UI 诊断。",
                language="Chinese",
                model_id="qwen3-tts-12hz-0.6b-customvoice",
                voice={"speaker": "Serena"},
                instruct="自然",
            )

            with mock.patch.object(backend, "_try_mlx_generate", return_value=None):
                backend.generate(request)
            response = json.loads(
                backend.handle_json(json.dumps({"id": 5, "method": "generation.list", "params": {}}))
            )

            generations = response["result"]["generations"]
            self.assertGreaterEqual(len(generations), 1)
            self.assertIn(generations[0]["status"], {"failed", "ready"})
            self.assertIn("runtime", generations[0])
            backend.close()

    def test_json_rpc_models_list(self):
        with TemporaryDirectoryPath() as tmp_path:
            backend = QwenVoiceBackend(data_dir=tmp_path)

            response = backend.handle_json(json.dumps({"id": 1, "method": "models.list", "params": {}}))

            payload = json.loads(response)
            self.assertEqual(payload["id"], 1)
            self.assertEqual(payload["result"]["models"][0]["id"], "qwen3-tts-12hz-0.6b-customvoice")
            backend.close()


class TemporaryDirectoryPath:
    def __enter__(self):
        import tempfile
        from pathlib import Path

        self._tmp = tempfile.TemporaryDirectory()
        return Path(self._tmp.name)

    def __exit__(self, exc_type, exc, traceback):
        self._tmp.cleanup()
