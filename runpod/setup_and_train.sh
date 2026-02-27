#!/usr/bin/env bash
# Run this on a RunPod GPU instance (e.g. A100 40GB or RTX 4090).
# Prereqs: dataset at /workspace/dataset (images + .txt captions), HuggingFace token for FLUX.1-dev.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLKIT_DIR="$PROJECT_ROOT/ai-toolkit"
CONFIG_NAME="ohwx_influencer_runpod.yaml"
CONFIG_SRC="$PROJECT_ROOT/config/$CONFIG_NAME"

# Use /workspace/dataset if present, else project dataset (full repo upload)
export DATASET_PATH="${DATASET_PATH:-/workspace/dataset}"
if [ ! -d "$DATASET_PATH" ]; then
  DATASET_PATH="$PROJECT_ROOT/dataset"
fi
if [ ! -d "$DATASET_PATH" ]; then
  echo "ERROR: No dataset found. Put images + .txt captions in /workspace/dataset or in project dataset/"
  exit 1
fi
echo "Using dataset: $DATASET_PATH"

# Copy config and set dataset path (so /workspace/dataset or project dataset/ both work)
mkdir -p "$TOOLKIT_DIR/config"
CONFIG_OUT="$TOOLKIT_DIR/config/$CONFIG_NAME"
sed "s|folder_path: .*|folder_path: $DATASET_PATH|" "$CONFIG_SRC" > "$CONFIG_OUT"
echo "Config written to $CONFIG_OUT (dataset: $DATASET_PATH)"

echo "[1/4] Cloning ostris/ai-toolkit (CUDA)..."
if [ -d "$TOOLKIT_DIR/.git" ]; then
  cd "$TOOLKIT_DIR"
  git pull --ff-only || true
  git submodule update --init --recursive
else
  cd "$PROJECT_ROOT"
  git clone https://github.com/ostris/ai-toolkit.git
  cd "$TOOLKIT_DIR"
  git submodule update --init --recursive
fi
# Compatibility: use torch.optim.AdamW (transformers removed AdamW in v5)
sed -i.bak 's/from transformers import Adafactor, AdamW/from transformers import Adafactor/' "$TOOLKIT_DIR/toolkit/optimizer.py" 2>/dev/null || true

echo "[2/4] Creating venv and installing dependencies..."
PYTHON="${PYTHON:-python3}"
if [ ! -d "$TOOLKIT_DIR/venv" ]; then
  $PYTHON -m venv "$TOOLKIT_DIR/venv"
fi
source "$TOOLKIT_DIR/venv/bin/activate"
pip install --upgrade pip setuptools wheel -q
pip install torch torchvision torchaudio -q
pip install -r "$TOOLKIT_DIR/requirements.txt" -q
pip install 'transformers<5.0.0' 'setuptools<70' -q 2>/dev/null || true

echo "[3/4] HuggingFace login (required for FLUX.1-dev)..."
if ! python -c "from huggingface_hub import HfApi; HfApi().whoami()" 2>/dev/null; then
  echo "Run: huggingface-cli login   (paste your token, accept FLUX.1-dev license at https://huggingface.co/black-forest-labs/FLUX.1-dev)"
  huggingface-cli login
fi

echo "[4/4] Starting training..."
cd "$TOOLKIT_DIR"
python run.py "config/$CONFIG_NAME"

echo "Done. LoRA files: $TOOLKIT_DIR/output/ohwx_influencer/"
