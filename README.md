# AI Influencer

Fully automated AI influencer pipeline running on a Mac Mini M4 Pro (24GB). Trains a custom FLUX LoRA, generates photorealistic images, writes captions, posts to Instagram/TikTok, engages with followers, and tracks analytics -- all autonomously.

## How It Works

```
ComfyUI + FLUX + LoRA  -->  Generate images of "Zara Soleil"
Claude API             -->  Write captions, reply to comments, plan strategy
OpenClaw               -->  Orchestrate everything on a schedule
Admin Panel            -->  Visual dashboard to review and approve content
Browser Automation     -->  Post to Instagram and TikTok
```

## Hardware

- Mac Mini M4 Pro, 24GB unified RAM
- macOS with Metal Performance Shaders (MPS)

## What's In This Repo

| Path | Description |
|------|-------------|
| `PLAN.md` | Complete 16-stage system plan |
| `dataset/` | 118 training images + captions (ready to use) |
| `config/ohwx_influencer.yaml` | ai-toolkit LoRA training config |
| `setup.sh` | Clones ai-toolkit, creates venv, installs deps |
| `train.sh` | Launches LoRA training |
| `setup_comfyui.sh` | Clones ComfyUI, creates venv, installs deps |
| `run_comfyui.sh` | Launches ComfyUI at localhost:8188 |

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/Birkirlauf/AI-INFLUENCER.git
cd AI-INFLUENCER

# 2. Run setup (clones ai-toolkit, installs PyTorch + deps)
./setup.sh

# 3. Log in to HuggingFace (needed for FLUX.1-dev)
cd ai-toolkit && source venv/bin/activate
huggingface-cli login
cd ..

# 4. Train the LoRA (~2-4 hours on M4 Pro)
./train.sh

# 5. Set up ComfyUI for image generation
./setup_comfyui.sh
./run_comfyui.sh
```

## Requirements

- macOS (Apple Silicon with MPS)
- Python 3.11+
- Git
- HuggingFace account (FLUX.1-dev license accepted)
- Anthropic API key (for Claude)

## Dataset

118 images of "Zara Soleil" with per-image `.txt` caption files using the trigger word `ohwx`. The dataset includes 20 original reference photos and 98 AI-generated variations across diverse scenes, lighting conditions, and poses.

## Training

The LoRA is trained with [ai-toolkit](https://github.com/ostris/ai-toolkit) on FLUX.1-dev:

- **Device:** MPS (Apple Silicon)
- **LoRA rank:** 16
- **Steps:** 1,500
- **Quantization:** fp8 (fits in 24GB)
- **Trigger word:** `ohwx woman`

## Full Plan

See [PLAN.md](PLAN.md) for the complete 16-stage system plan covering:

1. Mac Mini preparation
2. OpenClaw installation
3. Cloud model setup (Claude API)
4. FLUX LoRA training
5. ComfyUI image inference
6. Video generation
7. OpenClaw skills (10 automation skills)
8. Automation schedule
9. Error handling
10. Content variety system
11. TikTok video content
12. Remote access
13. Admin panel
14. Monetization
15. Scaling to multiple accounts
16. Costs and revenue projections
