@echo off

where /q PWSH.exe

if ERRORLEVEL 1 (

  echo PWSH 6 or later is required.
  echo The preferred PWSH version is version 7.5.3 which can be downloaded from https://github.com/PowerShell/PowerShell/releases.
  echo Press any key to exit the script.
  pause > nul

) else (
  pushd "%CD%"
  CD /D "%~dp0"

  if not "%GPU_FORCE_64BIT_PTR%"=="1" (setx GPU_FORCE_64BIT_PTR 1) > nul
  if not "%GPU_MAX_HEAP_SIZE%"=="100" (setx GPU_MAX_HEAP_SIZE 100) > nul
  if not "%GPU_USE_SYNC_OBJECTS%"=="1" (setx GPU_USE_SYNC_OBJECTS 1) > nul
  if not "%GPU_MAX_ALLOC_PERCENT%"=="100" (setx GPU_MAX_ALLOC_PERCENT 100) > nul
  if not "%GPU_SINGLE_ALLOC_PERCENT%"=="100" (setx GPU_SINGLE_ALLOC_PERCENT 100) > nul
  if not "%CUDA_DEVICE_ORDER%"=="PCI_BUS_ID" (setx CUDA_DEVICE_ORDER PCI_BUS_ID) > nul

  conhost.exe PWSH -ExecutionPolicy bypass -WindowStyle maximized -Command "%~dp0UG-Miner.ps1" -ConfigFile "%~dp0Config\Config.json"
)