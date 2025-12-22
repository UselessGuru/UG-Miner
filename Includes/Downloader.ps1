<#
Copyright (c) 2018-2025 UselessGuru

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
Version:        6.7.13
Version date:   2025/12/22
#>

using module .\Includes\Include.psm1

function Expand-WebRequest { 

    param (
        [Parameter (Mandatory = $true)]
        [String]$Uri,
        [Parameter (Mandatory = $false)]
        [String]$Path = ""
    )

    # Set current path used by .net methods to the same as the script's path
    [Environment]::CurrentDirectory = $ExecutionContext.SessionState.Path.CurrentFileSystemLocation

    if (-not $Path) { $Path = Join-Path ".\Downloads" ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName }
    if (-not (Test-Path -LiteralPath ".\Downloads" -PathType Container)) { New-Item "Downloads" -ItemType "directory" | Out-Null }
    $FileName = Join-Path ".\Downloads" (Split-Path $Uri -Leaf)

    if (Test-Path -LiteralPath $FileName -PathType Leaf) { Remove-Item $FileName }
    Invoke-WebRequest -Uri $Uri -OutFile $FileName -TimeoutSec 5

    if (".msi", ".exe" -contains ([IO.FileInfo](Split-Path $Uri -Leaf)).Extension) { 
        Start-Process $FileName "-qb" -Wait | Out-Null
    }
    else { 
        $Path_Old = (Join-Path (Split-Path (Split-Path $Path)) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
        $Path_New = Split-Path $Path

        if (Test-Path -LiteralPath $Path_Old -PathType Container) { Remove-Item $Path_Old -Recurse -Force }
        Start-Process ".\Utils\7z" "x `"$([IO.Path]::GetFullPath($FileName))`" -o`"$([IO.Path]::GetFullPath($Path_Old))`" -y -spe" -Wait -WindowStyle Hidden | Out-Null

        if (Test-Path -LiteralPath $Path_New -PathType Container) { Remove-Item $Path_New -Recurse -Force }

        # Use first (topmost) directory, some miners, e.g. ClaymoreDual_v11.9, contain multiple miner binaries for different driver versions in various subdirs
        $Path_Old = ((Get-ChildItem -Path $Path_Old -File -Recurse).where({ $_.Name -eq $(Split-Path $Path -Leaf) })).Directory | Select-Object -First 1

        if ($Path_Old) { 
            (Move-Item $Path_Old $Path_New -PassThru).ForEach({ $_.LastWriteTime = [DateTime]::Now })
            $Path_Old = (Join-Path (Split-Path (Split-Path $Path)) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
            if (Test-Path -LiteralPath $Path_Old -PathType Container) { Remove-Item -Path $Path_Old -Recurse -Force }
        }
        else { 
            throw "Error: Cannot find '$Path'."
        }
    }
}

# $Config = $args.Config
$DownloadList = $args.DownloadList
$Session = $args.Session

$ProgressPreference = "SilentlyContinue"

($DownloadList | Select-Object).ForEach(
    { 
        $URI = $_.URI
        $Path = $_.Path
        $Searchable = $_.Searchable
        $Type = $_.Type

        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { 
            try { 
                Write-Message -Level Info "Downloader:<br>Initiated download of $Type from '$URI'."

                if ($URI -and (Split-Path $URI -Leaf) -eq (Split-Path $Path -Leaf)) { 
                    New-Item (Split-Path $Path) -ItemType Directory | Out-Null
                    Invoke-WebRequest $URI -OutFile $Path -ErrorAction Stop
                }
                else { 
                    [Void](Expand-WebRequest $URI $Path -ErrorAction Stop)
                }
                Write-Message -Level Info "Downloader:<br>Installed $Type '$($Path.Replace("$($Session.MainPath)\", ''))'."
                if (Get-Command "Unblock-File" -ErrorAction Ignore) { $Path | Unblock-File }
            }
            catch { 
                $Path_Old = $null

                if ($URI) { 
                    if (-not (Test-Path -LiteralPath "$($Session.MainPath)\Downloads\$(Split-Path $URI -Leaf)")) { 
                        Write-Message -Level Warn "Downloader:<br>Cannot download '$URI'."
                    }
                }
                else { Write-Message -Level Warn "Downloader:<br>Cannot download '$(Split-Path $Path -Leaf)'." }

                if ($Searchable) { 
                    Write-Message -Level Info "Downloader:<br>Searching for $Type $(Split-Path $Path -Leaf) on local computer..."

                    ($Path_Old = Get-PSDrive -PSProvider FileSystem).ForEach({ Get-ChildItem -Path $_.Root -Include (Split-Path $Path -Leaf) -Recurse }) | Sort-Object -Property LastWriteTimeUtc -Descending | Select-Object -First 1
                    $Path_New = $Path
                }

                if ($Path_Old) { 
                    if (Test-Path -LiteralPath (Split-Path $Path_New) -PathType Container) { (Split-Path $Path_New) | Remove-Item -Recurse -Force }
                    (Split-Path $Path_Old) | Copy-Item -Destination (Split-Path $Path_New) -Recurse -Force
                    Write-Message -Level Info "Downloader:<br>Copied $Type '$($Path.Replace("$($Session.MainPath)\", ''))' from local repository '$PathOld'."
                }
                else { 
                    if ($URI) { 
                        if (Test-Path -LiteralPath "$($Session.MainPath)\Downloads\$(Split-Path $URI -Leaf)") { 
                            Write-Message -Level Warn "Downloader:<br>Cannot find $Type '$(Split-Path $Path -Leaf)' in downloaded package '$($Session.MainPath)\Downloads\$(Split-Path $URI -Leaf)'."
                        }
                    }
                    else { Write-Message -Level Warn "Downloader:<br>Cannot find $Type '$($Path.Replace("$($Session.MainPath)\", ''))'." }
                }
            }
        }
    }
)

Write-Message -Level Info "Downloader:<br>All tasks complete."