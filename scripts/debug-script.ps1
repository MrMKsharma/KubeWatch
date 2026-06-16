$PSScriptRoot
"---"
$configPath = Join-Path $PSScriptRoot ".."
$configPath = Join-Path $configPath "infra"
$configPath = Join-Path $configPath "kind"
$configPath = Join-Path $configPath "kind-config.yaml"
$configPath
"---"
Test-Path $configPath
