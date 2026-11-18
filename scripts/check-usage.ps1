# Prints the current Claude plan usage (weekly / 5-hour) by making one tiny
# headless Haiku call and reading the rate_limit_event from the stream output.

# A CLI on PATH can be too old to emit rate_limit_event, so prefer the newest
# binary bundled with the VS Code extension.
$exe = Get-ChildItem "$HOME\.vscode\extensions" -Directory -Filter 'anthropic.claude-code-*' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    ForEach-Object { Join-Path $_.FullName 'resources\native-binary\claude.exe' } |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $exe) { $exe = (Get-Command claude -ErrorAction SilentlyContinue).Source }
if (-not $exe -and (Test-Path "$HOME\.local\bin\claude.exe")) { $exe = "$HOME\.local\bin\claude.exe" }
if (-not $exe) { 'Claude Code binary not found.'; exit 1 }

Push-Location ([IO.Path]::GetTempPath())
try {
    $lines = & $exe -p 'reply with just: ok' --model haiku --output-format stream-json --verbose 2>$null
} finally { Pop-Location }

$windows = @{}
foreach ($line in $lines) {
    try { $o = $line | ConvertFrom-Json } catch { continue }
    if ($o.type -ne 'rate_limit_event') { continue }
    $info = $o.rate_limit_info
    if ($info.unifiedWindows) {
        foreach ($w in $info.unifiedWindows.PSObject.Properties) { $windows[$w.Name] = $w.Value }
    } elseif ($info.rateLimitType) {
        $windows[$info.rateLimitType] = [pscustomobject]@{ utilization = $info.utilization; resetsAt = $info.resetsAt }
    }
    "status: $($info.status)"
}

if ($windows.Count -eq 0) { 'No rate limit data returned.'; exit 1 }
foreach ($name in $windows.Keys) {
    $w = $windows[$name]
    $pct = if ($null -ne $w.utilization) { '{0:P0}' -f [double]$w.utilization } else { 'n/a' }
    $reset = if ($w.resetsAt) { [DateTimeOffset]::FromUnixTimeSeconds($w.resetsAt).LocalDateTime.ToString('yyyy-MM-dd HH:mm') } else { 'n/a' }
    "{0}: {1} used, resets {2} (local)" -f $name, $pct, $reset
}
