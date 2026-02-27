@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================
REM  Kiro + Auto Memory 一键启动脚本
REM  同事只需双击此脚本即可完成所有配置
REM  步骤：
REM    1. 检查并安装 Git
REM    2. 检查并安装 Kiro
REM    3. Clone/更新共享经验库
REM    4. 同步 steering 文件
REM    5. 配置 git hooks
REM    6. 同步共享经验
REM    7. 启动 Kiro 打开项目
REM ============================================

set SHARED_REPO_URL=https://github.com/wzg624gxx/shared-memory.git
set SHARED_REPO=D:\shared-memory-test
set KIRO_INSTALLER_URL=https://github.com/wzg624gxx/shared-memory/releases/download/Kiro%%E5%%AE%%89%%E8%%A3%%85%%E5%%8C%%85/kiro-ide-0.10.32-stable-win32-x64.exe
set KIRO_INSTALLER_FILE=%TEMP%\KiroSetup.exe
set PROJECT_DIR=%~1
if "%PROJECT_DIR%"=="" set PROJECT_DIR=%CD%

echo ============================================
echo   Kiro + Auto Memory 一键启动
echo ============================================
echo.

REM ---- Step 1: 检查 Git ----
echo [1/7] 检查 Git...
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未找到 Git，请安装 Git：https://git-scm.com/download/win
    start "" "https://git-scm.com/download/win"
    echo.
    echo 安装 Git 后请重新运行此脚本
    pause
    exit /b 1
)
echo [OK] Git 已安装

REM ---- Step 2: 检查 Kiro ----
echo [2/7] 检查 Kiro...
set KIRO_FOUND=0

where kiro >nul 2>&1
if %errorlevel% equ 0 (
    set KIRO_FOUND=1
    set KIRO_CMD=kiro
)

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
    echo [提示] 未找到 Kiro IDE，正在下载安装...
    curl -L -o "%KIRO_INSTALLER_FILE%" "%KIRO_INSTALLER_URL%"
    if !errorlevel! neq 0 (
        echo [错误] 下载失败，请手动下载：https://kiro.dev/downloads
        pause
        exit /b 1
    )
    echo [OK] 下载完成
    echo      正在安装 Kiro...
    "%KIRO_INSTALLER_FILE%" /S
    if !errorlevel! neq 0 (
        "%KIRO_INSTALLER_FILE%"
    )
    echo      等待安装完成...
    timeout /t 15 /nobreak >nul
    del "%KIRO_INSTALLER_FILE%" >nul 2>&1

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
        echo [错误] 安装后仍未找到 Kiro，请手动安装后重试
        pause
        exit /b 1
    )
)
echo [OK] Kiro 已安装

REM ---- Step 3: Clone 或更新共享经验库 ----
echo [3/7] 同步共享经验库...
if not exist "%SHARED_REPO%\.git" (
    echo      共享经验库不存在，正在 clone...
    git clone "%SHARED_REPO_URL%" "%SHARED_REPO%" >nul 2>&1
    if !errorlevel! neq 0 (
        echo [警告] clone 失败，跳过共享经验同步
    ) else (
        echo [OK] 共享经验库已 clone
    )
) else (
    git -C "%SHARED_REPO%" pull origin main >nul 2>&1
    echo [OK] 共享经验库已更新
)

REM ---- Step 4: 同步 steering 文件（不再同步 hooks） ----
echo [4/7] 同步配置文件...
echo      目标项目: %PROJECT_DIR%

if not exist "%PROJECT_DIR%\.kiro\steering" mkdir "%PROJECT_DIR%\.kiro\steering"

REM 只同步 steering 模板（不覆盖已有文件）
if exist "%SHARED_REPO%\kiro-template\steering" (
    for %%f in ("%SHARED_REPO%\kiro-template\steering\*") do (
        if not exist "%PROJECT_DIR%\.kiro\steering\%%~nxf" (
            copy /Y "%%f" "%PROJECT_DIR%\.kiro\steering\" >nul
            echo      + steering: %%~nxf
        )
    )
)
echo [OK] 配置文件已同步

REM ---- Step 5: 配置 git hooks（core.hooksPath） ----
echo [5/7] 配置 git hooks...
if exist "%PROJECT_DIR%\.githooks" (
    git -C "%PROJECT_DIR%" config core.hooksPath .githooks >nul 2>&1
    echo [OK] git core.hooksPath 已设置为 .githooks
) else (
    echo [跳过] 项目中未找到 .githooks 目录
)

REM ---- Step 6: 同步共享经验到项目 ----
echo [6/7] 同步共享经验...
if not exist "%PROJECT_DIR%\.kiro\steering\shared" mkdir "%PROJECT_DIR%\.kiro\steering\shared"

REM 同步全局经验
if exist "%SHARED_REPO%\global" (
    for %%f in ("%SHARED_REPO%\global\*.md") do (
        copy /Y "%%f" "%PROJECT_DIR%\.kiro\steering\shared\" >nul 2>&1
    )
)

REM 自动识别项目类型并同步对应 profile 经验
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

echo      项目类型: !PROFILE!

if exist "%SHARED_REPO%\profiles\!PROFILE!" (
    for %%f in ("%SHARED_REPO%\profiles\!PROFILE!\*.md") do (
        copy /Y "%%f" "%PROJECT_DIR%\.kiro\steering\shared\" >nul 2>&1
    )
)
echo [OK] 共享经验已同步

REM ---- Step 7: 启动 Kiro ----
echo [7/7] 启动 Kiro...
echo.
echo ============================================
echo   配置完成！Kiro 正在启动...
echo ============================================

start "" !KIRO_CMD! "%PROJECT_DIR%"
