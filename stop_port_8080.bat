@echo off
echo Stopping processes on port 8080...

REM 查找占用8080端口的进程
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080 ^| findstr LISTENING') do (
    echo Terminating process ID: %%a
    taskkill /f /pid %%a 2>nul
    if !errorlevel! equ 0 (
        echo Success: Process %%a terminated.
    ) else (
        echo Warning: Could not terminate process %%a
    )
)

echo Done!
pause 