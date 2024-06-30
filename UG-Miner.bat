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

    conhost.exe PWSH -ExecutionPolicy bypass -WindowStyle maximized -Command "%~dp0UG-Miner.ps1" -ConfigFile "%~dp0Config\config.json"

  )
)