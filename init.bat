@echo off
REM Auto Memory ?????
REM ???????????? D:\shared-memory-test\init.bat

set SHARED_REPO=D:\shared-memory-test
set TARGET=.kiro

echo [Auto Memory] ?????...

if not exist "%TARGET%\steering" mkdir "%TARGET%\steering"
if not exist "%TARGET%\hooks" mkdir "%TARGET%\hooks"

REM ?? hooks
copy /Y "%SHARED_REPO%\kiro-template\hooks\*" "%TARGET%\hooks\" >nul 2>&1

REM ?? steering ??
copy /Y "%SHARED_REPO%\kiro-template\steering\*" "%TARGET%\steering\" >nul 2>&1

echo [Auto Memory] ??????hooks ? steering ??????
