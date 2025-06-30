Write-Host "Cleaning port 8080..." -ForegroundColor Yellow

$processes = netstat -ano | findstr :8080 | findstr LISTENING
if ($processes) {
    $processes | ForEach-Object {
        $line = $_.Trim()
        $parts = $line -split '\s+'
        if ($parts.Length -ge 5) {
            $processId = $parts[4]
            Write-Host "Killing process with PID: $processId" -ForegroundColor Red
            taskkill /f /pid $processId
        }
    }
    Write-Host "Port 8080 cleaned!" -ForegroundColor Green
} else {
    Write-Host "Port 8080 is not in use." -ForegroundColor Green
} 