param(
  [string]$Code,
  [int]$Port = 8080
)
if (-not $Code) {
  Write-Error "Usage: rcli.ps1 -Code <code> [-Port <port>]"
  exit 1
}
$Body = @{ command = $Code } | ConvertTo-Json
Invoke-RestMethod -Uri "http://127.0.0.1:$Port/execute" -Method Post -Body $Body -ContentType 'application/json'
