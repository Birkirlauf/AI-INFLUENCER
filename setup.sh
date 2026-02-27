#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLKIT_DIR="$PROJECT_DIR/ai-toolkit"
CONFIG_SRC="$PROJECT_DIR/config/ohwx_influencer.yaml"

echo "============================================"
echo "  AI Influencer - Phase 1 Setup"
echo "  Mac Mini M4 Pro (24GB)"
echo "============================================"
echo ""

# ── Check prerequisites ──────────────────────────────────────────────────────

echo "[1/5] Checking prerequisites..."

if ! command -v python3.11 &>/dev/null; then
    echo "ERROR: Python 3.11 not found."
    echo "  Install it with: brew install python@3.11"
    exit 1
fi
echo "  Python 3.11: $(python3.11 --version)"

if ! command -v git &>/dev/null; then
    echo "ERROR: git not found."
    echo "  Install it with: brew install git"
    exit 1
fi
echo "  Git: $(git --version)"

# ── Clone ai-toolkit ─────────────────────────────────────────────────────────

echo ""
echo "[2/5] Setting up ai-toolkit..."

if [ -d "$TOOLKIT_DIR" ]; then
    echo "  ai-toolkit already exists, pulling latest..."
    cd "$TOOLKIT_DIR"
    git pull --ff-only || true
    git submodule update --init --recursive
else
    cd "$PROJECT_DIR"
    git clone https://github.com/hughescr/ai-toolkit.git
    cd "$TOOLKIT_DIR"
    git submodule update --init --recursive
fi

# ── Create venv and install deps ─────────────────────────────────────────────

echo ""
echo "[3/5] Creating Python virtual environment..."

if [ ! -d "$TOOLKIT_DIR/venv" ]; then
    python3.11 -m venv "$TOOLKIT_DIR/venv"
    echo "  Created venv at ai-toolkit/venv/"
else
    echo "  venv already exists, skipping creation"
fi

source "$TOOLKIT_DIR/venv/bin/activate"

echo ""
echo "[4/5] Installing PyTorch + ai-toolkit dependencies..."
echo "  This may take a few minutes..."

pip install --upgrade pip setuptools wheel -q
pip install torch torchvision torchaudio -q
pip install -r "$TOOLKIT_DIR/requirements.txt" -q

echo "  Done. PyTorch MPS available: $(python -c 'import torch; print(torch.backends.mps.is_available())')"

# ── Symlink config ───────────────────────────────────────────────────────────

echo ""
echo "[5/5] Linking training config..."

mkdir -p "$TOOLKIT_DIR/config"
ln -sf "$CONFIG_SRC" "$TOOLKIT_DIR/config/ohwx_influencer.yaml"
echo "  Linked config/ohwx_influencer.yaml -> ai-toolkit/config/"

# ── HuggingFace login reminder ───────────────────────────────────────────────

echo ""
echo "============================================"
echo "  Setup complete!"
echo "============================================"
echo ""
echo "NEXT STEPS:"
echo ""
echo "  1. Log in to HuggingFace (needed to download FLUX.1-dev):"
echo "     cd \"$TOOLKIT_DIR\""
echo "     source venv/bin/activate"
echo "     huggingface-cli login"
echo ""
echo "     You need a HuggingFace account and must accept the"
echo "     FLUX.1-dev license at:"
echo "     https://huggingface.co/black-forest-labs/FLUX.1-dev"
echo ""
echo "  2. Start training:"
echo "     ./train.sh"
echo ""
