$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$requiredFiles = @(
    'infra/core/foundry.bicep',
    'infra/core/monitoring.bicep',
    'k8s/keyvault-foundry-spc.yaml',
    'k8s/keyvault-foundry-api-key-spc.yaml',
    'k8s/keyvault-foundry-model-deployment-spc.yaml',
    'scripts/deploy-foundry.ps1'
)

foreach ($relativePath in $requiredFiles) {
    if (!(Test-Path (Join-Path $repoRoot $relativePath))) {
        throw "Required Foundry migration file is missing: $relativePath"
    }
}

$sourceFiles = Get-ChildItem $repoRoot -Recurse -File -Include *.cs,*.csproj,*.bicep,*.json,*.ps1,*.sh,*.yaml |
    Where-Object {
        $_.FullName -notmatch '[\\/](Workshop|bin|obj|\.git)[\\/]' -and
        $_.Name -ne 'test-foundry-migration.ps1'
    }
$source = $sourceFiles | Get-Content -Raw

$forbiddenPatterns = @(
    '2023-03-15-preview',
    'secrets-store-openai',
    'keyvault-openai',
    'AZURE_OPENAI_',
    'deploy-openai.ps1'
)

foreach ($pattern in $forbiddenPatterns) {
    if ($source -match [regex]::Escape($pattern)) {
        throw "Found stale migration value outside the workshop: $pattern"
    }
}

$applicationFiles = @(
    (Join-Path $repoRoot 'AdminSite/Services/FoundryChatClient.cs'),
    (Join-Path $repoRoot 'StoreFront/Controllers/ChatbotController.cs')
)
$applicationSource = (Get-Content -Path $applicationFiles -Raw) -join "`n"

if ($applicationSource -notmatch '/openai/v1/chat/completions') {
    throw 'Applications do not use the stable OpenAI v1 chat completions route.'
}

if ($applicationSource -notmatch 'Headers.Add\("api-key"') {
    throw 'Applications do not use the api-key request header.'
}

Write-Host 'Foundry migration contract validation passed.'