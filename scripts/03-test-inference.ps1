$ErrorActionPreference = "Stop"
$NAMESPACE = "vllm-gemma-3-x86"

$ROUTE_HOST = (oc get route gemma-1b-pvc -n $NAMESPACE -o jsonpath='{.spec.host}')
if ([string]::IsNullOrWhiteSpace($ROUTE_HOST)) { throw "Could not resolve API route hostname." }

$URI = "http://$ROUTE_HOST/v1/chat/completions"

$BODY = @{
    model = "RedHatAI/gemma-3-1b-it-quantized.w8a8"
    messages = @(
        @{ role = 'user'; content = 'Explain containerization in one short sentence.' }
    )
    max_tokens = 50
    temperature = 0.1
} | ConvertTo-Json -Depth 10

Write-Host "Sending test prompt to $URI..."
try {
    $response = Invoke-RestMethod -Uri $URI -Method Post -ContentType "application/json" -Body $BODY
    Write-Host "`n=================== MODEL RESPONSE ===================" -ForegroundColor Cyan
    Write-Host $response.choices[0].message.content -ForegroundColor Green
    Write-Host "======================================================`n"
} catch {
    Write-Error "Inference request failed. Run .\scripts\04-diagnostics.ps1 to inspect pod logs.`nDetails: $_"
    exit 1
}
