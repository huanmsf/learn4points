# Smart Answer Assistant Startup Script
Write-Host "Smart Answer Assistant Startup Script" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Yellow

# Check and terminate processes occupying port 8080
Write-Host "Checking port 8080 usage..." -ForegroundColor Blue

try {
    $connections = netstat -ano | Select-String ":8080.*LISTENING"
    
    if ($connections) {
        foreach ($line in $connections) {
            $parts = $line.ToString().Split()
            $lastPart = $parts[-1]  # Get the last part (PID)
            
            if ($lastPart -match '^\d+$') {  # Ensure it's a number
                Write-Host "Found process with PID: $lastPart using port 8080" -ForegroundColor Yellow
                Write-Host "Terminating process..." -ForegroundColor Red
                Start-Process -FilePath "taskkill" -ArgumentList "/f", "/pid", $lastPart -Wait -NoNewWindow
                Write-Host "Process terminated successfully" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "Port 8080 is not in use" -ForegroundColor Green
    }
} catch {
    Write-Host "Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    
    # Fallback: stop dart processes
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    try {
        $dartProcesses = Get-Process -Name "dart" -ErrorAction SilentlyContinue
        if ($dartProcesses) {
            foreach ($proc in $dartProcesses) {
                Write-Host "Stopping dart process: $($proc.Id)" -ForegroundColor Red
                Stop-Process -Id $proc.Id -Force
            }
            Write-Host "Dart processes stopped" -ForegroundColor Green
        }
    } catch {
        Write-Host "Could not stop dart processes: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Wait for port to be released
Start-Sleep -Seconds 2

Write-Host "Cleaning Flutter cache..." -ForegroundColor Blue
flutter clean | Out-Null

Write-Host "Getting dependencies..." -ForegroundColor Blue
flutter pub get

Write-Host "Starting Flutter Web app..." -ForegroundColor Green
Write-Host "App will run at http://localhost:8080" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the app" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow

# Start Flutter app
flutter run -d chrome --web-hostname localhost --web-port 8080 