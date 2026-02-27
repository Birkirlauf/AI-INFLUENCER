# Run FLUX LoRA training on RunPod

Train the Zara LoRA on a cloud GPU in **~30–60 minutes** instead of days on a Mac. Cost is typically **$1–3** for a single run.

## 1. RunPod setup

1. Go to [runpod.io](https://www.runpod.io), create an account, add payment.
2. **Deploy a GPU pod**: choose a **PyTorch** template (or Ubuntu + CUDA).
   - **Recommended**: RTX 4090 (24GB) or A100 40GB. 24GB VRAM is enough with the RunPod config (quantization + bf16).
3. Note the **SSH** command or use the **Web Terminal** from the RunPod console.

## 2. Upload project and dataset

On the RunPod instance you need:

- This repo (so you have `config/` and `runpod/setup_and_train.sh`).
- Your **dataset** in a folder: 118 (or more) images plus `.txt` captions with the trigger word `ohwx`.

**Option A – Full repo + dataset**

- From your Mac, upload the whole project (including `dataset/`) to the pod, e.g. under `/workspace`:
  - `runpodctl send ./dataset` then on the pod: `runpodctl receive` and move to `/workspace/AI-INFLUENCER-ZARA/dataset`,  
  - or clone the repo on the pod and upload only the `dataset` folder into the repo.

**Option B – Dataset in /workspace**

- Put the dataset at `/workspace/dataset` (same structure: `1.png`, `1.txt`, …).
- Clone this repo on the pod (e.g. under `/workspace`) so you have the `runpod` script and config.

Example (on the pod):

```bash
cd /workspace
git clone https://github.com/YOUR_USER/AI-INFLUENCER-ZARA.git
# Then upload your dataset into /workspace/AI-INFLUENCER-ZARA/dataset
#   or into /workspace/dataset (script will use it)
```

## 3. HuggingFace

- Accept the **FLUX.1-dev** license: [black-forest-labs/FLUX.1-dev](https://huggingface.co/black-forest-labs/FLUX.1-dev) → “Agree and access repository”.
- Create a token at [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) (read access is enough).

## 4. Run training

SSH or open Web Terminal on the pod, then:

```bash
cd /workspace/AI-INFLUENCER-ZARA   # or wherever you put the repo
chmod +x runpod/setup_and_train.sh
./runpod/setup_and_train.sh
```

When prompted, run `huggingface-cli login` and paste your token. The script will:

- Clone **ostris/ai-toolkit** (CUDA version)
- Create a venv and install dependencies
- Use `config/ohwx_influencer_runpod.yaml` (CUDA, fp8 quant, adamw8bit, bf16)
- Train for 1500 steps (~30–60 min on A100/4090)

Output LoRA: `ai-toolkit/output/ohwx_influencer/*.safetensors`.

## 5. Download the LoRA

From your Mac (or use RunPod’s file browser):

```bash
runpodctl receive   # run the command it prints on the pod after runpodctl send ...
# or SCP:
scp -P <PORT> -r root@<POD_IP>:/workspace/AI-INFLUENCER-ZARA/ai-toolkit/output/ohwx_influencer ./
```

Then put the `.safetensors` file in ComfyUI’s `models/loras/` and use the trigger **ohwx woman** in prompts.

## Config used on RunPod

- **config/ohwx_influencer_runpod.yaml**: `device: cuda`, `quantize: true`, `optimizer: adamw8bit`, `dtype: bf16`, resolutions 512/768/1024. Dataset path is set automatically to `/workspace/dataset` or the project’s `dataset/` folder.

## Troubleshooting

- **Out of memory**: Use an A100 40GB or enable `low_vram: true` in the RunPod config.
- **“Cannot access gated repo”**: Accept the FLUX.1-dev license and log in with `huggingface-cli login`.
- **Import errors (e.g. AdamW, ViTHybrid)**: The script pins `transformers<5`; if you still see them, run:  
  `pip install 'transformers<5.0.0' 'setuptools<70'` in the toolkit venv.
