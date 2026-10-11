$ErrorActionPreference = "Stop"
$NAMESPACE = "vllm-gemma-3-x86"

if (-not $env:HF_TOKEN) {
    throw "HF_TOKEN is not set in environment. Please run `. .\scripts\load-hf-token.ps1` first."
}

Write-Host "Creating namespace $NAMESPACE if not present..."
$nsYaml = oc create namespace $NAMESPACE --dry-run=client -o yaml
$nsYaml | oc apply -f -
if ($LASTEXITCODE -ne 0) { throw "Failed to create/apply namespace." }

Write-Host "Granting anyuid SCC to default service account in $NAMESPACE..."
oc adm policy add-scc-to-user anyuid -z default -n $NAMESPACE
if ($LASTEXITCODE -ne 0) { throw "Failed to grant SCC policy." }

Write-Host "Creating/updating Hugging Face secret 'hf-token'..."
oc create secret generic hf-token --from-literal=token=$env:HF_TOKEN -n $NAMESPACE --dry-run=client -o yaml | oc apply -f -
if ($LASTEXITCODE -ne 0) { throw "Failed to create hf-token secret." }

Write-Host "Namespace and Secret setup complete!" -ForegroundColor Green
