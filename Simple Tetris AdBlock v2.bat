@echo off
title Tetrio Ad Blocker Windows
setlocal enabledelayedexpansion

:: Universal path (per-user)
set "DEFAULT_PATH=%LOCALAPPDATA%\Programs\tetrio-desktop\TETR.IO.exe"
set "CONFIG_PATH=%~dp0tetrio-path.txt"
set "TETRIO_PATH="

:: Load or find path
if exist "%CONFIG_PATH%" set /p TETRIO_PATH=<"%CONFIG_PATH%" & if exist "%TETRIO_PATH%" goto path_ok
if exist "%DEFAULT_PATH%" set "TETRIO_PATH=%DEFAULT_PATH%" & goto path_ok

:: Picker (fixed PowerShell) - Used for Option 2
:picker
powershell -ExecutionPolicy Bypass -WindowStyle Normal -Command "Add-Type -AssemblyName System.Windows.Forms; $dlg=[System.Windows.Forms.OpenFileDialog]::new(); $dlg.Title='Select TETR.IO.exe'; $dlg.Filter='TETR.IO.exe|TETR.IO.exe|EXE|*.exe'; $dlg.InitialDirectory='%LOCALAPPDATA%\Programs'; if($dlg.ShowDialog() -eq 'OK'){$dlg.FileName}else{exit 1}" >"%TEMP%\path.tmp" 2>nul
set /p TETRIO_PATH=<"%TEMP%\path.tmp" & del "%TEMP%\path.tmp" 2>nul
if not exist "%TETRIO_PATH%" (
    echo ERROR: No TETR.IO.exe found/selected. Install from tetr.io.
    timeout /t 3 >nul & goto picker
)
echo %TETRIO_PATH%">"%CONFIG_PATH%"

:path_ok
set "EXT_DIR=%~dp0adblock-ext"
set "SHORTCUT_PATH=%~dp0TETR.IO-NoAds.lnk"
set "RESOLVER_RULES=MAP pagead2.googlesyndication.com 0.0.0.0,MAP googleads.g.doubleclick.net 0.0.0.0,MAP pubads.g.doubleclick.net 0.0.0.0,MAP securepubads.g.doubleclick.net 0.0.0.0,MAP tpc.googlesyndication.com 0.0.0.0,MAP static.doubleclick.net 0.0.0.0,MAP adservice.google.com 0.0.0.0,MAP ad.doubleclick.net 0.0.0.0,MAP pagead.googlesyndication.com 0.0.0.0,MAP www.googletagservices.com 0.0.0.0,MAP googleadservices.com 0.0.0.0,MAP partner.googleadservices.com 0.0.0.0"

:: AUTOMATIC LAUNCH CHECK
if exist "%TETRIO_PATH%" goto launch
goto picker

:menu
cls
echo ========================================
echo Tetrio FIXED - CRASH-FREE + NO WHITE BOX
echo ========================================
echo Path: %TETRIO_PATH%
echo PowerShell writes files (no batch crash)^
echo SUPER AGGRESSIVE: Hides bottom white rect + parents.
echo.
echo 1. LAUNCH ADBLOCKED TETR.IO
echo 2. SELECT TETR.IO PATH
echo 3. KILL TETR.IO (Safe)
echo 4. CLEANUP
echo 5. EXIT
echo ========================================
choice /c 12345 /n /m "Choose: "

if errorlevel 5 exit /b
if errorlevel 4 goto cleanup
if errorlevel 3 goto kill
if errorlevel 2 goto picker3
if errorlevel 1 goto launch

:picker3
:: New Picker (Does not minimize batch window)
powershell -ExecutionPolicy Bypass -WindowStyle Normal -Command "Add-Type -AssemblyName System.Windows.Forms; $dlg=[System.Windows.Forms.OpenFileDialog]::new(); $dlg.Title='Select TETR.IO.exe'; $dlg.Filter='TETR.IO.exe|TETR.IO.exe|EXE|*.exe'; $dlg.InitialDirectory='%LOCALAPPDATA%\Programs'; if($dlg.ShowDialog() -eq 'OK'){$dlg.FileName | Out-File '%TEMP%\path3.tmp' -Encoding ascii } else { exit 1 }" >"%TEMP%\path3.tmp" 2>nul
set /p TETRIO_PATH=<"%TEMP%\path3.tmp" & del "%TEMP%\path3.tmp" 2>nul
if not exist "%TETRIO_PATH%" (
    echo ERROR: No TETR.IO.exe found/selected. Install from tetr.io.
    timeout /t 3 >nul & goto menu
)
echo %TETRIO_PATH%">"%CONFIG_PATH%"
echo New path saved.
pause
goto menu

:shortcut
echo [1/4] Cleaning old ext...
if exist "%EXT_DIR%" rmdir /s /q "%EXT_DIR%" >nul 2>nul
mkdir "%EXT_DIR%" >nul

echo [2/4] Writing extension (PowerShell - crash-proof)...
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
"$m=@{manifest_version=3; name='Tetrio Ad Killer'; version='1.0'; content_scripts=@(@{matches=@('://tetr.io/','://.tetr.io/'); css=@('hide-ads.css'); js=@('kill-ads.js'); run_at='document_start'}); permissions=@('scripting')}; $m | ConvertTo-Json | Set-Content '%EXT_DIR%\manifest.json' -Encoding UTF8; ^
'@document.addEventListener(\"DOMContentLoaded\",()=>{const s=[\".ad-slot\",\".adsbygoogle\",\"#ads\",\".ad-container\",\"[class=\\\"ad\\\"]\",\"[id*=\\\"ad\\\"]\",\"iframe[src*=\\\"google\\\"]\",\"ins.adsbygoogle\",\".google-ads\",\".ad-rectangle\",\".ad-banner\",\"div[data-ad]\",\"#ad-bottom\",\".ads-frame\"];s.forEach(sel=>{document.querySelectorAll(sel).forEach(el=>{el.style.display=\"none!important\";el.remove();});});const o=new MutationObserver(m=>{m.forEach(mu=>{mu.addedNodes.forEach(n=>{if(n.nodeType===1){s.forEach(sel=>{if(n.matches(sel))n.remove();n.querySelectorAll(sel).forEach(el=>el.remove());});}});});});o.observe(document.body,{childList:true,subtree:true});setInterval(()=>{s.forEach(sel=>document.querySelectorAll(sel).forEach(el=>el.remove()));},250);},false);@' | Set-Content '%EXT_DIR%\kill-ads.js' -Encoding UTF8; ^
'@.ad-slot,.adsbygoogle,#ads,.ad-container,[class*=ad],[id*=ad],iframe[src*=google],ins.adsbygoogle,.google-ads,.ad-rectangle,.ad-banner,div[data-ad],#ad-bottom,.ads-frame,*[data-google-query-id]{display:none!important;visibility:hidden!important;height:0!important;width:0!important;margin:0!important;padding:0!important;position:absolute!important;opacity:0!important;z-index:-9999!important;max-height:0!important;min-height:0!important;overflow:hidden!important;box-sizing:border-box!important;border:none!important;}@' | Set-Content '%EXT_DIR%\hide-ads.css' -Encoding UTF8"

echo [3/4] Building shortcut...
if exist "%SHORTCUT_PATH%" del "%SHORTCUT_PATH%" >nul
set "FULL_ARGS=--host-resolver-rules=\"%RESOLVER_RULES%\" --load-extension=\"%EXT_DIR%\" --disable-web-security --disable-features=VizDisplayCompositor"
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
"$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%SHORTCUT_PATH%'); $s.TargetPath='%TETRIO_PATH%'; $s.Arguments='%FULL_ARGS%'; $s.IconLocation='%TETRIO_PATH%'; $s.Description='Tetrio Ad-Free'; $s.WorkingDirectory='%~dp0'; $s.Save()"

echo [4/4] DONE!
echo ========================================
echo SUCCESS: TETR.IO-NoAds.lnk + adblock-ext/
echo DOUBLE-CLICK shortcut - NO white box/space!
echo KEEP FOLDER WITH SHORTCUT. Pin it!
echo ========================================
pause
goto menu

:launch
:: Launch in new window and close script immediately
start "" "%TETRIO_PATH%" --host-resolver-rules="%RESOLVER_RULES%" --load-extension="%EXT_DIR%" --disable-web-security --disable-features=VizDisplayCompositor
exit /b

:kill
taskkill /f /im TETR.IO.exe >nul 2>&1
taskkill /f /im tetrio-desktop.exe >nul 2>&1
echo Killed safely.
pause
goto menu

:cleanup
del "%SHORTCUT_PATH%" >nul 2>nul
rmdir /s /q "%EXT_DIR%" >nul 2>nul
del "%CONFIG_PATH%" >nul 2>nul
echo Cleaned.
pause
goto menu