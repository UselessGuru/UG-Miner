@echo off
:: BatchGotAdmin
::-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"="
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
::--------------------------------------

@echo off

where /q PWSH.exe

if ERRORLEVEL 1 (

  echo Powershell 6 or later is required. Cannot continue.
  pause

) else (
  pushd "%CD%"
  CD /D "%~dp0"

  if not "%GPU_FORCE_64BIT_PTR%"=="1" (setx GPU_FORCE_64BIT_PTR 1) > nul
  if not "%GPU_MAX_HEAP_SIZE%"=="100" (setx GPU_MAX_HEAP_SIZE 100) > nul
  if not "%GPU_USE_SYNC_OBJECTS%"=="1" (setx GPU_USE_SYNC_OBJECTS 1) > nul
  if not "%GPU_MAX_ALLOC_PERCENT%"=="100" (setx GPU_MAX_ALLOC_PERCENT 100) > nul
  if not "%GPU_SINGLE_ALLOC_PERCENT%"=="100" (setx GPU_SINGLE_ALLOC_PERCENT 100) > nul
  if not "%CUDA_DEVICE_ORDER%"=="PCI_BUS_ID" (setx CUDA_DEVICE_ORDER PCI_BUS_ID) > nul

  where /q WT.exe

  if ERRORLEVEL 1 (

    PWSH -WorkingDirectory "%~dp0" -ExecutionPolicy bypass -WindowStyle maximized -Command "%~dp0UG-Miner.ps1" -ConfigFile "%~dp0Config\config.json"

  ) else (

    WT --maximized --profile "PowerShell 7" PWSH -WorkingDirectory "%~dp0" -ExecutionPolicy bypass -WindowStyle maximized -Command "%~dp0UG-Miner.ps1" -ConfigFile "%~dp0Config\config.json"

  )
)