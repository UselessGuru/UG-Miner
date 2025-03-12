<#
Copyright (c) 2018-2024 UselessGuru

UG-Miner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

UG-Miner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        UG-Miner
File:           \Includes\Downloader.ps1
Version:        6.4.16
Version date:   2025/03/12
#>

using module .\Includes\Include.psm1

$Config = $args.Config
$DownloadList = $args.DownloadList
$Variables = $args.Variables

$ProgressPreference = "SilentlyContinue"

($DownloadList | Select-Object).ForEach(
    { 
        $URI = $_.URI
        $Path = $_.Path
        $Searchable = $_.Searchable

        If (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { 
            Try { 
                Write-Message -Level Info "Downloader:<br>Initiated download of '$URI'."

                If ($URI -and (Split-Path $URI -Leaf) -eq (Split-Path $Path -Leaf)) { 
                    New-Item (Split-Path $Path) -ItemType Directory | Out-Null
                    Invoke-WebRequest $URI -OutFile $Path -ErrorAction Stop
                }
                Else { 
                    [Void](Expand-WebRequest $URI $Path -ErrorAction Stop)
                }
                Write-Message -Level Info "Downloader:<br>Installed downloaded miner binary '$($Path.Replace("$($Variables.MainPath)\", ''))'."
                If (Get-Command "Unblock-File" -ErrorAction Ignore) { $Path | Unblock-File }
            }
            Catch { 
                $Path_Old = $null

                If ($URI) { Write-Message -Level Warn "Downloader:<br>Cannot download '$(Split-Path $Path -Leaf)' distributed at '$URI'." }
                Else { Write-Message -Level Warn "Downloader:<br>Cannot download '$(Split-Path $Path -Leaf)'." }

                If ($Searchable) { 
                    Write-Message -Level Info "Downloader:<br>Searching for $(Split-Path $Path -Leaf) on local computer..."

                    ($Path_Old = Get-PSDrive -PSProvider FileSystem).ForEach({ Get-ChildItem -Path $_.Root -Include (Split-Path $Path -Leaf) -Recurse }) | Sort-Object -Property LastWriteTimeUtc -Descending | Select-Object -First 1
                    $Path_New = $Path
                }

                If ($Path_Old) { 
                    If (Test-Path -LiteralPath (Split-Path $Path_New) -PathType Container) { (Split-Path $Path_New) | Remove-Item -Recurse -Force }
                    (Split-Path $Path_Old) | Copy-Item -Destination (Split-Path $Path_New) -Recurse -Force
                    Write-Message -Level Info "Downloader:<br>Copied '$($Path.Replace("$($Variables.MainPath)\", ''))' from local repository '$PathOld'."
                }
                Else { 
                    If ($URI) { Write-Message -Level Warn "Downloader:<br>Cannot find '$($Path.Replace("$($Variables.MainPath)\", ''))' distributed at '$URI'." }
                    Else { Write-Message -Level Warn "Downloader:<br>Cannot find '$($Path.Replace("$($Variables.MainPath)\", ''))'." }
                }
            }
        }
    }
)

Write-Message -Level Info "Downloader:<br>All tasks complete."