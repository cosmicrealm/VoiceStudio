#!/usr/bin/env bash
set -euo pipefail

APP_SUPPORT_DIR="${VOICE_STUDIO_APP_SUPPORT_DIR:-$HOME/Library/Application Support/VoiceStudio}"
RUNTIME_DIR="${VOICE_STUDIO_RUNTIME_DIR:-$APP_SUPPORT_DIR/runtime}"
VENV_DIR="$RUNTIME_DIR/venv"
BIN_DIR="$RUNTIME_DIR/bin"

mkdir -p "$RUNTIME_DIR" "$BIN_DIR"

log() {
  printf '%s\n' "$*"
}

find_python() {
  if [[ -n "${VOICE_STUDIO_BOOTSTRAP_PYTHON:-}" && -x "${VOICE_STUDIO_BOOTSTRAP_PYTHON:-}" ]]; then
    printf '%s\n' "$VOICE_STUDIO_BOOTSTRAP_PYTHON"
    return 0
  fi
  for candidate in \
    "/opt/homebrew/bin/python3" \
    "/usr/local/bin/python3" \
    "/usr/bin/python3"
  do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  if command -v python3 >/dev/null 2>&1; then
    command -v python3
    return 0
  fi
  return 1
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
  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew is not installed; cannot install $package_name automatically."
    log "Install Homebrew first, then rerun this installer: https://brew.sh"
    return 1
  fi
  log "Installing $package_name via Homebrew..."
  brew install "$package_name"
}

if ! PYTHON_BIN="$(find_python)"; then
  log "python3 not found."
  log "Install Python 3.10+ or Homebrew Python, then rerun this installer."
  exit 1
fi

log "Using bootstrap Python: $PYTHON_BIN"
log "Runtime directory: $RUNTIME_DIR"

"$PYTHON_BIN" -m venv "$VENV_DIR"
VENV_PYTHON="$VENV_DIR/bin/python3"

log "Upgrading pip tooling..."
"$VENV_PYTHON" -m pip install --upgrade pip setuptools wheel

log "Installing Voice Studio runtime packages..."
"$VENV_PYTHON" -m pip install --upgrade \
  mlx \
  mlx-audio \
  transformers \
  numpy \
  huggingface_hub \
  hf_transfer \
  soundfile

ensure_homebrew_package "ffmpeg" "ffmpeg"

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

log "Verifying Python runtime imports..."
"$VENV_PYTHON" - <<'PY'
import importlib
for name in ["mlx", "mlx_audio", "transformers", "numpy", "huggingface_hub"]:
    importlib.import_module(name)
    print(f"{name}: ok")
PY

log "Voice Studio runtime installed."
log "Python: $VENV_PYTHON"
if [[ -x "$BIN_DIR/ffmpeg" ]]; then
  log "ffmpeg: $BIN_DIR/ffmpeg"
fi
