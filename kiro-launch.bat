@echo off
REM ============================================
REM  Kiro + Auto Memory ???
REM  ???kiro-launch.bat [????]
REM  ????????????????
REM ============================================

set SHARED_REPO=D:\shared-memory-test
set PROJECT_DIR=%~1
if "%PROJECT_DIR%"=="" set PROJECT_DIR=%CD%

echo [Auto Memory] ????: %PROJECT_DIR%

REM Step 1: ???????? clone
if not exist "%SHARED_REPO%\.git" (
    echo [Auto Memory] ??????? clone ?????...
    git clone https://github.com/wzg624gxx/shared-memory.git "%SHARED_REPO%"
) else (
    echo [Auto Memory] ??????????...
    git -C "%SHARED_REPO%" pull origin main >nul 2>&1
)

REM Step 2: ?????? .kiro ??
if not exist "%PROJECT_DIR%\.kiro\hooks" mkdir "%PROJECT_DIR%\.kiro\hooks"
if not exist "%PROJECT_DIR%\.kiro\steering" mkdir "%PROJECT_DIR%\.kiro\steering"

REM ???????????????????????????
for %%f in ("%SHARED_REPO%\kiro-template\hooks\*") do (
    if not exist "%PROJECT_DIR%\.kiro\hooks\%%~nxf" (
        copy /Y "%%f" "%PROJECT_DIR%\.kiro\hooks\" >nul
        echo [Auto Memory] ??? hook: %%~nxf
    )
)
for %%f in ("%SHARED_REPO%\kiro-template\steering\*") do (
    if not exist "%PROJECT_DIR%\.kiro\steering\%%~nxf" (
        copy /Y "%%f" "%PROJECT_DIR%\.kiro\steering\" >nul
        echo [Auto Memory] ??? steering: %%~nxf
    )
)

REM Step 3: ????????????
if not exist "%PROJECT_DIR%\.kiro\steering\shared" mkdir "%PROJECT_DIR%\.kiro\steering\shared"
if exist "%SHARED_REPO%\global" (
    xcopy /Y /Q "%SHARED_REPO%\global\*.md" "%PROJECT_DIR%\.kiro\steering\shared\" >nul 2>&1
)

echo [Auto Memory] ?????????? Kiro...

REM Step 4: ?? Kiro ????
start "" kiro "%PROJECT_DIR%"
