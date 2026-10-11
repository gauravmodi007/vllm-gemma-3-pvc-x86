$ErrorActionPreference = "Stop"
$NAMESPACE = "vllm-gemma-3-x86"

Write-Host "Applying PersistentVolumeClaim..."
oc apply -f k8s/01-pvc.yaml -n $NAMESPACE
if ($LASTEXITCODE -ne 0) { throw "Failed to apply PVC manifest." }

Write-Host "Applying vLLM Application Manifests (Deployment, Service, Route)..."
oc apply -f k8s/02-gemma-pvc-app.yaml -n $NAMESPACE
if ($LASTEXITCODE -ne 0) { throw "Failed to apply App manifest." }

Write-Host "Waiting for pod rollout and initial model download into PVC..."
Write-Host "(Initial run takes ~2-3 minutes to download weights to PVC. Timeout set to 15 mins)..."
oc rollout status deployment/gemma-1b-pvc -n $NAMESPACE --timeout=900s
if ($LASTEXITCODE -ne 0) { throw "Deployment failed to become ready. Run 04-diagnostics.ps1." }

Write-Host "Deployment successfully rolled out and healthy!" -ForegroundColor Green
