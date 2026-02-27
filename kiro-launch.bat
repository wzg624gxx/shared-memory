@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================
REM  Kiro + Auto Memory 一键启动器
REM  用法：双击运行，或拖拽项目文件夹到此脚本上
REM  功能：
REM    1. 检查并安装 Git
REM    2. 检查并安装 Kiro
REM    3. Clone/更新共享经验库
REM    4. 初始化项目 .kiro 配置
REM    5. 同步共享经验
REM    6. 启动 Kiro 打开项目
REM ============================================

set SHARED_REPO_URL=https://github.com/wzg624gxx/shared-memory.git
set SHARED_REPO=D:\shared-memory-test
set KIRO_DOWNLOAD_URL=https://kiro.dev/downloads
set PROJECT_DIR=%~1
if "%PROJECT_DIR%"=="" set PROJECT_DIR=%CD%

echo ============================================
echo   Kiro + Auto Memory 一键启动器
echo ============================================
echo.

REM ---- Step 1: 检查 Git ----
echo [1/6] 检查 Git...
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未检测到 Git，请先安装 Git：https://git-scm.com/download/win
    echo 正在打开 Git 下载页面...
    start "" "https://git-scm.com/download/win"
    echo.
    echo 安装完 Git 后，请重新运行此脚本。
    pause
    exit /b 1
)
echo [OK] Git 已安装

REM ---- Step 2: 检查 Kiro ----
echo [2/6] 检查 Kiro...
set KIRO_FOUND=0

REM 检查 PATH 中是否有 kiro
where kiro >nul 2>&1
if %errorlevel% equ 0 (
    set KIRO_FOUND=1
    set KIRO_CMD=kiro
)

REM 检查常见安装路径
if %KIRO_FOUND% equ 0 (
    if exist "%LOCALAPPDATA%\Programs\Kiro\Kiro.exe" (
        set KIRO_FOUND=1
        set KIRO_CMD="%LOCALAPPDATA%\Programs\Kiro\Kiro.exe"
    )
)
if %KIRO_FOUND% equ 0 (
    if exist "%PROGRAMFILES%\Kiro\Kiro.exe" (
        set KIRO_FOUND=1
        set KIRO_CMD="%PROGRAMFILES%\Kiro\Kiro.exe"
    )
)
if %KIRO_FOUND% equ 0 (
    if exist "%USERPROFILE%\AppData\Local\Programs\Kiro\Kiro.exe" (
        set KIRO_FOUND=1
        set KIRO_CMD="%USERPROFILE%\AppData\Local\Programs\Kiro\Kiro.exe"
    )
)

if %KIRO_FOUND% equ 0 (
    echo [提示] 未检测到 Kiro IDE，正在打开下载页面...
    start "" "%KIRO_DOWNLOAD_URL%"
    echo.
    echo 请下载并安装 Kiro IDE，安装完成后重新运行此脚本。
    pause
    exit /b 1
)
echo [OK] Kiro 已安装

REM ---- Step 3: Clone 或更新共享经验库 ----
echo [3/6] 同步共享经验库...
if not exist "%SHARED_REPO%\.git" (
    echo      首次使用，正在 clone 共享经验库...
    git clone "%SHARED_REPO_URL%" "%SHARED_REPO%" >nul 2>&1
    if %errorlevel% neq 0 (
        echo [警告] clone 失败，跳过共享经验同步
    ) else (
        echo [OK] 共享经验库已 clone
    )
) else (
    git -C "%SHARED_REPO%" pull origin main >nul 2>&1
    echo [OK] 共享经验库已更新
)

REM ---- Step 4: 初始化项目 .kiro 配置 ----
echo [4/6] 初始化项目配置...
echo      项目路径: %PROJECT_DIR%

if not exist "%PROJECT_DIR%\.kiro\hooks" mkdir "%PROJECT_DIR%\.kiro\hooks"
if not exist "%PROJECT_DIR%\.kiro\steering" mkdir "%PROJECT_DIR%\.kiro\steering"

REM 复制 hooks（不覆盖已有文件）
if exist "%SHARED_REPO%\kiro-template\hooks" (
    for %%f in ("%SHARED_REPO%\kiro-template\hooks\*") do (
        if not exist "%PROJECT_DIR%\.kiro\hooks\%%~nxf" (
            copy /Y "%%f" "%PROJECT_DIR%\.kiro\hooks\" >nul
            echo      + hook: %%~nxf
        )
    )
)

REM 复制 steering 规则（不覆盖已有文件）
if exist "%SHARED_REPO%\kiro-template\steering" (
    for %%f in ("%SHARED_REPO%\kiro-template\steering\*") do (
        if not exist "%PROJECT_DIR%\.kiro\steering\%%~nxf" (
            copy /Y "%%f" "%PROJECT_DIR%\.kiro\steering\" >nul
            echo      + steering: %%~nxf
        )
    )
)
echo [OK] 项目配置已就绪

REM ---- Step 5: 同步共享经验到项目 ----
echo [5/6] 同步共享经验到项目...
if not exist "%PROJECT_DIR%\.kiro\steering\shared" mkdir "%PROJECT_DIR%\.kiro\steering\shared"

REM 同步全局经验
if exist "%SHARED_REPO%\global" (
    for %%f in ("%SHARED_REPO%\global\*.md") do (
        copy /Y "%%f" "%PROJECT_DIR%\.kiro\steering\shared\" >nul 2>&1
    )
)

REM 自动检测项目类型并同步对应 profile 的经验
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

echo      项目类型: %PROFILE%

if exist "%SHARED_REPO%\profiles\%PROFILE%" (
    for %%f in ("%SHARED_REPO%\profiles\%PROFILE%\*.md") do (
        copy /Y "%%f" "%PROJECT_DIR%\.kiro\steering\shared\" >nul 2>&1
    )
)
echo [OK] 共享经验已同步

REM ---- Step 6: 启动 Kiro ----
echo [6/6] 启动 Kiro...
echo.
echo ============================================
echo   一切就绪！Kiro 正在启动...
echo ============================================

start "" %KIRO_CMD% "%PROJECT_DIR%"
