#!/usr/bin/env bash
set -euo pipefail

APP_SUPPORT_DIR="${VOICE_STUDIO_APP_SUPPORT_DIR:-$HOME/Library/Application Support/VoiceStudio}"
RUNTIME_DIR="${VOICE_STUDIO_RUNTIME_DIR:-$APP_SUPPORT_DIR/runtime}"
VENV_DIR="$RUNTIME_DIR/venv"
BIN_DIR="$RUNTIME_DIR/bin"
CONSTRAINTS_FILE="$RUNTIME_DIR/pip-constraints.txt"
TOTAL_STEPS=9
REQUIRED_PYTHON_VERSION="3.12"
REQUIRED_PYTHON_KEY=312
PYTHON_FORMULA="python@3.12"

mkdir -p "$RUNTIME_DIR" "$BIN_DIR"

log() {
  printf '%s\n' "$*" >&2
}

step() {
  local current="$1"
  shift
  log "VOICE_STUDIO_STEP ${current}/${TOTAL_STEPS} $*"
}

python_info() {
  "$1" - <<'PY'
import platform
import ssl
import sys
print(f"executable={sys.executable}")
print(f"version={sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")
print(f"ssl={getattr(ssl, 'OPENSSL_VERSION', 'unknown')}")
print(f"machine={platform.machine()}")
PY
}

python_version_key() {
  "$1" - <<'PY'
import sys
print(sys.version_info.major * 100 + sys.version_info.minor)
PY
}

python_ssl_version() {
  "$1" - <<'PY'
import ssl
print(getattr(ssl, "OPENSSL_VERSION", "unknown"))
PY
}

find_brew() {
  for candidate in "/opt/homebrew/bin/brew" "/usr/local/bin/brew"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi
  return 1
}

find_python() {
  if [[ -n "${VOICE_STUDIO_BOOTSTRAP_PYTHON:-}" && -x "${VOICE_STUDIO_BOOTSTRAP_PYTHON:-}" ]]; then
    printf '%s\n' "$VOICE_STUDIO_BOOTSTRAP_PYTHON"
    return 0
  fi
  for candidate in \
    "/opt/homebrew/bin/python3.12" \
    "/usr/local/bin/python3.12" \
    "/opt/homebrew/opt/python@3.12/bin/python3.12" \
    "/usr/local/opt/python@3.12/bin/python3.12" \
    "/opt/homebrew/bin/python3" \
    "/usr/local/bin/python3" \
    "/usr/bin/python3"
  do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  if command -v python3.12 >/dev/null 2>&1; then
    command -v python3.12
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    command -v python3
    return 0
  fi
  return 1
}

brew_python_candidate() {
  for candidate in \
    "/opt/homebrew/bin/python3.12" \
    "/usr/local/bin/python3.12" \
    "/opt/homebrew/opt/python@3.12/bin/python3.12" \
    "/usr/local/opt/python@3.12/bin/python3.12"
  do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  if command -v python3.12 >/dev/null 2>&1; then
    command -v python3.12
    return 0
  fi
  return 1
}

ensure_brew_python_if_needed() {
  local current_python="$1"
  local version_key
  version_key="$(python_version_key "$current_python")"
  local ssl_version
  ssl_version="$(python_ssl_version "$current_python")"
  if [[ "$version_key" -eq "$REQUIRED_PYTHON_KEY" && "$ssl_version" != *"LibreSSL"* ]]; then
    printf '%s\n' "$current_python"
    return 0
  fi
  log "Bootstrap Python is not the recommended Voice Studio runtime Python ${REQUIRED_PYTHON_VERSION}, or it may be incompatible with modern HTTPS packages:"
  python_info "$current_python" >&2
  local brew_bin
  if ! brew_bin="$(find_brew)"; then
    if [[ "$version_key" -eq "$REQUIRED_PYTHON_KEY" ]]; then
      log "Homebrew is not installed, but Python ${REQUIRED_PYTHON_VERSION} is available. The installer will continue."
      printf '%s\n' "$current_python"
      return 0
    fi
    log "Homebrew is not installed and Python ${REQUIRED_PYTHON_VERSION} was not found."
    log "Install Homebrew from https://brew.sh, then run: brew install ${PYTHON_FORMULA} ffmpeg"
    log "After that, rerun this installer from Voice Studio."
    return 1
  fi
  log "Installing/updating Homebrew ${PYTHON_FORMULA} to create a stable Python ${REQUIRED_PYTHON_VERSION} runtime..."
  "$brew_bin" install "$PYTHON_FORMULA" >&2 || "$brew_bin" upgrade "$PYTHON_FORMULA" >&2 || true
  if brew_python="$(brew_python_candidate)"; then
    printf '%s\n' "$brew_python"
    return 0
  fi
  log "Homebrew Python ${REQUIRED_PYTHON_VERSION} was not found after brew install; continuing with compatibility pin."
  printf '%s\n' "$current_python"
}

ensure_homebrew_package() {
  local package_name="$1"
  local binary_name="$2"
  if command -v "$binary_name" >/dev/null 2>&1; then
    log "$binary_name already available: $(command -v "$binary_name")"
    return 0
  fi
  for candidate in "/opt/homebrew/bin/$binary_name" "/usr/local/bin/$binary_name"; do
    if [[ -x "$candidate" ]]; then
      log "$binary_name already available: $candidate"
      return 0
    fi
  done
  local brew_bin
  if ! brew_bin="$(find_brew)"; then
    log "Homebrew is not installed; cannot install $package_name automatically."
    log "Install Homebrew first, then rerun this installer: https://brew.sh"
    return 1
  fi
  log "Installing $package_name via Homebrew..."
  "$brew_bin" install "$package_name"
}

step 1 "检查系统和 Python"
if ! PYTHON_BIN="$(find_python)"; then
  log "python3 not found."
  log "Install Homebrew ${PYTHON_FORMULA}, then rerun this installer."
  exit 1
fi
PYTHON_BIN="$(ensure_brew_python_if_needed "$PYTHON_BIN")"

log "Using bootstrap Python:"
python_info "$PYTHON_BIN"
log "Runtime directory: $RUNTIME_DIR"

step 2 "创建 Voice Studio 专用 Python 环境"
if [[ -x "$VENV_DIR/bin/python3" ]]; then
  VENV_VERSION_KEY="$(python_version_key "$VENV_DIR/bin/python3" || printf '0\n')"
  VENV_EXISTING_SSL="$(python_ssl_version "$VENV_DIR/bin/python3" || printf 'unknown\n')"
  if [[ "$VENV_VERSION_KEY" -ne "$REQUIRED_PYTHON_KEY" || "$VENV_EXISTING_SSL" == *"LibreSSL"* ]]; then
    log "Existing runtime venv is incompatible and will be rebuilt:"
    python_info "$VENV_DIR/bin/python3" >&2 || true
    rm -rf "$VENV_DIR"
  else
    log "Existing runtime venv is compatible; refreshing packages in place."
    python_info "$VENV_DIR/bin/python3" >&2 || true
  fi
fi
"$PYTHON_BIN" -m venv "$VENV_DIR"
VENV_PYTHON="$VENV_DIR/bin/python3"

step 3 "检查 SSL 兼容性"
VENV_SSL_VERSION="$(python_ssl_version "$VENV_PYTHON")"
rm -f "$CONSTRAINTS_FILE"
if [[ "$VENV_SSL_VERSION" == *"LibreSSL"* ]]; then
  log "Detected LibreSSL in runtime Python: $VENV_SSL_VERSION"
  log "Pinning urllib3<2 to avoid urllib3 v2 OpenSSL requirement."
  printf '%s\n' "urllib3<2" > "$CONSTRAINTS_FILE"
else
  log "Runtime Python SSL: $VENV_SSL_VERSION"
fi

pip_install() {
  if [[ -f "$CONSTRAINTS_FILE" ]]; then
    "$VENV_PYTHON" -m pip install --upgrade --constraint "$CONSTRAINTS_FILE" "$@"
  else
    "$VENV_PYTHON" -m pip install --upgrade "$@"
  fi
}

step 4 "升级 pip 基础工具"
log "Upgrading pip tooling..."
pip_install pip setuptools wheel

step 5 "安装 MLX / mlx-audio / Transformers"
log "Installing Voice Studio runtime packages..."
pip_install \
  mlx \
  mlx-audio \
  transformers \
  numpy \
  "huggingface_hub[cli]" \
  hf_transfer \
  soundfile

if [[ -x "$VENV_DIR/bin/hf" ]]; then
  ln -sf "$VENV_DIR/bin/hf" "$BIN_DIR/hf"
elif [[ -x "$VENV_DIR/bin/huggingface-cli" ]]; then
  ln -sf "$VENV_DIR/bin/huggingface-cli" "$BIN_DIR/hf"
else
  log "Hugging Face CLI command 'hf' was not installed."
  log "Try manually: $VENV_PYTHON -m pip install --upgrade 'huggingface_hub[cli]' hf_transfer"
  exit 1
fi
"$BIN_DIR/hf" --help >/dev/null
log "hf: $BIN_DIR/hf"

step 6 "检查 ffmpeg / ffprobe"
ensure_homebrew_package "ffmpeg" "ffmpeg"

step 7 "记录音频工具路径"
if command -v ffmpeg >/dev/null 2>&1; then
  ln -sf "$(command -v ffmpeg)" "$BIN_DIR/ffmpeg"
elif [[ -x /opt/homebrew/bin/ffmpeg ]]; then
  ln -sf /opt/homebrew/bin/ffmpeg "$BIN_DIR/ffmpeg"
elif [[ -x /usr/local/bin/ffmpeg ]]; then
  ln -sf /usr/local/bin/ffmpeg "$BIN_DIR/ffmpeg"
fi

if command -v ffprobe >/dev/null 2>&1; then
  ln -sf "$(command -v ffprobe)" "$BIN_DIR/ffprobe"
elif [[ -x /opt/homebrew/bin/ffprobe ]]; then
  ln -sf /opt/homebrew/bin/ffprobe "$BIN_DIR/ffprobe"
elif [[ -x /usr/local/bin/ffprobe ]]; then
  ln -sf /usr/local/bin/ffprobe "$BIN_DIR/ffprobe"
fi

step 8 "验证 Python 依赖导入"
log "Verifying Python runtime imports..."
"$VENV_PYTHON" - <<'PY'
import importlib
for name in ["mlx", "mlx_audio", "transformers", "numpy", "huggingface_hub"]:
    importlib.import_module(name)
    print(f"{name}: ok")
PY

step 9 "完成运行环境安装"
log "Voice Studio runtime installed."
log "Python: $VENV_PYTHON"
if [[ -x "$BIN_DIR/ffmpeg" ]]; then
  log "ffmpeg: $BIN_DIR/ffmpeg"
fi
if [[ -x "$BIN_DIR/ffprobe" ]]; then
  log "ffprobe: $BIN_DIR/ffprobe"
fi
