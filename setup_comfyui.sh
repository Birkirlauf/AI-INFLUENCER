#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMFY_DIR="$PROJECT_DIR/ComfyUI"
TOOLKIT_OUTPUT="$PROJECT_DIR/ai-toolkit/output/ohwx_influencer"

echo "============================================"
echo "  AI Influencer - Phase 2: ComfyUI Setup"
echo "============================================"
echo ""

# ── Check prerequisites ──────────────────────────────────────────────────────

echo "[1/4] Checking prerequisites..."

if ! command -v python3.11 &>/dev/null; then
    echo "ERROR: Python 3.11 not found."
    echo "  Install it with: brew install python@3.11"
    exit 1
fi
echo "  Python 3.11: $(python3.11 --version)"

# ── Clone ComfyUI ────────────────────────────────────────────────────────────

echo ""
echo "[2/4] Setting up ComfyUI..."

if [ -d "$COMFY_DIR" ]; then
    echo "  ComfyUI already exists, pulling latest..."
    cd "$COMFY_DIR"
    git pull --ff-only || true
else
    cd "$PROJECT_DIR"
    git clone https://github.com/comfyanonymous/ComfyUI.git
fi

# ── Create venv and install deps ─────────────────────────────────────────────

echo ""
echo "[3/4] Creating Python virtual environment..."

if [ ! -d "$COMFY_DIR/venv" ]; then
    python3.11 -m venv "$COMFY_DIR/venv"
    echo "  Created venv at ComfyUI/venv/"
else
    echo "  venv already exists, skipping creation"
fi

source "$COMFY_DIR/venv/bin/activate"

echo "  Installing PyTorch + ComfyUI dependencies..."
pip install --upgrade pip setuptools wheel -q
pip install torch torchvision torchaudio -q
pip install -r "$COMFY_DIR/requirements.txt" -q

echo "  Done."

# ── Create model directories and symlink LoRA ────────────────────────────────

echo ""
echo "[4/4] Setting up model directories..."

mkdir -p "$COMFY_DIR/models/checkpoints"
mkdir -p "$COMFY_DIR/models/loras"
mkdir -p "$COMFY_DIR/models/clip"
mkdir -p "$COMFY_DIR/models/vae"

LORA_FILE=$(find "$TOOLKIT_OUTPUT" -name "*.safetensors" -type f 2>/dev/null | sort | tail -1)
if [ -n "$LORA_FILE" ]; then
    LORA_NAME=$(basename "$LORA_FILE")
    ln -sf "$LORA_FILE" "$COMFY_DIR/models/loras/$LORA_NAME"
    echo "  Linked LoRA: $LORA_NAME -> ComfyUI/models/loras/"
else
    echo "  No LoRA file found yet in ai-toolkit/output/"
    echo "  Run training first (./train.sh), then re-run this script"
    echo "  or manually copy your .safetensors to ComfyUI/models/loras/"
fi

echo ""
echo "============================================"
echo "  ComfyUI setup complete!"
echo "============================================"
echo ""
echo "MODEL SETUP:"
echo ""
echo "  You need the FLUX.1-dev model files in ComfyUI/models/."
echo "  The easiest way is to download them via the ComfyUI Manager"
echo "  or manually place them:"
echo ""
echo "    ComfyUI/models/"
echo "      checkpoints/  <- FLUX.1-dev checkpoint (or symlink)"
echo "      loras/        <- Your trained LoRA (linked above if found)"
echo "      clip/         <- FLUX text encoders"
echo "      vae/          <- FLUX VAE"
echo ""
echo "  If you already downloaded FLUX.1-dev during training,"
echo "  it's cached in ~/.cache/huggingface/ and ComfyUI"
echo "  can load it from there via the model path."
echo ""
echo "LAUNCH:"
echo "  ./run_comfyui.sh"
echo ""
