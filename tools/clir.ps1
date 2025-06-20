$ErrorActionPreference = 'Stop'
$configDir = Join-Path $HOME '.replr'
$instFile  = Join-Path $configDir 'instances'
$defaultPort = 8080
$defaultHost = '127.0.0.1'

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
        $host  = if ($args.Length -gt 3) { $args[3] } else { $defaultHost }
        $proc = Start-Process -PassThru Rscript -ArgumentList 'replr_server.R','--background','--port',$port,'--host',$host
        $inst[$label] = @{ port = $port; pid = $proc.Id }
        Save-Instances $inst
        Write-Output "Started '$label' on $host:$port (PID $($proc.Id))"
    }
    'stop' {
        $label = if ($args.Length -gt 1) { $args[1] } else { 'default' }
        $host  = if ($args.Length -gt 2) { $args[2] } else { $defaultHost }
        $port = Port-Of $label $inst
        Invoke-RestMethod -Uri "http://$host:$port/shutdown" -Method Post > $null
        if ($inst.ContainsKey($label)) { $inst.Remove($label); Save-Instances $inst }
        Write-Output "Sent shutdown to '$label' on $host (port $port)"
    }
    'status' {
        $label = if ($args.Length -gt 1) { $args[1] } else { 'default' }
        $json = $false
        $host = $defaultHost
        $i = 2
        while ($i -lt $args.Length) {
            if ($args[$i] -eq '--json') { $json = $true; $i++ }
            else { $host = $args[$i]; $i++ }
        }
        $port = Port-Of $label $inst
        $resp = Invoke-RestMethod -Uri "http://$host:$port/status"
        if ($json) { $resp | ConvertTo-Json -Depth 10 } else { $resp }
    }
    'exec' {
        $label = if ($args.Length -gt 1) { $args[1] } else { 'default' }
        $code = $null
        $json = $false
        $host = $defaultHost
        $i = 2
        while ($i -lt $args.Count) {
            if ($args[$i] -eq '-e') { $code = $args[$i+1]; $i += 2 }
            elseif ($args[$i] -eq '--json') { $json = $true; $i++ }
            else { $host = $args[$i]; $i++ }
        }
        if (-not $code) { $code = [Console]::In.ReadToEnd() }
        if (-not $code) { Write-Error 'Nothing to run; supply code with -e or pipe via stdin'; exit 1 }
        $port = Port-Of $label $inst
        $body = @{ command = $code } | ConvertTo-Json
        $url = "http://$host:$port/execute"
        if (-not $json) { $url = "$url?format=text" } else { $url = "$url?plain=false" }
        $resp = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType 'application/json'
        if ($json) { $resp | ConvertTo-Json -Depth 10 } else { $resp }
    }
    'list' {
        Get-Content $instFile
    }
    default {
        Write-Output "Usage: clir.ps1 {start [label] [port] [host]|stop [label] [host]|status [label] [host] [--json]|exec [label] [-e CODE] [--json] [host]|list}"
    }
}
