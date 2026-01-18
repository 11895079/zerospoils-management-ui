@echo off
REM Setup script to install Git hooks for ZeroSpoils project (Windows)
REM Run this after cloning the repository

echo Setting up Git hooks for ZeroSpoils...

REM Get repository root
for /f "tokens=*" %%i in ('git rev-parse --show-toplevel') do set REPO_ROOT=%%i

REM Convert forward slashes to backslashes for Windows
set REPO_ROOT=%REPO_ROOT:/=\%

set HOOKS_DIR=%REPO_ROOT%\.git\hooks
set SOURCE_HOOKS=%REPO_ROOT%\scripts\hooks

REM Ensure hooks directory exists
if not exist "%HOOKS_DIR%" mkdir "%HOOKS_DIR%"

REM Copy pre-commit hook
if exist "%SOURCE_HOOKS%\pre-commit" (
    copy /Y "%SOURCE_HOOKS%\pre-commit" "%HOOKS_DIR%\pre-commit" >nul
    echo [OK] Installed pre-commit hook
) else (
    echo [ERROR] pre-commit hook not found at %SOURCE_HOOKS%\pre-commit
    exit /b 1
)

echo.
echo Git hooks installed successfully!
echo.
echo The following checks will run before each commit:
echo   * Dart formatting (dart format)
echo   * Flutter analyzer (flutter analyze)
echo.
echo To bypass hooks in rare cases, use: git commit --no-verify
