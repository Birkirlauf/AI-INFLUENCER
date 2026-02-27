#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMFY_DIR="$PROJECT_DIR/ComfyUI"

if [ ! -d "$COMFY_DIR/venv" ]; then
    echo "ERROR: ComfyUI not set up yet. Run ./setup_comfyui.sh first."
    exit 1
fi

source "$COMFY_DIR/venv/bin/activate"
cd "$COMFY_DIR"

echo "============================================"
echo "  Launching ComfyUI"
echo "============================================"
echo ""
echo "  URL: http://127.0.0.1:8188"
echo "  Press Ctrl+C to stop"
echo ""
echo "  Quick workflow:"
echo "    Load FLUX checkpoint -> Apply LoRA -> Text prompt -> Generate"
echo ""
echo "  Example prompt:"
echo "    a photo of ohwx woman hiking in the Swiss Alps,"
echo "    golden hour, DSLR photograph"
echo "============================================"
echo ""

sleep 1 && open "http://127.0.0.1:8188" &

python main.py --force-fp16
