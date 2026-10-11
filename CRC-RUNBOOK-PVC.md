# CRC + PVC Model Storage Runbook

This runbook documents the PVC-based deployment pattern for running `RedHatAI/gemma-3-1b-it-quantized.w8a8` on OpenShift Local (CRC).

## Architectural Comparison: PVC vs. Baked Image

| Feature | Baked Image Pattern | PVC Pattern (This Repo) |
|---|---|---|
| **Build Setup** | Requires `podman build` inside Podman VM / WSL2 | **Zero build required.** Pulls stock `vllm/vllm-openai-cpu` |
| **CRC Registry Setup** | Requires route exposure, CA cert installation, `/etc/hosts` DNS hack in VM | **Not required.** Pulls standard container image from public registry |
| **Model Weights** | Embedded into container image layer | Stored on 20Gi `PersistentVolumeClaim` |
| **First Launch** | Instant (weights already in image) | ~2-3 min initial download into PVC (cached permanently after) |
| **Memory Management** | `8Gi` Limit, 1Gi KV Cache, `/dev/shm` 2Gi | `8Gi` Limit, 1Gi KV Cache, `/dev/shm` 2Gi |

## Step-by-Step Execution Guide

### 1. Initialize OpenShift Environment
```powershell
& crc oc-env | Invoke-Expression
oc login -u kubeadmin https://api.crc.testing:6443
```
Get the kubeadmin password with `crc console --credentials`. Image used: `vllm/vllm-openai-cpu:v0.31.0` (see README prerequisites and troubleshooting).

### 2. Load Hugging Face Token
```powershell
. .\scripts\load-hf-token.ps1
```
This helper checks `$HOME\.cache\huggingface\token` or `.env` and exports `$env:HF_TOKEN` into the active PowerShell session.

### 3. Namespace & Credentials Setup
```powershell
.\scripts\01-setup-namespace-secret.ps1
```
Creates namespace `vllm-gemma-3-x86`, applies `anyuid` SCC policy to the default service account, and populates the `hf-token` Kubernetes Secret.

### 4. Deploy Infrastructure & Application
```powershell
.\scripts\02-deploy-pvc-app.ps1
```
Applies:
- `k8s/01-pvc.yaml`: Requests 20Gi storage on CRC default storage class (`crc-csi-hostpath-provisioner`).
- `k8s/02-gemma-pvc-app.yaml`: Deploys vLLM server with mounted PVC at `/models-cache`, `8Gi` RAM limit, `/dev/shm` 2Gi mount, and 15-minute startup health probe.

### 5. Memory Failure Post-Mortem & Configuration
- **Initial Finding:** With a `7Gi` RAM limit and `VLLM_CPU_KVCACHE_SPACE="1"`, vLLM reported only ~0.29 GiB remaining for KV cache, failing health probes.
- **Root Cause:** Total memory = Model weights (~1.0 GiB) + Python/vLLM/PyTorch overhead (~3.5 GiB) + `/dev/shm` shared memory usage (~1.5 GiB) + vLLM KV Cache (1.0 GiB) = ~7.0 GiB total required.
- **Proven Solution:** Raised memory limits to `8Gi` (`requests: 6Gi`, `limits: 8Gi`) while keeping `VLLM_CPU_KVCACHE_SPACE="1"` and capping `--max-model-len 512` and `--max-num-seqs 1`.

### 6. Verify Inference
```powershell
.\scripts\03-test-inference.ps1
```
