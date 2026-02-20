@echo off
REM Executive Report Generator Wrapper
REM Makes it easy to generate reports from Windows command line

setlocal enabledelayedexpansion

REM Get the script directory
set SCRIPT_DIR=%~dp0

REM Check if Python 3 is available
where python >nul 2>nul
if errorlevel 1 (
    echo Error: Python 3 is not installed or not in PATH
    echo Please install Python 3 and add it to your PATH
    exit /b 1
)

REM Parse arguments
set FROM_DATE=
set TO_DATE=
set OUTPUT=
set LATEST=
set NO_SAVE=
set REPO=.
set ROADMAP=
set PDF=

:parse_args
if "%~1"=="" goto end_parse
if "%~1"=="--from" (
    set FROM_DATE=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--to" (
    set TO_DATE=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--output" (
    set OUTPUT=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--latest" (
    set LATEST=1
    shift
    goto parse_args
)
if "%~1"=="--no-save" (
    set NO_SAVE=1
    shift
    goto parse_args
)
if "%~1"=="--repo" (
    set REPO=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--roadmap" (
    set ROADMAP=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--pdf" (
    set PDF=1
    shift
    goto parse_args
)
if "%~1"=="--help" (
    goto show_help
)
shift
goto parse_args

:end_parse
set ARGS=
if not "%FROM_DATE%"=="" set ARGS=%ARGS% --from %FROM_DATE%
if not "%TO_DATE%"=="" set ARGS=%ARGS% --to %TO_DATE%
if not "%OUTPUT%"=="" set ARGS=%ARGS% --output "%OUTPUT%"
if not "%LATEST%"=="" set ARGS=%ARGS% --latest
if not "%NO_SAVE%"=="" set ARGS=%ARGS% --no-save
if not "%REPO%"=="" set ARGS=%ARGS% --repo "%REPO%"
if not "%ROADMAP%"=="" set ARGS=%ARGS% --roadmap %ROADMAP%
if not "%PDF%"=="" set ARGS=%ARGS% --pdf

python "%SCRIPT_DIR%generate_executive_report.py" %ARGS%
exit /b %errorlevel%

:show_help
echo Usage: generate_executive_report.bat [options]
echo.
echo Options:
echo   --from DATE          Start date (YYYY-MM-DD) - inclusive
echo   --to DATE            End date (YYYY-MM-DD) - inclusive
echo   --latest             Generate report for last 7 days
echo   --output FILENAME    Output filename (default: auto-generated)
echo   --no-save            Print report to stdout instead of saving
echo   --repo PATH          Path to repository (default: current directory)
echo   --roadmap M1,M2      Scope report to milestones (comma-separated)
echo   --pdf                Export report to PDF
echo   --help               Show this help message
echo.
echo Examples:
echo   REM Cumulative report
echo   generate_executive_report.bat
echo.
echo   REM Report for date range
echo   generate_executive_report.bat --from 2026-01-15 --to 2026-02-14
echo.
echo   REM Report from date to today
echo   generate_executive_report.bat --from 2026-02-01
echo.
echo   REM Last 7 days
echo   generate_executive_report.bat --latest
echo.
echo   REM Scoped to a roadmap
echo   generate_executive_report.bat --roadmap M1,M2
exit /b 0
