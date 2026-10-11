# OpenShift Local (CRC) Gemma 3 1B PVC POC

**Goal:**
Deploy `RedHatAI/gemma-3-1b-it-quantized.w8a8` on OpenShift Local (CRC) in namespace `vllm-gemma-3-x86` using a PersistentVolumeClaim (PVC) to cache model weights.

**Workflow for VS Code / GitHub Copilot Agent:**
1. Verify `oc` is on PATH (`& crc oc-env | Invoke-Expression`).
2. Run `. .\scripts\load-hf-token.ps1` to ensure `$env:HF_TOKEN` is loaded.
3. Run `.\scripts\01-setup-namespace-secret.ps1` to create namespace `vllm-gemma-3-x86`, apply `anyuid` SCC, and create secret `hf-token`.
4. Run `.\scripts\02-deploy-pvc-app.ps1` to apply PVC and deployment. Wait for model download and rollout.
5. Run `.\scripts\03-test-inference.ps1` to verify inference endpoint.

6. If rollout fails, run `.\scripts\04-diagnostics.ps1` (see README troubleshooting).

Get the cluster credentials with `crc console --credentials`; never commit them to this repo.
