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

REM Copy pre-push hook
if exist "%SOURCE_HOOKS%\pre-push" (
    copy /Y "%SOURCE_HOOKS%\pre-push" "%HOOKS_DIR%\pre-push" >nul
    echo [OK] Installed pre-push hook
) else (
    echo [ERROR] pre-push hook not found at %SOURCE_HOOKS%\pre-push
    exit /b 1
)

echo.
echo Git hooks installed successfully!
echo.
echo The following checks will run before each commit:
echo   * Dart formatting (dart format)
echo   * Flutter analyzer (flutter analyze)
echo.
echo The following check will run before each push:
echo   * Branch protection (blocks push to main/master/develop)
echo.
echo To bypass hooks in rare cases:
echo   git commit --no-verify   (Skip pre-commit checks)
echo   git push --no-verify     (Skip pre-push checks - ONLY for emergencies)
