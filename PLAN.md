# AI Influencer - Complete System Plan

## System Overview

This document is the complete setup plan for running Zara Soleil, a fully automated AI influencer, on a Mac Mini M4 Pro using OpenClaw as the brain. The system generates content, posts it, engages with followers, and reports analytics -- all automatically, 24 hours a day, 7 days a week.

| Component | Purpose |
|-----------|---------|
| OpenClaw | Central brain -- orchestrates everything |
| Claude API (Haiku / Sonnet / Opus) | All text tasks -- captions, comments, strategy, quality checks |
| ComfyUI + Flux | Image generation engine |
| Zara LoRA | Locks Zara's face and look permanently |
| Real-ESRGAN | Upscales all images to high resolution |
| Browser Automation | Posts to Instagram and TikTok automatically |
| Telegram Bot | Remote control from your phone |
| Admin Panel (localhost:3000) | Visual dashboard -- content queue, gallery, analytics, system status |

## Architecture

```
Mac Mini M4 Pro 24GB — Running 24/7
│
├── OpenClaw Gateway        :18789   (brain + orchestration)
│   ├── Telegram Bot                 (your phone control)
│   ├── Model Router                 (sends tasks to right AI)
│   ├── Content Scheduler            (cron jobs 6am/12pm/6pm)
│   ├── Quality Checker              (Claude reviews before post)
│   ├── Engagement Bot               (20 comments/day)
│   └── Analytics Reporter           (daily Telegram report)
│
├── Admin Panel             :3000    (visual control center for OpenClaw)
│   ├── Content Queue                (approve/reject before posting)
│   ├── Image Gallery                (browse all generated images)
│   ├── Post History                 (see what was posted + engagement)
│   ├── Analytics Dashboard          (follower growth, engagement charts)
│   └── System Status                (ComfyUI, API, disk health)
│
├── Claude API (cloud)               (all text/reasoning tasks)
│   ├── Haiku                        (comments, DMs, hashtags — fast + cheap)
│   ├── Sonnet                       (captions, quality checks, content review)
│   └── Opus                         (strategy, skill building, brand outreach)
│
├── ComfyUI                 :8188    (image generation — uses full 24GB)
│   ├── Flux 1 Dev                   (base image model)
│   ├── Zara LoRA                    (face + look lock)
│   └── Real-ESRGAN                  (2x upscaling)
│
└── Browser Automation               (Instagram + TikTok posting)
```

All text/reasoning runs in the cloud via the Anthropic API. The full 24GB of unified RAM is dedicated to ComfyUI + FLUX for image generation, which is the most memory-hungry workload.

---

## Hardware

- Mac Mini M4 Pro, 24GB unified RAM
- macOS with Metal Performance Shaders (MPS)

## Dataset (DONE)

- **118 images** in `/dataset/` (20 original + 98 generated)
- Per-image `.txt` caption files with trigger word `ohwx`
- `metadata.jsonl` for tool compatibility
- All images: clean PNG, RGB, no metadata

---

## Stage 1: Mac Mini Preparation

### 1.1 Update macOS

Before installing anything, make sure macOS is fully updated. Go to System Settings > General > Software Update and install all available updates.

### 1.2 Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 1.3 Install Node 22

```bash
brew install nvm
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zprofile
echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"' >> ~/.zprofile
source ~/.zprofile
nvm install 22
nvm use 22
nvm alias default 22
node --version   # Should show v22.x.x
```

### 1.4 Install Core Dependencies

```bash
brew install python@3.11
brew install git
brew install wget
```

### 1.5 Create Folder Structure

```bash
mkdir -p ~/zara/{generated,upscaled,posted,videos,training,loras,captions,analytics}
mkdir -p ~/openclaw/{skills,personas,logs,config}
```

---

## Stage 2: Install OpenClaw

### 2.1 Install

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
source ~/.zprofile
```

### 2.2 Run Onboarding Wizard

```bash
openclaw onboard --install-daemon
```

During onboarding you will be asked for:
- Your Anthropic API key -- get from console.anthropic.com
- Which channel to connect -- choose Telegram
- Your Telegram bot token -- see step 2.3 below

### 2.3 Create Telegram Bot

1. Open Telegram on your phone
2. Search for @BotFather in Telegram
3. Send the message: `/newbot`
4. Name it something private like ZaraManagerBot
5. Copy the token it gives you
6. Paste the token into the OpenClaw onboarding prompt

### 2.4 Verify OpenClaw is Running

```bash
openclaw gateway status
openclaw dashboard
# Opens browser at http://127.0.0.1:18789
```

### 2.5 Enable Auto-Start on Boot

```bash
openclaw gateway install-service
```

### 2.6 Create Zara's Persona File

```bash
cat > ~/.openclaw/personas/zara.md << 'EOF'
# Zara Soleil

## Identity
25-year-old luxury lifestyle influencer.
Based between Miami, Paris, and Tulum.
Fashion, travel, fitness, golden aesthetics.
Warm, confident, playful, elegant.

## Voice
- Casual but aspirational
- Light humor, never try-hard
- Ends captions with engaging questions
- Never sounds like a brand or robot
- French/Spanish words occasionally

## Rules
- Never mention being AI
- Always stay in character
- Reply to comments within 2 hours
- Captions under 150 words
- Always include a call to action
EOF
```

---

## Stage 3: Cloud Model Setup (Claude API)

All text and reasoning tasks run via the Anthropic Claude API. This keeps the Mac Mini's 24GB RAM entirely free for image generation, avoids downloading 40GB+ of local model weights, and gives you access to the best models available.

### 3.1 Get Anthropic API Key

1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Create an account and add billing (pay-as-you-go)
3. Create an API key under Settings > API Keys
4. Save the key -- you'll need it for OpenClaw onboarding

### 3.2 Model Routing Config

Three tiers, each matched to the right task by cost and speed:

```yaml
# ~/.openclaw/config/models.yaml
models:
  fast:
    provider: anthropic
    model: claude-haiku
    use_for: [comment_replies, dm_responses, hashtag_generation, spam_detection]
    notes: "$0.25/M input — use for all high-volume, simple tasks"

  creative:
    provider: anthropic
    model: claude-sonnet
    use_for: [caption_writing, content_planning, story_ideas, quality_checks, brand_voice_audit]
    notes: "$3/M input — main workhorse for content creation"

  strategy:
    provider: anthropic
    model: claude-opus
    use_for: [weekly_planning, growth_strategy, skill_building, brand_outreach, complex_decisions]
    notes: "$15/M input — use sparingly for high-value strategic tasks"
```

### 3.3 Estimated API Cost Breakdown

| Task | Model | Frequency | Est. Monthly Cost |
|------|-------|-----------|-------------------|
| Comment replies (10/check, 6x/day) | Haiku | ~1,800/month | €1-2 |
| DM responses | Haiku | ~300/month | <€1 |
| Hashtag generation | Haiku | ~90/month | <€1 |
| Caption writing (3/day) | Sonnet | ~90/month | €2-4 |
| Quality checks (3/day) | Sonnet | ~90/month | €2-4 |
| Content planning (daily) | Sonnet | ~30/month | €1-2 |
| Weekly strategy | Opus | ~4/month | €1-2 |
| Brand outreach emails | Opus | ~5-10/month | €1-2 |
| **TOTAL** | | | **€8-18/month** |

### 3.4 Test the API

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-20250514",
    "max_tokens": 256,
    "messages": [{"role": "user", "content": "Write a short Instagram caption for a sunset rooftop photo in Zara Soleil'\''s voice — casual, aspirational, with a question at the end."}]
  }'
```

---

## Stage 4: FLUX LoRA Training (Image Generation)

### 4.1 Install Dependencies

All automated via `./setup.sh`, but for reference:

```bash
cd ~/Desktop/Personal/Ai\ influencer
git clone https://github.com/ostris/ai-toolkit.git
cd ai-toolkit
git submodule update --init --recursive

python3.11 -m venv venv
source venv/bin/activate

pip install torch torchvision torchaudio
pip install -r requirements.txt
```

### 4.2 Download Base Model

- Model: **FLUX.1-dev** from HuggingFace
- Requires HuggingFace account + accepting the FLUX license
- Login: `huggingface-cli login`
- Model ID: `black-forest-labs/FLUX.1-dev`

### 4.3 Training Config

The config is in `config/ohwx_influencer.yaml` (created by setup). Key settings:

```yaml
job: extension
config:
  name: ohwx_influencer
  process:
    - type: sd_trainer
      training_folder: output/ohwx_influencer
      device: mps
      network:
        type: lora
        linear: 16
        linear_alpha: 16
      save:
        dtype: float16
        save_every: 250
        max_step_saves_to_keep: 4
      datasets:
        - folder_path: /Users/birkirlauf/Desktop/Personal/Ai influencer/dataset
          caption_ext: txt
          caption_dropout_rate: 0.05
          resolution: [512, 768, 1024]
          batch_size: 1
      train:
        batch_size: 1
        steps: 1500
        gradient_accumulation_steps: 1
        train_unet: true
        train_text_encoder: false
        gradient_checkpointing: true
        noise_scheduler: flowmatch
        optimizer: adamw8bit
        lr: 4e-4
        ema_config:
          use_ema: true
          ema_decay: 0.99
        dtype: bf16
      model:
        name_or_path: black-forest-labs/FLUX.1-dev
        quantize: true  # fp8 quantization to fit in 24GB
      sample:
        sampler: flowmatch
        sample_every: 250
        width: 1024
        height: 1024
        prompts:
          - "a photo of ohwx woman standing in a coffee shop, dark curly hair, olive skin, freckles, gold earrings"
          - "a photo of ohwx woman at a beach sunset, dark curly hair, olive skin, freckles, gold necklace"
```

### 4.4 Run Training

```bash
./train.sh
```

- **Expected time:** 2-4 hours on M4 Pro
- **Output:** LoRA file (~100-200MB) in `output/ohwx_influencer/`
- **Monitor:** Sample images generated every 250 steps to check progress
- **Sweet spot:** Usually around 1000-1500 steps for 118 images

### 4.5 Expected Result

A `.safetensors` LoRA file that, when loaded with FLUX.1-dev, generates photorealistic images of your character from any text prompt.

---

## Stage 5: ComfyUI (Image Inference)

### 5.1 Install ComfyUI

All automated via `./setup_comfyui.sh`, but for reference:

```bash
cd ~/Desktop/Personal/Ai\ influencer
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
python3.11 -m venv venv
source venv/bin/activate
pip install torch torchvision torchaudio
pip install -r requirements.txt
```

### 5.2 Install ComfyUI Manager and Custom Nodes

```bash
cd ~/ComfyUI/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager
git clone https://github.com/Fannovel16/comfyui_controlnet_aux
git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus
```

### 5.3 Download Flux Model Files

```bash
export HF_TOKEN=your_token_here

# Flux 1 Dev model
cd ~/ComfyUI/models/checkpoints
wget --header="Authorization: Bearer $HF_TOKEN" \
  https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors

# Text encoders
cd ~/ComfyUI/models/text_encoders
wget https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors
wget https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors

# VAE
cd ~/ComfyUI/models/vae
wget --header="Authorization: Bearer $HF_TOKEN" \
  https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/ae.safetensors

# Real-ESRGAN upscaler
cd ~/ComfyUI/models/upscale_models
wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesr-general-x4v3.pth
```

### 5.4 Set Up Models Directory

```
ComfyUI/
  models/
    checkpoints/    <- Put FLUX.1-dev here (or symlink)
    loras/          <- Put your trained LoRA .safetensors here
    clip/           <- FLUX text encoders
    vae/            <- FLUX VAE
```

### 5.5 Launch & Use

```bash
./run_comfyui.sh
```

- Opens at `http://127.0.0.1:8188`
- Build a workflow: Load FLUX checkpoint -> Apply LoRA -> Text prompt -> Generate
- Prompt example: `a photo of ohwx woman at a beach party, wearing a red dress, sunset lighting`

### 5.6 Set ComfyUI to Auto-Start (Production)

```bash
cat > ~/Library/LaunchAgents/com.comfyui.server.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.comfyui.server</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/python3.11</string>
    <string>/Users/birkirlauf/ComfyUI/main.py</string>
    <string>--listen</string><string>127.0.0.1</string>
    <string>--port</string><string>8188</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict></plist>
EOF
launchctl load ~/Library/LaunchAgents/com.comfyui.server.plist
```

---

## Stage 6: Video Generation

### Option A: AnimateDiff in ComfyUI (Easiest, local)

- Install AnimateDiff custom nodes in ComfyUI
- Use your LoRA-generated images as keyframes
- Generates 2-4 second animated clips
- Quality: Good for social media loops/reels
- RAM: Fits in 24GB with SDXL (not FLUX)

### Option B: CogVideoX-2B (Better quality, local)

```bash
pip install diffusers transformers accelerate
```

- 2B parameter model, fits in 24GB
- Image-to-video: feed it a LoRA-generated image, get a 6-second clip
- Quality: Decent, good motion coherence

### Option C: Wan2.1 (Best local quality, tight fit)

- 14B model, needs int4 quantization to fit 24GB
- Highest quality local video generation available
- Slower (~5-10 min per 4-second clip on M4 Pro)
- Install via ComfyUI custom nodes or standalone

### Option D: Kling API (Best quality overall, recommended for TikTok)

- Upload LoRA-generated images -> get high-quality video
- Cost: $0.10-0.50 per video clip
- Quality: Significantly better than any local option on 24GB

Tell OpenClaw to build a `generate_video` skill that:
1. Takes one of Zara's generated images as input
2. Calls the Kling API with the image + motion prompt
3. Motion prompts to rotate through:
   - Gentle hair movement in breeze
   - Slow camera pullback
   - Subject turns head slowly and smiles
   - Walking forward on beach or street
4. Downloads completed 5-second video
5. Saves to `~/zara/videos/` with timestamp
6. Calls `post_tiktok` automatically

Run this workflow 3 times per week minimum.

**Recommended approach:** Use Option A or B for quick local clips, Option D for high-quality content.

---

## Stage 7: OpenClaw Skills (Build via Telegram)

Build these 10 skills by telling OpenClaw in Telegram:

### Skill 1: generate_image

Generate a new Zara image using ComfyUI at `localhost:8188`:
1. Pick a random scene from the content variety list
2. Build the prompt using Zara's trigger word `ohwx woman` plus scene details
3. Send the prompt to ComfyUI API with FLUX + LoRA settings
4. Wait for generation to complete
5. Save image to `~/zara/generated/` with timestamp name
6. Run Real-ESRGAN upscaling on the image
7. Save upscaled version to `~/zara/upscaled/`
8. Insert a row into the admin panel `images` table with filename, prompt, and category

### Skill 2: write_caption

1. Look at the generated image prompt to understand the scene
2. Use Claude Sonnet to write an Instagram caption in Zara's voice
3. Caption must be under 150 words, include a call to action
4. Use Claude Haiku to generate 5-10 targeted hashtags (mix of popular and niche)
5. Save caption to `~/zara/captions/`
6. Insert a row into the admin panel `queue` table with image_id, caption, hashtags, and status `pending_review`

### Skill 3: post_instagram

1. Open Instagram via browser automation
2. Upload the upscaled image from `~/zara/upscaled/`
3. Paste the caption and hashtags
4. Post it
5. Move image to `~/zara/posted/`
6. Insert a row into the admin panel `posts` table with image_id, platform, caption, and posted_at
7. Update the corresponding `queue` entry status to `posted`
8. Send confirmation to Telegram with a preview

### Skill 4: post_tiktok

Same flow as Instagram but for TikTok. Use video if available, otherwise create a slideshow from the image with a trending sound.

### Skill 5: engage_comments

Every 2 hours:
1. Check latest comments on recent posts
2. Use Claude Haiku to write replies in Zara's voice
3. Reply to up to 10 comments per check
4. Never reply to spam/bots

### Skill 6: engagement_run

Once daily at 9 PM:
1. Find 20 accounts in similar niches
2. Like 3 recent posts on each
3. Leave a genuine comment on 10 of them
4. All comments must sound natural, never generic

### Skill 7: schedule_content

Every night at 11 PM:
1. Use Claude Sonnet to plan tomorrow's 3 posts
2. Check content variety tracker -- avoid recent repeats
3. Queue the plans with specific times: 6am, 12pm, 6pm (with +-15 min variance)

### Skill 8: quality_check

Before every post:
1. Send the image + caption to Claude Sonnet
2. Ask: Is this consistent with Zara's brand? Any issues?
3. If Claude flags issues, regenerate or rewrite
4. Only post if quality check passes

### Skill 9: daily_analytics

Every night at 10 PM:
1. Collect follower count, likes, comments, reach from today
2. Insert a row into the admin panel `analytics` table with date, followers, engagement data
3. Update likes/comments/reach on today's entries in the `posts` table
4. Compare to yesterday and weekly average
5. Identify best and worst performing post
6. Send report to Telegram

### Skill 10: weekly_strategy

Every Sunday at 12 PM:
1. Use Claude Opus to analyze the week's performance and make strategic recommendations
2. Adjust content mix based on what performed best
3. Send strategy report to Telegram

---

## Stage 8: Automation Schedule

### Two-Week Warmup (Manual/Semi-Auto)

Before enabling full automation, manually warm up the accounts:
- Week 1: 1 post per day, 10 likes, 5 comments
- Week 2: 2 posts per day, 20 likes, 10 comments
- This prevents Instagram from flagging the account as a bot

### Daily Automated Schedule

| Time | Action |
|------|--------|
| 5:45 AM | Generate morning content (image + caption + quality check) |
| 6:00 AM (+/-15min) | Post morning content |
| 6:15 AM | Telegram confirmation sent |
| 10:00 AM | Respond to overnight comments |
| 11:45 AM | Generate and prepare midday content |
| 12:00 PM (+/-15min) | Post midday content |
| 12:15 PM | Telegram confirmation sent |
| 6:00 PM (+/-15min) | Generate and post evening content |
| 6:15 PM | Telegram confirmation sent |
| 8:00 PM | Respond to daytime comments |
| 9:00 PM | Engagement run -- 20 comments + 30 likes |
| 10:00 PM | Daily analytics report sent to Telegram |
| 11:00 PM | Content planning for tomorrow using Claude Sonnet |
| Sunday 12:00 PM | Weekly hashtag refresh |
| 1st of month | Monthly strategy review via Claude Opus |

---

## Stage 9: Error Handling and Recovery

Tell OpenClaw in Telegram to build a system health monitor:

**Every 30 minutes check:**
- ComfyUI is responding at `localhost:8188`
- Admin panel is responding at `localhost:3000`
- Anthropic API is reachable (test ping)
- OpenClaw gateway is running
- Disk space is above 20GB free

**If any service is down:**
- Try to restart it automatically
- If restart fails, send emergency alert to Telegram
- Pause all scheduled posting until resolved

**If a post fails:**
- Log the error with full details
- Retry once after 10 minutes
- If retry fails, send alert and save content for manual posting

**If image generation fails:**
- Try regenerating with simplified prompt
- If still fails, use a backup image from `~/zara/generated/`

**Daily:** Send a good morning message at 7am summarizing overnight system status and any issues.

---

## Stage 10: Content Variety System

Tell OpenClaw to track and rotate content so the feed never looks repetitive:

1. Keep a log of the last 30 posts and their categories
2. Before generating each post, check what categories were used in the last 7 days
3. Ensure this rotation across every 9 posts (one Instagram grid row):
   - 3x fashion/outfit posts
   - 2x travel/location posts
   - 2x lifestyle/daily life posts
   - 1x fitness/wellness post
   - 1x golden hour/aesthetic post
4. Rotate posting times so they vary naturally
5. Track which scene prompts were used to avoid repeats

### Content Variety Scene Prompts

| Category | Example Scenes |
|----------|---------------|
| Morning Routine | Coffee at home, getting ready, morning yoga, farmers market |
| Outfit of Day | Street style walking, mirror selfie, cafe sitting, shopping |
| Travel | Mykonos streets, Tulum cenote, Amalfi coast, Paris cafe |
| Beach/Pool | Yacht deck, pool lounge, shoreline, beach bar |
| Fitness | Gym training, outdoor run, yoga on terrace, post-workout |
| Golden Hour | Rooftop sunset, balcony glow, outdoor dinner, driving |
| City Life | Restaurant arrival, nightlife, art gallery, market |
| Cozy Indoor | Reading at home, cooking, sofa relaxing, study session |

---

## Stage 11: Video Content for TikTok

TikTok without video content barely grows. Options:

**Option 1 -- Kling API (Recommended)**

See Stage 6 Option D above.

**Option 2 -- Local Wan2.1 (Free)**

Install Wan2.1 via ComfyUI Manager, then tell OpenClaw to build a video generation skill using Wan2.1 in ComfyUI to animate Zara images into 3-5 second clips.

---

## Stage 12: Remote Access Setup

### 12.1 Enable SSH

```bash
# System Settings > General > Sharing > Remote Login > Enable
ipconfig getifaddr en0
# From any computer on same network:
ssh username@your-mac-mini-ip
```

### 12.2 Enable Screen Sharing

System Settings > General > Sharing > Screen Sharing > Enable.

### 12.3 Remote Access Over Internet (Tailscale)

```bash
brew install tailscale
tailscale up
# Create free account at tailscale.com
# Install Tailscale app on your phone
# Now SSH and screen share from anywhere
```

### 12.4 Backup System

Tell OpenClaw to build a backup skill that runs every Sunday at 2am:
1. Back up `~/zara/loras/` to external drive or cloud
2. Back up `~/.openclaw/` config and personas
3. Archive last 30 days of generated content
4. Send backup confirmation to Telegram

---

## Stage 13: Admin Panel

The admin panel is OpenClaw's visual frontend. Everything OpenClaw manages -- content queue, generated images, post history, analytics, system health -- is viewable and controllable here. It runs as a lightweight web app on the Mac Mini, accessible at `http://localhost:3000` (and remotely via Tailscale).

### 13.1 Tech Stack

- **Backend:** FastAPI (Python 3.11, already installed)
- **Database:** SQLite (single file at `~/zara/admin/zara.db`)
- **Frontend:** Static HTML + vanilla JS + Tailwind CSS (no build step)
- **No auth required** -- local only, secured by Tailscale for remote access

### 13.2 Install

Tell OpenClaw via Telegram:

> Build an admin panel for Zara using FastAPI and SQLite. It should run at localhost:3000 and serve a static HTML frontend with Tailwind CSS. Create the database schema, API endpoints, and frontend pages described below. Save the project to ~/zara/admin/.

### 13.3 Database Schema

```sql
CREATE TABLE images (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filename TEXT NOT NULL,
    prompt TEXT,
    category TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'generated'  -- generated, approved, rejected, posted
);

CREATE TABLE queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    image_id INTEGER REFERENCES images(id),
    caption TEXT,
    hashtags TEXT,
    platform TEXT,           -- instagram, tiktok
    scheduled_for DATETIME,
    status TEXT DEFAULT 'pending_review',  -- pending_review, approved, posted, failed
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    image_id INTEGER REFERENCES images(id),
    platform TEXT,
    caption TEXT,
    hashtags TEXT,
    posted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    likes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    reach INTEGER DEFAULT 0
);

CREATE TABLE analytics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date DATE UNIQUE,
    followers INTEGER,
    posts_count INTEGER,
    total_likes INTEGER,
    total_comments INTEGER,
    engagement_rate REAL
);
```

### 13.4 Pages

**Dashboard (home page)**
- System status cards: ComfyUI up/down, API health, disk space, last post time
- Today's schedule with countdown to next post
- Quick stats: followers, today's engagement, weekly trend

**Content Queue**
- Cards showing upcoming posts: image thumbnail + caption + scheduled time
- Approve / reject / edit / reorder buttons
- "Generate Now" button to trigger on-demand image + caption via OpenClaw
- Status badges: pending review, approved, posted, failed

**Image Gallery**
- Grid of all images from `~/zara/generated/` and `~/zara/upscaled/`
- Filter by date, category, status (unused / posted / rejected)
- Click to view full-size image + the prompt that generated it
- Bulk select to delete bad generations

**Post History**
- Timeline of everything posted to Instagram + TikTok
- Each entry shows: image, caption, time, platform, engagement (likes, comments)
- Sort by engagement to find best/worst performers

**Analytics**
- Follower growth chart (daily)
- Engagement rate over time
- Best performing content categories
- Posting time vs engagement heatmap

**Settings**
- View/edit Zara's persona file
- Adjust posting schedule and time slots
- Toggle auto-post on/off (manual approval mode vs fully automatic)
- View API key status and usage

### 13.5 OpenClaw Integration

The admin panel shares a SQLite database with OpenClaw's skills. The data flows in both directions:

**OpenClaw writes to the DB:**
- `generate_image` skill inserts into the `images` table after each generation
- `write_caption` skill inserts into the `queue` table with status `pending_review`
- `post_instagram` / `post_tiktok` skills insert into the `posts` table
- `daily_analytics` skill inserts into the `analytics` table

**The panel triggers OpenClaw:**
- Clicking "Approve" on a queued post tells OpenClaw to run `post_instagram` or `post_tiktok`
- Clicking "Generate Now" tells OpenClaw to run `generate_image` + `write_caption`
- Clicking "Reject" marks the image as rejected and removes it from the queue

Tell OpenClaw via Telegram:

> Update all content skills to log their results to the SQLite database at ~/zara/admin/zara.db. When generate_image completes, insert the image details into the images table. When write_caption completes, insert into the queue table. When post_instagram or post_tiktok completes, insert into the posts table. When daily_analytics runs, insert into the analytics table.

### 13.6 API Endpoints

```
GET  /api/dashboard          -- status cards + today's schedule
GET  /api/queue              -- content queue with filters
POST /api/queue/:id/approve  -- approve a queued post (triggers OpenClaw posting skill)
POST /api/queue/:id/reject   -- reject and remove from queue
POST /api/generate           -- trigger on-demand generation via OpenClaw
GET  /api/gallery            -- paginated image list with filters
GET  /api/posts              -- post history with engagement data
GET  /api/analytics          -- chart data for a date range
GET  /api/status             -- system health (ComfyUI, API, disk)
POST /api/settings           -- update persona, schedule, toggles
```

### 13.7 Set Admin Panel to Auto-Start

```bash
cat > ~/Library/LaunchAgents/com.zara.admin.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.zara.admin</string>
  <key>ProgramArguments</key>
  <array>
    <string>/Users/birkirlauf/zara/admin/venv/bin/uvicorn</string>
    <string>app:app</string>
    <string>--host</string><string>127.0.0.1</string>
    <string>--port</string><string>3000</string>
  </array>
  <key>WorkingDirectory</key><string>/Users/birkirlauf/zara/admin</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict></plist>
EOF
launchctl load ~/Library/LaunchAgents/com.zara.admin.plist
```

After setup, open `http://localhost:3000` in your browser (or via Tailscale from your phone).

---

## Stage 14: Monetization Setup

### 14.1 Affiliate Links

Set up accounts:
- **Amazon Associates** -- fashion and beauty products
- **LTK (LikeToKnowIt)** -- dedicated fashion influencer platform
- **RewardStyle** -- premium fashion affiliate network
- **Booking.com affiliate** -- travel content

Tell OpenClaw to include "link in bio" CTAs in outfit posts and booking affiliate references in travel captions. Track clicks via UTM parameters.

### 14.2 Brand Outreach Automation

Build a brand outreach skill that runs at 500, 1k, 5k, 10k followers:
1. Research 20 brands in Zara's niche that work with micro-influencers
2. Use Claude Opus to write personalised pitch emails
3. Track all outreach in `~/zara/analytics/brand_outreach.log`
4. Follow up automatically after 7 days if no response
5. Alert on Telegram with any positive responses

### 14.3 Media Kit Generation

Build a `generate_media_kit` skill that:
1. Pulls latest follower count and engagement rate
2. Assembles Zara's best performing content examples
3. Uses Claude Sonnet to write compelling brand pitch copy
4. Generates a PDF media kit
5. Saves to `~/zara/media_kit_[date].pdf`

---

## Stage 15: Scaling to Multiple Accounts

Once Zara is profitable and running stable for 2+ months, duplicate the entire system for a second influencer. Since text tasks run in the cloud, scaling accounts only costs more API usage -- the Mac Mini just needs to generate images sequentially.

### Second Influencer -- Sofia Reyes

| Attribute | Detail |
|-----------|--------|
| Name | Sofia Reyes |
| Niche | NYC fashion and street style |
| Look | Dark skin, Afro-Latina, natural hair, bold fashion |
| Why profitable | Underserved niche with high brand demand for diversity |
| LoRA trigger | `sofiar` |
| Accounts | @sofiareyesnyc |

```bash
mkdir -p ~/sofia/{generated,upscaled,posted,videos,training,loras,captions,analytics}
cp ~/.openclaw/personas/zara.md ~/.openclaw/personas/sofia.md
# Edit sofia.md with Sofia's new details
```

### Resource Usage with Multiple Accounts

Since all text/reasoning runs in the cloud, RAM is only used for image generation (one at a time). Scaling accounts adds API cost, not RAM pressure.

| Accounts | RAM Usage | Generation Time | API Cost | Status |
|----------|-----------|-----------------|----------|--------|
| 1 account (Zara) | ~16GB peak | 45-60 sec/image | €8-18/month | Comfortable |
| 2 accounts | ~16GB peak | Queue-based, ~2x time | €16-36/month | Good |
| 3 accounts | ~16GB peak | Queue-based, ~3x time | €24-54/month | Good |
| 4+ accounts | ~16GB peak | Queue-based, may need scheduling | €32-72/month | Near limit |

---

## Stage 16: Costs and Revenue Projections

### Monthly Running Costs

| Item | Detail | Cost | Notes |
|------|--------|------|-------|
| Claude API | All text tasks (Haiku + Sonnet + Opus) | €8-18 | See Stage 3 breakdown |
| Electricity | Mac Mini 24/7 | €5-10 | Very energy efficient |
| Kling API | Video generation | €10-20 | Optional, skip early on |
| Replicate | LoRA retraining | €0-5 | Only when needed |
| Domain/email | hello@zarasoleil.com | €2-5 | Professional collabs |
| **TOTAL** | | **€25-58/month** | |

### Revenue Projections -- Zara Soleil

| Timeframe | Followers | Monthly Revenue | Primary Source |
|-----------|-----------|-----------------|----------------|
| Month 1-3 | 0 -- 5k | €0 -- €200 | Building foundation |
| Month 4-6 | 5k -- 20k | €200 -- €1,500 | Affiliate links |
| Month 7-12 | 20k -- 50k | €1,500 -- €5,000 | Brand deals begin |
| Year 2 | 50k -- 150k | €5,000 -- €20,000 | Premium brand deals |
| Year 3+ | 150k+ | €20,000 -- €60,000+ | Multiple income streams |

---

## Quick Reference

| Task | Tool | Time | Quality |
|------|------|------|---------|
| LoRA training | ai-toolkit | 2-4 hrs | - |
| Image generation | ComfyUI + FLUX + LoRA | 10-30 sec/img | Excellent |
| Video (local) | AnimateDiff / CogVideoX | 2-10 min/clip | Good |
| Video (cloud) | Runway / Kling API | 30-60 sec/clip | Excellent |

## Trigger Word

Use `ohwx woman` in all prompts to activate your trained character.
Example: `a photo of ohwx woman hiking in the Swiss Alps, golden hour, DSLR photograph`

---

## File Structure

```
Ai influencer/
├── PLAN.md                  <- This file
├── setup.sh                 <- Phase 1 setup (run first)
├── train.sh                 <- Start LoRA training
├── setup_comfyui.sh         <- Phase 2 setup
├── run_comfyui.sh           <- Launch ComfyUI
├── config/
│   └── ohwx_influencer.yaml <- Training config
├── dataset/                 <- Training data (118 images + captions)
│   ├── 1.png ... 120.png
│   ├── 1.txt ... 120.txt
│   └── metadata.jsonl
├── ai-toolkit/              <- LoRA training tool (cloned by setup.sh)
│   └── output/
│       └── ohwx_influencer/ <- Trained LoRA files
├── ComfyUI/                 <- Image/video generation UI (cloned by setup_comfyui.sh)
│   └── models/
│       ├── checkpoints/     <- FLUX.1-dev
│       └── loras/           <- Your trained LoRA
└── ~/zara/admin/            <- Admin panel (FastAPI + static frontend)
    ├── app.py               <- FastAPI backend
    ├── static/              <- HTML + JS + Tailwind frontend
    └── zara.db              <- SQLite database (shared with OpenClaw)
```

---

## Setup Checklist

| Task | Status |
|------|--------|
| macOS updated to latest | ☐ |
| Homebrew installed | ☐ |
| Node 22 installed via NVM | ☐ |
| Folder structure created | ☐ |
| OpenClaw installed | ☐ |
| OpenClaw onboarding completed | ☐ |
| Telegram bot created and connected | ☐ |
| OpenClaw set to auto-start | ☐ |
| Zara persona file created | ☐ |
| Anthropic API key created + billing set up | ☐ |
| Model routing config created | ☐ |
| Claude API tested | ☐ |
| ComfyUI installed | ☐ |
| Hugging Face token obtained | ☐ |
| Flux 1 Dev downloaded | ☐ |
| Real-ESRGAN downloaded | ☐ |
| ComfyUI set to auto-start | ☐ |
| 118 training images generated | ☐ |
| LoRA trained | ☐ |
| LoRA tested and approved | ☐ |
| All 10 skills built via Telegram | ☐ |
| Admin panel installed and running | ☐ |
| Admin panel auto-start configured | ☐ |
| Skills updated to log to admin panel DB | ☐ |
| Instagram account created | ☐ |
| TikTok account created | ☐ |
| Two week warmup completed | ☐ |
| Session cookies saved | ☐ |
| Error handling configured | ☐ |
| Backup system running | ☐ |
| Remote access via Tailscale | ☐ |
| First automated post confirmed | ☐ |

---

## Setup Timeline

| Day | Tasks |
|-----|-------|
| Day 1 Morning | Mac Mini prep, Homebrew, Node, OpenClaw install, Telegram bot |
| Day 1 Afternoon | Anthropic API setup, model routing config, test Claude API |
| Day 2 Morning | ComfyUI install, Flux download (takes several hours) |
| Day 2 Afternoon | Run `./setup.sh` and `./train.sh` for LoRA training |
| Day 3 | Test LoRA, build all 10 skills via Telegram, set up admin panel |
| Day 4-5 | Create social accounts, begin manual warmup posting |
| Day 6-14 | Continue warmup -- posting daily manually or semi-auto |
| Day 15 | Enable full automation -- system goes live |
| Week 3+ | Monitor, optimise, and start planning second account |

System fully operational in approximately 2 weeks.
