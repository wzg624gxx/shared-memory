@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================
REM  Kiro + Auto Memory ?????
REM  ?????????????????????
REM  ???
REM    1. ????? Git
REM    2. ????????? Kiro
REM    3. Clone/???????
REM    4. ????? .kiro ??
REM    5. ??????
REM    6. ?? Kiro ????
REM ============================================

set SHARED_REPO_URL=https://github.com/wzg624gxx/shared-memory.git
set SHARED_REPO=D:\shared-memory-test
set KIRO_INSTALLER_URL=https://github.com/wzg624gxx/shared-memory/releases/download/Kiro%%E5%%AE%%89%%E8%%A3%%85%%E5%%8C%%85/kiro-ide-0.10.32-stable-win32-x64.exe
set KIRO_INSTALLER_FILE=%TEMP%\KiroSetup.exe
set PROJECT_DIR=%~1
if "%PROJECT_DIR%"=="" set PROJECT_DIR=%CD%

echo ============================================
echo   Kiro + Auto Memory ?????
echo ============================================
echo.

REM ---- Step 1: ?? Git ----
echo [1/6] ?? Git...
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo [??] ???? Git????? Git?https://git-scm.com/download/win
    echo ???? Git ????...
    start "" "https://git-scm.com/download/win"
    echo.
    echo ??? Git ???????????
    pause
    exit /b 1
)
echo [OK] Git ???

REM ---- Step 2: ?? Kiro ----
echo [2/6] ?? Kiro...
set KIRO_FOUND=0

REM ?? PATH ???? kiro
where kiro >nul 2>&1
if %errorlevel% equ 0 (
    set KIRO_FOUND=1
    set KIRO_CMD=kiro
)

REM ????????
if !KIRO_FOUND! equ 0 (
    if exist "%LOCALAPPDATA%\Programs\Kiro\Kiro.exe" (
        set KIRO_FOUND=1
        set KIRO_CMD="%LOCALAPPDATA%\Programs\Kiro\Kiro.exe"
    )
)
if !KIRO_FOUND! equ 0 (
    if exist "%PROGRAMFILES%\Kiro\Kiro.exe" (
        set KIRO_FOUND=1
        set KIRO_CMD="%PROGRAMFILES%\Kiro\Kiro.exe"
    )
)
if !KIRO_FOUND! equ 0 (
    if exist "%USERPROFILE%\AppData\Local\Programs\Kiro\Kiro.exe" (
        set KIRO_FOUND=1
        set KIRO_CMD="%USERPROFILE%\AppData\Local\Programs\Kiro\Kiro.exe"
    )
)

if !KIRO_FOUND! equ 0 (
    echo [??] ???? Kiro IDE?????????...
    echo      ????: GitHub Releases
    echo      ??????????????...
    echo.

    REM ?? curl ???Windows 10+ ?? curl?
    curl -L -o "%KIRO_INSTALLER_FILE%" "%KIRO_INSTALLER_URL%"
    if !errorlevel! neq 0 (
        echo [??] ????????????
        echo ?????????https://kiro.dev/downloads
        pause
        exit /b 1
    )
    echo [OK] ????

    echo      ?????? Kiro...
    "%KIRO_INSTALLER_FILE%" /S
    if !errorlevel! neq 0 (
        echo [??] ??????????????...
        "%KIRO_INSTALLER_FILE%"
    )

    REM ??????
    echo      ??????...
    timeout /t 15 /nobreak >nul

    REM ?????
    del "%KIRO_INSTALLER_FILE%" >nul 2>&1

    REM ???? Kiro
    set KIRO_FOUND=0
    if exist "%LOCALAPPDATA%\Programs\Kiro\Kiro.exe" (
        set KIRO_FOUND=1
        set KIRO_CMD="%LOCALAPPDATA%\Programs\Kiro\Kiro.exe"
    )
    if !KIRO_FOUND! equ 0 (
        if exist "%USERPROFILE%\AppData\Local\Programs\Kiro\Kiro.exe" (
            set KIRO_FOUND=1
            set KIRO_CMD="%USERPROFILE%\AppData\Local\Programs\Kiro\Kiro.exe"
        )
    )
    if !KIRO_FOUND! equ 0 (
        where kiro >nul 2>&1
        if !errorlevel! equ 0 (
            set KIRO_FOUND=1
            set KIRO_CMD=kiro
        )
    )

    if !KIRO_FOUND! equ 0 (
        echo [??] ???????? Kiro??????????????
        pause
        exit /b 1
    )
)
echo [OK] Kiro ???

REM ---- Step 3: Clone ???????? ----
echo [3/6] ???????...
if not exist "%SHARED_REPO%\.git" (
    echo      ??????? clone ?????...
    git clone "%SHARED_REPO_URL%" "%SHARED_REPO%" >nul 2>&1
    if !errorlevel! neq 0 (
        echo [??] clone ???????????
    ) else (
        echo [OK] ?????? clone
    )
) else (
    git -C "%SHARED_REPO%" pull origin main >nul 2>&1
    echo [OK] ????????
)

REM ---- Step 4: ????? .kiro ?? ----
echo [4/6] ???????...
echo      ????: %PROJECT_DIR%

if not exist "%PROJECT_DIR%\.kiro\hooks" mkdir "%PROJECT_DIR%\.kiro\hooks"
if not exist "%PROJECT_DIR%\.kiro\steering" mkdir "%PROJECT_DIR%\.kiro\steering"

REM ?? hooks?????????
if exist "%SHARED_REPO%\kiro-template\hooks" (
    for %%f in ("%SHARED_REPO%\kiro-template\hooks\*") do (
        if not exist "%PROJECT_DIR%\.kiro\hooks\%%~nxf" (
            copy /Y "%%f" "%PROJECT_DIR%\.kiro\hooks\" >nul
            echo      + hook: %%~nxf
        )
    )
)

REM ?? steering ???????????
if exist "%SHARED_REPO%\kiro-template\steering" (
    for %%f in ("%SHARED_REPO%\kiro-template\steering\*") do (
        if not exist "%PROJECT_DIR%\.kiro\steering\%%~nxf" (
            copy /Y "%%f" "%PROJECT_DIR%\.kiro\steering\" >nul
            echo      + steering: %%~nxf
        )
    )
)
echo [OK] ???????

REM ---- Step 5: ????????? ----
echo [5/6] ?????????...
if not exist "%PROJECT_DIR%\.kiro\steering\shared" mkdir "%PROJECT_DIR%\.kiro\steering\shared"

REM ??????
if exist "%SHARED_REPO%\global" (
    for %%f in ("%SHARED_REPO%\global\*.md") do (
        copy /Y "%%f" "%PROJECT_DIR%\.kiro\steering\shared\" >nul 2>&1
    )
)

REM ????????????? profile ???
set PROFILE=generic
if exist "%PROJECT_DIR%\pom.xml" (
    findstr /i "teamcenter" "%PROJECT_DIR%\pom.xml" >nul 2>&1
    if !errorlevel! equ 0 (
        set PROFILE=teamcenter-rac
    ) else (
        findstr /i "spring-boot" "%PROJECT_DIR%\pom.xml" >nul 2>&1
        if !errorlevel! equ 0 set PROFILE=springboot-api
    )
)
if exist "%PROJECT_DIR%\package.json" (
    findstr /i "react" "%PROJECT_DIR%\package.json" >nul 2>&1
    if !errorlevel! equ 0 (
        set PROFILE=react-frontend
    ) else (
        findstr /i "vue" "%PROJECT_DIR%\package.json" >nul 2>&1
        if !errorlevel! equ 0 set PROFILE=vue-frontend
    )
)
if exist "%PROJECT_DIR%\build.gradle" set PROFILE=gradle-java

echo      ????: !PROFILE!

if exist "%SHARED_REPO%\profiles\!PROFILE!" (
    for %%f in ("%SHARED_REPO%\profiles\!PROFILE!\*.md") do (
        copy /Y "%%f" "%PROJECT_DIR%\.kiro\steering\shared\" >nul 2>&1
    )
)
echo [OK] ???????

REM ---- Step 6: ?? Kiro ----
echo [6/6] ?? Kiro...
echo.
echo ============================================
echo   ?????Kiro ????...
echo ============================================

start "" !KIRO_CMD! "%PROJECT_DIR%"
