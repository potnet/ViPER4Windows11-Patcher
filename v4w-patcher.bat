:: ViPER4Windows Patcher for Windows 11
@echo off
setlocal EnableDelayedExpansion

::
:: REQUESTING ADMINISTRATIVE PRIVILEGES (Enhanced method for Windows 11)
::
>nul 2>&1 fsutil dirty query %systemdrive%
if '%errorlevel%' NEQ '0' (
	echo Requesting administrative privileges...
	powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
	exit /B
)

::
:: MAIN SCRIPT STARTS BELOW
::
title "ViPER4Windows Patcher for Windows 11"
color 0B
pushd "%~dp0"
set APPVAR=3.2
:: Detect installation path (try both potential registry locations)
for /f "tokens=2*" %%X in ('REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\ViPER4Windows" /v ConfigPath 2^>nul') do set PAppDir=%%Y
if not defined PAppDir (
    for /f "tokens=2*" %%X in ('REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ViPER4Windows" /v ConfigPath 2^>nul') do set PAppDir=%%Y
)
if not defined PAppDir (
    set PAppDir=NOT_FOUND
    set AppDir=NOT_FOUND
) else (
    set AppDir=%PAppDir:\DriverComm=%
)
mode con: cols=56 lines=22

:CHOICE_MENU
call:BANNER
echo      +--------[ OPTION MENU ]---------------+
echo      ^|                                      ^|
echo      ^|  1. Registry Patch (No PsExec)       ^|
echo      ^|  2. Launch Configurator              ^|
echo      ^|  3. Restart Audio Service            ^|
echo      ^|  4. Verify Installation              ^|
echo      ^|  0. Exit                             ^|
echo      +--------------------------------------+
echo.
echo   # Close media players before option 3.
echo   # Installation path: %AppDir%
echo   # Type a number below and press Enter key.
echo.
set CMVAR=
set /p "CMVAR=Enter Option: "
if "%CMVAR%"=="0" exit
if "%CMVAR%"=="4" goto:VERIFY_INSTALLATION
if "%AppDir%"=="NOT_FOUND" (
	call:BANNER
	echo [FAIL!] ViPER4Windows installation not detected.
	echo Please ensure ViPER4Windows is properly installed.
	>nul 2>&1 timeout /t 3
	goto:CHOICE_MENU
) else (
	if "%CMVAR%"=="1" call:PATCH_REGISTRY
	if "%CMVAR%"=="2" call:LAUNCH_CONFIGURATOR
	if "%CMVAR%"=="3" (
		call:BANNER
		call:RESTART_AUDIO_SERVICE
	)
)
goto:CHOICE_MENU

:VERIFY_INSTALLATION
call:BANNER
echo Checking ViPER4Windows installation...
echo.
if "%AppDir%"=="NOT_FOUND" (
    echo [FAIL!] Registry keys for ViPER4Windows not found.
) else (
    echo [INFO] Registry path found: %AppDir%
)

if exist "%AppDir%\ViPER4WindowsCtrlPanel.exe" (
    echo [PASS] Control panel executable found.
) else (
    echo [FAIL!] Control panel executable missing.
)

if exist "%AppDir%\Configurator.exe" (
    echo [PASS] Configurator executable found.
) else (
    echo [FAIL!] Configurator executable missing.
)

echo.
echo Press any key to return to menu...
pause >nul
goto:CHOICE_MENU

:PATCH_REGISTRY
call:BANNER
echo Applying registry patches for Windows 11...
echo This may take a moment...

:: Apply Run as Admin settings
echo Setting Run as Admin flags...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%AppDir%\ViPER4WindowsCtrlPanel.exe" /t REG_SZ /d "RUNASADMIN" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%AppDir%\ViPER4WindowsCtrlPanel.exe" /t REG_SZ /d "RUNASADMIN" /f

:: Remove old registry keys if they exist (one by one to prevent hanging)
echo Checking and removing old registry keys...
reg query "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" >nul 2>&1
if %errorlevel% EQU 0 (
    echo Removing old HKLM APO registry keys...
    reg delete "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /f
)

reg query "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" >nul 2>&1
if %errorlevel% EQU 0 (
    echo Removing old HKCR APO registry keys...
    reg delete "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /f
)

:: Create registry entries for ViPER4Windows - with /f to force overwrite without prompting
echo Creating registry entries for HKLM path...
reg add "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "FriendlyName" /t REG_SZ /d "ViPER4Windows" /f
reg add "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "Copyright" /t REG_SZ /d "Copyright (C) 2013, vipercn.com" /f
reg add "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MajorVersion" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MinorVersion" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "Flags" /t REG_DWORD /d "13" /f
reg add "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MinInputConnections" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MaxInputConnections" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MinOutputConnections" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MaxOutputConnections" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MaxInstances" /t REG_DWORD /d "4294967295" /f
reg add "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "NumAPOInterfaces" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "APOInterface0" /t REG_SZ /d "{FD7F2B29-24D0-4B5C-B177-592C39F9CA10}" /f

:: Try alternate path if available
echo Creating registry entries for HKCR path...
reg add "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "FriendlyName" /t REG_SZ /d "ViPER4Windows" /f
reg add "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "Copyright" /t REG_SZ /d "Copyright (C) 2013, vipercn.com" /f
reg add "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MajorVersion" /t REG_DWORD /d "1" /f
reg add "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MinorVersion" /t REG_DWORD /d "0" /f
reg add "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "Flags" /t REG_DWORD /d "13" /f
reg add "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MinInputConnections" /t REG_DWORD /d "1" /f
reg add "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MaxInputConnections" /t REG_DWORD /d "1" /f
reg add "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MinOutputConnections" /t REG_DWORD /d "1" /f
reg add "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MaxOutputConnections" /t REG_DWORD /d "1" /f
reg add "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "MaxInstances" /t REG_DWORD /d "4294967295" /f
reg add "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "NumAPOInterfaces" /t REG_DWORD /d "1" /f
reg add "HKCR\AudioEngine\AudioProcessingObjects\{DA2FB532-3014-4B93-AD05-21B2C620F9C2}" /v "APOInterface0" /t REG_SZ /d "{FD7F2B29-24D0-4B5C-B177-592C39F9CA10}" /f

:: Add Windows 11 specific registry key
echo Adding Windows 11 specific registry keys...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" /v "DisableProtectedAudioDG" /t REG_DWORD /d "1" /f

:: Additional patch for Windows 11 22H2 and later
echo Adding compatibility patches for Windows 11 22H2+...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotEnforceEnterpriseTLSCertPinning" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" /v "AllowMultipleAudioDevices" /t REG_DWORD /d "1" /f

:: Windows 11 23H2-specific patches
echo Adding Windows 11 23H2+ specific registry keys...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\MTCUVC" /v "EnableMTCUVC" /t REG_DWORD /d "0" /f

call:BANNER
echo [DONE] Registry patches applied for Windows 11.
echo [DONE] Run as Admin patch applied.
echo [INFO] Restarting audio service...
call:RESTART_AUDIO_SERVICE

:LAUNCH_CONFIGURATOR
if exist "%AppDir%\Configurator.exe" (
	start "" "%AppDir%\Configurator.exe"
	goto:CHOICE_MENU
) else (
	call:BANNER
	echo [FAIL!] ViPER4Windows Configurator not found.
	echo Checked path: %AppDir%\Configurator.exe
	>nul 2>&1 timeout /t 3
	goto:CHOICE_MENU
)

:RESTART_AUDIO_SERVICE
echo Restarting Windows 11 Audio Service...
:: Enhanced service restart method for Windows 11
echo Stopping Audiosrv...
net stop Audiosrv /y
echo Waiting for service to stop completely...
timeout /t 2 /nobreak >nul
echo Starting Audiosrv...
net start Audiosrv
echo Starting AudioEndpointBuilder...
net start AudioEndpointBuilder
echo [DONE] Audio Service Restarted.
timeout /t 2 /nobreak >nul
goto:eof

:BANNER
cls                                   
echo                    ______________________
echo         ViPER4Windows Patcher for Win11 \__ 
echo       \\        version %APPVAR%            /  \ 
echo        \\___________________________\__/
echo.&echo.
goto:eof