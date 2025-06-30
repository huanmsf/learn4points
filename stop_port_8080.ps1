# 简单可靠的8080端口清理脚本
Write-Host "Stopping processes on port 8080..." -ForegroundColor Yellow

# 方法1：使用netstat + taskkill
try {
    $connections = netstat -ano | Select-String ":8080.*LISTENING"
    
    if ($connections) {
        foreach ($line in $connections) {
            $parts = $line.ToString().Split()
            $lastPart = $parts[-1]  # 获取最后一部分（PID）
            
            if ($lastPart -match '^\d+$') {  # 确保是数字
                Write-Host "Terminating process ID: $lastPart" -ForegroundColor Red
                Start-Process -FilePath "taskkill" -ArgumentList "/f", "/pid", $lastPart -Wait -NoNewWindow
            }
        }
        Write-Host "Port 8080 cleanup completed!" -ForegroundColor Green
    } else {
        Write-Host "No processes found on port 8080." -ForegroundColor Green
    }
} catch {
    Write-Host "Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    
    # 备用方法：直接杀掉dart进程
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    try {
        $dartProcesses = Get-Process -Name "dart" -ErrorAction SilentlyContinue
        if ($dartProcesses) {
            foreach ($proc in $dartProcesses) {
                Write-Host "Stopping dart process: $($proc.Id)" -ForegroundColor Red
                Stop-Process -Id $proc.Id -Force
            }
        }
        Write-Host "Dart processes stopped!" -ForegroundColor Green
    } catch {
        Write-Host "Could not stop dart processes: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Done!" -ForegroundColor Green 