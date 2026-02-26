@echo off

where /q PWSH.exe

if ERRORLEVEL 1 (

  echo PWSH 6 or later is required.
  echo The preferred PWSH version is version 7.5.4 which can be downloaded from https://github.com/PowerShell/PowerShell/releases.
  echo Press any key to exit the script.
  pause > nul

) else (
  pushd "%CD%"
  CD /D "%~dp0"

  Set POWERSHELL_UPDATECHECK=Off

  conhost.exe PWSH -ExecutionPolicy bypass -WindowStyle maximized -Command "%~dp0UG-Miner.ps1" -ConfigFile "%~dp0Config\Config.json"
)