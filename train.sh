#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLKIT_DIR="$PROJECT_DIR/ai-toolkit"
CONFIG="config/ohwx_influencer.yaml"

if [ ! -d "$TOOLKIT_DIR/venv" ]; then
    echo "ERROR: ai-toolkit not set up yet. Run ./setup.sh first."
    exit 1
fi

source "$TOOLKIT_DIR/venv/bin/activate"
cd "$TOOLKIT_DIR"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Training config not found at ai-toolkit/$CONFIG"
    echo "  Run ./setup.sh to link it."
    exit 1
fi

echo "============================================"
echo "  Starting FLUX LoRA Training"
echo "============================================"
echo ""
echo "  Config:   $CONFIG"
echo "  Device:   MPS (Apple Silicon)"
echo "  Steps:    1500"
echo "  LoRA:     rank 16"
echo "  Dataset:  $PROJECT_DIR/dataset/ (118 images)"
echo "  Output:   $TOOLKIT_DIR/output/ohwx_influencer/"
echo ""
echo "  Expected time: 2-4 hours on M4 Pro"
echo "  Sample images generated every 250 steps"
echo ""
echo "  Press Ctrl+C to stop training at any time."
echo "  (Checkpoints are saved every 250 steps)"
echo "============================================"
echo ""

PYTORCH_ENABLE_MPS_FALLBACK=1 PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0 python run.py "$CONFIG"

echo ""
echo "============================================"
echo "  Training complete!"
echo "============================================"
echo ""
echo "  Your LoRA file is in:"
echo "    $TOOLKIT_DIR/output/ohwx_influencer/"
echo ""
echo "  Next: set up ComfyUI for image generation:"
echo "    ./setup_comfyui.sh"
echo ""
