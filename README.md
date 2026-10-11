# Gemma 1B Quantized on OpenShift Local (CRC) - PVC Architecture

This project implements the **PersistentVolumeClaim (PVC)** strategy for running `RedHatAI/gemma-3-1b-it-quantized.w8a8` on OpenShift Local (CRC). 

## Why PVC over Baked Image?
- **No Local Image Building:** Avoids local `podman build` issues on Windows/WSL2.
- **No CRC Registry / DNS / TLS Hurdles:** Bypasses registry route exposure, CA cert installation, and Podman VM DNS mapping.
- **Standard Base Image:** Uses official `vllm/vllm-openai-cpu:v0.31.0` (multi-arch, amd64 supported) pulled directly by OpenShift. The tag is pinned in `k8s/02-gemma-pvc-app.yaml`; verify tags exist at https://hub.docker.com/r/vllm/vllm-openai-cpu/tags before bumping.
- **Persistent Caching:** Downloads the 1B weights to the PVC on first run; subsequent restarts load directly from disk in seconds.

## Memory Configuration (Learned from CRC Runbook)
- **Container Memory Limit:** `8Gi` (Requests: `6Gi`)
- **KV Cache Space:** `VLLM_CPU_KVCACHE_SPACE="1"` (1 GiB allocated to vLLM KV cache)
- **Shared Memory (`/dev/shm`):** `2Gi` Memory-backed `emptyDir`
- **Max Model Context:** `--max-model-len 512`, `--max-num-seqs 1`
- **CPU Threads:** `OMP_NUM_THREADS="4"`

## Prerequisites
- OpenShift Local (CRC) running (`crc status`), with roughly 12+ GiB RAM and 8 CPUs assigned to the VM (`crc config set memory 16384`, `crc config set cpus 8`, then restart).
- Windows PowerShell, run from the repo root (scripts use relative `k8s/` paths).
- A Hugging Face token with access to the model. Copy `.env.example` to `.env` and set `HF_TOKEN`, or run `huggingface-cli login`. `.env` is git-ignored.
- Cluster-admin login (needed for the `anyuid` SCC grant).

## Quick Start (Windows PowerShell)

1. **Initialize `oc` and log in** (get the password via `crc console --credentials`):
   ```powershell
   & crc oc-env | Invoke-Expression
   oc login -u kubeadmin https://api.crc.testing:6443
   ```

2. **Load your Hugging Face Token:**
   ```powershell
   . .\scripts\load-hf-token.ps1
   ```

3. **Setup Namespace & K8s Secret:**
   ```powershell
   .\scripts\01-setup-namespace-secret.ps1
   ```

4. **Deploy PVC & vLLM Application:**
   ```powershell
   .\scripts\02-deploy-pvc-app.ps1
   ```

5. **Test Model Inference:**
   ```powershell
   .\scripts\03-test-inference.ps1
   ```

6. **Run Diagnostics (If needed):**
   ```powershell
   .\scripts\04-diagnostics.ps1
   ```

## Troubleshooting
- `ImagePullBackOff`: confirm the image tag in `k8s/02-gemma-pvc-app.yaml` exists on Docker Hub and the CRC VM has internet access.
- Pod `Pending`/`OOMKilled`: increase CRC memory (see Prerequisites) or check `oc describe pod -n vllm-gemma-3-x86`.
- Startup is slow on first run (image pull ~1.7 GB plus model download); the rollout timeout is 15 minutes.
- Logs: `oc logs deploy/gemma-1b-pvc -n vllm-gemma-3-x86`.
- Tested with CRC OpenShift 4.22 and vLLM CPU image v0.31.0.
