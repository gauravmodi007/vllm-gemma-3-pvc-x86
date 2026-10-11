# Helper script to load HF_TOKEN into active PowerShell session
if ($env:HF_TOKEN -and $env:HF_TOKEN -ne "your_token_here") {
    Write-Host "HF_TOKEN is already active in current environment." -ForegroundColor Green
    return
}

# 1. Try local CLI cache first
$tokenPath = Join-Path $HOME '.cache\huggingface\token'
if (Test-Path -LiteralPath $tokenPath) {
    $tokenVal = (Get-Content -LiteralPath $tokenPath -Raw).Trim()
    if ($tokenVal) {
        $env:HF_TOKEN = $tokenVal
        Write-Host "Loaded HF_TOKEN from Hugging Face CLI cache ($tokenPath)." -ForegroundColor Green
        return
    }
}

# 2. Try .env file in root
$envPath = Join-Path $PSScriptRoot "..\.env"
if (Test-Path -LiteralPath $envPath) {
    Get-Content $envPath | ForEach-Object {
        if ($_ -match "^\s*HF_TOKEN\s*=\s*(.+)$") {
            $val = $matches[1].Trim(' "', "'")
            if ($val -and $val -ne "your_token_here") {
                $env:HF_TOKEN = $val
                Write-Host "Loaded HF_TOKEN from .env file." -ForegroundColor Green
                return
            }
        }
    }
}

Write-Error "HF_TOKEN not found! Please set `$env:HF_TOKEN = 'your_token'` or add it to `.env`."
