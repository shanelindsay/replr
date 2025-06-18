$ErrorActionPreference = 'Stop'
$configDir = Join-Path $HOME '.replr'
$instFile  = Join-Path $configDir 'instances'
$defaultPort = 8080

if (!(Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir | Out-Null }
if (!(Test-Path $instFile)) { New-Item -ItemType File -Path $instFile | Out-Null }

function Load-Instances {
    $inst = @{}
    if (Test-Path $instFile) {
        Get-Content $instFile | ForEach-Object {
            $parts = $_ -split ':'
            $inst[$parts[0]] = @{ port = [int]$parts[1]; pid = [int]$parts[2] }
        }
    }
    return $inst
}

function Save-Instances($inst) {
    $inst.GetEnumerator() | ForEach-Object {
        "$($_.Key):$($inst[$_.Key].port):$($inst[$_.Key].pid)"
    } | Set-Content $instFile
}

function Port-Of($label, $inst) {
    if ($inst.ContainsKey($label)) { return $inst[$label].port }
    return [int]$label
}

$cmd = if ($args.Count) { $args[0] } else { '' }
$inst = Load-Instances

switch ($cmd) {
    'start' {
        $label = if ($args.Length -gt 1) { $args[1] } else { 'default' }
        $port  = if ($args.Length -gt 2) { [int]$args[2] } else { $defaultPort }
        $proc = Start-Process -PassThru Rscript -ArgumentList 'replr_server.R','--background','--port',$port
        $inst[$label] = @{ port = $port; pid = $proc.Id }
        Save-Instances $inst
        Write-Output "Started '$label' on port $port (PID $($proc.Id))"
    }
    'stop' {
        $label = if ($args.Length -gt 1) { $args[1] } else { 'default' }
        $port = Port-Of $label $inst
        Invoke-RestMethod -Uri "http://127.0.0.1:$port/shutdown" -Method Post > $null
        if ($inst.ContainsKey($label)) { $inst.Remove($label); Save-Instances $inst }
        Write-Output "Sent shutdown to '$label' (port $port)"
    }
    'status' {
        $label = if ($args.Length -gt 1) { $args[1] } else { 'default' }
        $port = Port-Of $label $inst
        Invoke-RestMethod -Uri "http://127.0.0.1:$port/status" | ConvertTo-Json -Depth 10
    }
    'exec' {
        $label = if ($args.Length -gt 1) { $args[1] } else { 'default' }
        $code = $null
        $i = 2
        while ($i -lt $args.Count) {
            if ($args[$i] -eq '-e') { $code = $args[$i+1]; $i += 2 } else { $i++ }
        }
        if (-not $code) { $code = [Console]::In.ReadToEnd() }
        if (-not $code) { Write-Error 'Nothing to run; supply code with -e or pipe via stdin'; exit 1 }
        $port = Port-Of $label $inst
        $body = @{ command = $code } | ConvertTo-Json
        Invoke-RestMethod -Uri "http://127.0.0.1:$port/execute" -Method Post -Body $body -ContentType 'application/json' | ConvertTo-Json -Depth 10
    }
    'list' {
        Get-Content $instFile
    }
    default {
        Write-Output "Usage: clir.ps1 {start [label] [port]|stop [label]|status [label]|exec [label] -e CODE|exec [label] < script.R|list}"
    }
}
