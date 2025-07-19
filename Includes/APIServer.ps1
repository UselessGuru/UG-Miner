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
File:           \Includes\APIServer.ps1
Version:        6.5.1
Version date:   2025/07/19
#>

using module .\Include.psm1

$APIversion = "6.0.10"

(Get-Process -Id $PID).PriorityClass = "Normal"

# Set the starting directory
$BasePath = "$PWD\web"

If ($Config.Transcript) { Start-Transcript -Path ".\Debug\APIServer-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

# List of possible mime types for files
$MIMEtypes = @{ 
    ".js"   = "application/x-javascript"
    ".html" = "text/html"
    ".htm"  = "text/html"
    ".json" = "application/json"
    ".css"  = "text/css"
    ".txt"  = "text/plain"
    ".ico"  = "image/x-icon"
    ".ps1"  = "text/html" # ps1 files get executed, assume their response is html
}

# Setup the listener
$Server = [System.Net.HttpListener]::new()

# Listening on anything other than localhost requires admin privileges
$Server.Prefixes.Add("http://localhost:$($Config.APIport)/")
$Server.Start()
$Variables.APIversion = $APIversion
$Variables.APIserver = $Server

$GCstopWatch = [System.Diagnostics.StopWatch]::New()
$GCstopWatch.Start()

While ($Variables.APIversion -and $Server.IsListening) { 
    $Context = $Server.GetContext()
    $Request = $Context.Request

    # Determine the requested resource and parse query strings
    $Path = $Request.Url.LocalPath

    If ($Request.HttpMethod -eq "GET") { 
        # Parse any parameters in the URL - $Request.Url.Query looks like "+ ?a=b&c=d&message=Hello%20world"
        # Decode any url escaped characters in the key and value
        $Parameters = @{ }
        ($Request.Url.Query -replace "\?" -split "&").ForEach(
            { 
                $Key, $Value = $_ -split "="
                # Decode any url escaped characters in the key and value
                $Key = [System.Web.HttpUtility]::UrlDecode($Key)
                $Value = [System.Web.HttpUtility]::UrlDecode($Value)
                If ($Key -and $Value) { $Parameters.$Key = $Value }
            }
        )
        If ($Config.APIlogfile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): $($Request.Url)" | Out-File $Config.APIlogfile -Append -ErrorAction Ignore }
        Remove-Variable Value -ErrorAction Ignore
    }
    ElseIf ($Request.HttpMethod -eq "POST") { 
        $Length = $Request.contentlength64
        $Buffer = New-Object "byte[]" $Length

        [Void]$Request.inputstream.read($Buffer, 0, $Length)
        $Body = [Text.Encoding]::ascii.getstring($Buffer)

        If ($Config.APIlogfile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): $($Request.Url) POST:$Body" | Out-File $Config.APIlogfile -Append -ErrorAction Ignore }

        $Parameters = @{ }
        ($Body -split "&").ForEach(
            { 
                $Key, $Value = $_ -split "="
                # Decode any url escaped characters in the key and value
                $Key = [System.Web.HttpUtility]::UrDecode($Key)
                $Value = [System.Web.HttpUtility]::UrlDecode($Value)
                If ($Key -and $Value) { $Parameters.$Key = $Value }
            }
        )
        Remove-Variable Buffer, Body, Key, Length, Value -ErrorAction Ignore
    }

    # Create a new response and the defaults for associated settings
    $Response = $Context.Response
    $ContentType = "application/json"
    $StatusCode = 200
    $Data = ""

    # Set the proper content type, status code and data for each resource
    Switch ($Path) { 
        "/functions/algorithm/disable" { 
            # Disable algorithm@pool in poolsconfig.json
            $PoolNames = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Name
            $Algorithms = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Algorithm
            If ($Pools = @($Variables.Pools.Where({ $PoolNames -contains $_.Name -and $Algorithms -contains $_.Algorithm }))) { 
                $PoolsConfig = [System.IO.File]::ReadAllLines($Config.PoolsConfigFile) | ConvertFrom-Json
                ForEach ($Pool in $Pools) { 
                    If ($PoolsConfig.($Pool.Name).Algorithm -like "-*") { 
                        $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm += "-$($Pool.Algorithm)") | Sort-Object -Unique
                        $Pool.Reasons = $Pool.Reasons.Add("Algorithm disabled (`-$($Pool.Algorithm)` in $($Pool.Name) pool config)") | Out-Null
                    }
                    Else { 
                        $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm.Where({ $_ -ne "+$($Pool.Algorithm)" }) | Sort-Object -Unique)
                        $Pool.Reasons = $Pool.Reasons.Add("Algorithm not enabled in $($Pool.Name) pool config") | Out-Null
                    }
                    $Pool.Available = $false
                    $Data += "$($Pool.Algorithm)@$($Pool.Name)"
                }
                $Message = "$($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" }) disabled."
                Write-Message -Level Verbose "Web GUI: $Message"
                $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                $PoolsConfig | Get-SortedObject | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $Variables.PoolsConfigFile -Force
            }
            Else { 
                $Data = "No matching stats found."
            }
            Remove-Variable Algorithms, Message, Pool, PoolNames, Pools, PoolsConfig -ErrorAction Ignore
            Break
        }
        "/functions/algorithm/enable" { 
            # Enable algorithm@pool in poolsconfig.json
            $PoolNames = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Name
            $Algorithms = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Algorithm
            If ($Pools = @($Variables.Pools.Where({ $PoolNames -contains $_.Name -and $Algorithms -contains $_.Algorithm }))) { 
                $PoolsConfig = [System.IO.File]::ReadAllLines($Config.PoolsConfigFile) | ConvertFrom-Json
                ForEach ($Pool in $Pools) { 
                    If ($PoolsConfig.($Pool.Name).Algorithm -like "+*") { 
                        $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm += "+$($Pool.Algorithm)" | Sort-Object -Unique)
                        $Pool.Reasons.Remove("Algorithm not enabled in $($Pool.Name) pool config") | Out-Null
                    }
                    Else { 
                        $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm.Where({ $_ -ne "-$($Pool.Algorithm)" }) | Sort-Object -Unique)
                        $Pool.Reasons.Remove("Algorithm disabled (`-$($Pool.Algorithm)` in $($Pool.Name) pool config)") | Out-Null
                    }
                    If (-not $Pool.Reasons.Count) { 
                        $Pool.Available = $true
                        $Pool.Reasons = [System.Collections.Generic.SortedSet[String]]::New()
                    }
                    $Data += "$($Pool.Algorithm)@$($Pool.Name)"
                }
                $Message = "$($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" }) enabled."
                Write-Message -Level Verbose "Web GUI: $Message"
                $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                $PoolsConfig | Get-SortedObject | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $Variables.PoolsConfigFile -Force
            }
            Else { 
                $Data = "No matching stats found."
            }
            Remove-Variable Algorithms, Message, Pool, Pools, PoolsConfig -ErrorAction Ignore
            Break
        }
        "/functions/api/stop" { 
            Write-Message -Level Verbose "API: API stopped!"
            Return
        }
        "/functions/balancedata/remove" { 
            If ($Parameters.Data) { 
                $BalanceDataEntries = $Variables.BalancesData
                $Variables.BalancesData = @((Compare-Object $Variables.BalancesData @($Parameters.Data | ConvertFrom-Json -ErrorAction Ignore) -PassThru -Property DateTime, Pool, Currency, Wallet).Where({ $_.SideIndicator -eq "<=" }) | Select-Object -ExcludeProperty SideIndicator)
                $Variables.BalancesData | ConvertTo-Json | Out-File ".\Data\BalancesTrackerData.json"
                $RemovedEntriesCount = $BalanceDataEntries.Count - $Variables.BalancesData.Count
                If ($RemovedEntriesCount -gt 0) { 
                    $Message = "$RemovedEntriesCount balance data $(If ($RemovedEntriesCount -eq 1) { "entry" } Else { "entries" }) removed."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = $Message
                }
                Else { 
                    $Data = "No matching entries found."
                }
                Remove-Variable BalanceDataEntries, Message, RemovedEntriesCount -ErrorAction Ignore
                Break
            }
        }
        "/functions/config/device/disable" { 
            ForEach ($Key in $Parameters.Keys) { 
                If ($Values = @(($Parameters.$Key -split ",").Where({ $_ -notin $Config.ExcludeDeviceName }))) { 
                    Try { 
                        $ExcludeDeviceName = $Config.ExcludeDeviceName
                        $Config.ExcludeDeviceName = @((@($Config.ExcludeDeviceName) + $Values) | Sort-Object -Unique)
                        Write-Config -Config $Config
                        $Data = "Device configuration changed`n`nOld values:"
                        $Data += "`nExcludeDeviceName: '[$($ExcludeDeviceName -join ", ")]'"
                        $Data += "`n`nNew values:"
                        $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ", ")]'"
                        $Data += "`n`nConfiguration saved to '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`nIt will become active in the next cycle."
                        $Variables.Devices.Where({ $Values -contains $_.Name }).ForEach(
                            { 
                                $_.State = [DeviceState]::Disabled
                                If ("Benchmarking", "Running", "WarmingUp" -contains $_.SubStatus) { $_.StatusInfo = "$($_.StatusInfo); will get disabled at end of cycle" }
                                Else { 
                                    $_.StatusInfo = "Disabled (ExcludeDeviceName: '$($_.Name)')"
                                    $_.Status = "Idle"
                                }
                            }
                        )
                        Write-Message -Level Verbose "Web GUI: Device$(If ($Values.Count -ne 1) { "s" }) '$($Values -join ", ")' disabled. Configuration file '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))' updated."
                    }
                    Catch { 
                        $Data = "Error saving configuration file '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`n`n[ $($_) ]"
                    }
                }
                Else { 
                    $Data = "No configuration change."
                }
            }
            Remove-Variable ExcludeDeviceName, Key, Values -ErrorAction Ignore
            Break
        }
        "/functions/config/device/enable" { 
            ForEach ($Key in $Parameters.Keys) { 
                If ($Values = @(($Parameters.$Key -split ",").Where({ $Config.ExcludeDeviceName -contains $_ }))) { 
                    Try { 
                        $ExcludeDeviceName = $Config.ExcludeDeviceName
                        $Config.ExcludeDeviceName = @($Config.ExcludeDeviceName.Where({ $_ -notin $Values }) | Sort-Object -Unique)
                        Write-Config -Config $Config
                        $Variables.ConfigurationHasChangedDuringUpdate = $false
                        $Data = "Device configuration changed`n`nOld values:"
                        $Data += "`nExcludeDeviceName: '[$($ExcludeDeviceName -join ", ")]'"
                        $Data += "`n`nNew values:"
                        $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ", " )]'"
                        $Data += "`n`nConfiguration saved to '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`nIt will become active in the next cycle."
                        $Variables.Devices.Where({ $Values -contains $_.Name }).ForEach(
                            { 
                                $_.State = [DeviceState]::Enabled
                                If ($_.StatusInfo -like "* {*@*}; will get enabled at end of cycle") { $_.StatusInfo = $_.StatusInfo -replace "; will get enabled at end of cycle" }
                                Else { $_.Status = $_.StatusInfo = $_.SubStatus = "Idle" }
                            }
                        )
                        Write-Message -Level Verbose "Web GUI: Device$(If ($Values.Count -ne 1) { "s" }) '$($Values -join ", ")' enabled. Configuration file '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))' updated."
                    }
                    Catch { 
                        $Data = "Error saving configuration file '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`n`n[ $($_) ]"
                    }
                }
                Else { 
                    $Data = "No configuration change."
                }
            }
            Remove-Variable ExcludedDeviceName, Key, Values -ErrorAction Ignore
            Break
        }
        "/functions/config/set" { 
            Try { 
                $TempConfig = ($Key | ConvertFrom-Json -AsHashtable)
                Write-Config -Config $TempConfig
                Write-Message -Level Verbose "Web GUI: Configuration saved to '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'. It will become fully active in the next cycle."

                $TempConfig.Keys.ForEach({ $Config.$_ = $TempConfig.$_ })

                $Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }).ForEach(
                    { 
                        If ($Config.ExcludeDeviceName -contains $_.Name) { 
                            $_.State = [DeviceState]::Disabled
                            If ($_.Status -like "Mining *}") { $_.Status = "$($_.Status); will get disabled at end of cycle" }
                        }
                        Else { 
                            $_.State = [DeviceState]::Enabled
                            If ($_.Status -like "*; will get disabled at end of cycle") { $_.Status = $_.Status -replace "; will get disabled at end of cycle" }
                            If ($_.Status -like "Disabled *") { $_.Status = "Idle" }
                        }
                    }
                )
                $Variables.Remove("ConfigurationHasChangedDuringUpdate")
                $Variables.RestartCycle = $true
                $Data = "Configuration saved to '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`nIt will become fully active in the next cycle."
            }
            Catch { 
                $Data = "Error saving configuration file '$($Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`n`n[ $($_) ]"
            }
            Remove-Variable Key, TempConfig -ErrorAction Ignore
            Break
        }
        "/functions/file/edit" { 
            $Data = Edit-File $Parameters.FileName
            If (Test-Path -LiteralPath $Parameters.FileName) { 
                If ($Parameters.FileName -eq $Variables.ConfigFile -or $Parameters.FileName -eq $Variables.PoolsConfigFile) { Read-Config }
            }
            Break
        }
        "/functions/file/showcontent" { 
            $Data = (Get-Content -Path $Parameters.FileName -Raw)
            $ContentType = "text/html"
            Break
        }
        "/functions/getminerdetail" { 
            $Miner = $Variables.Miners.Where({ $_.Info -eq $Key })
            If ($Miner) { 
                $Data = $Miner | ConvertTo-Json -Depth 10
            }
            Else { 
                $Data = "Miner with key '$Key' not found."
            }
            Remove-Variable Miner -ErrorAction Ignore
            Break
        }
        "/functions/log/get" { 
            $Lines = If ([Int]$Parameters.Lines) { [Int]$Parameters.Lines } Else { 100 }
            $Data = "$((Get-Content -Path $Variables.LogFile -Tail $Lines).ForEach({ "$($_)`n" }))"
            Remove-Variable Lines
            Break
        }
        "/functions/mining/getstatus" { 
            If ($Variables.ConfigurationHasChangedDuringUpdate) { 
                $Data = "ConfigurationHasChangedDuringUpdate" | ConvertTo-Json
            }
            Else { 
                $Data = $Variables.NewMiningStatus | ConvertTo-Json
            }
            Break
        }
        "/functions/mining/pause" { 
            If ($Variables.MiningStatus -ne "Paused") { 
                $Variables.NewMiningStatus = "Paused"
                $Data = "Mining is being paused...`n$(If ($Variables.BalancesTrackerPollInterval -gt 0) { If ($Variables.BalancesTrackerRunning) { "Balances tracker running." } Else { "Balances tracker starting..." } })"
                $Variables.SuspendCycle = $false
                $Variables.RestartCycle = $true
            }
            Break
        }
        "/functions/mining/start" { 
            If ($Variables.MiningStatus -ne "Running") { 
                $Variables.NewMiningStatus = "Running"
                $Data = "Mining processes starting...`n$(If ($Variables.BalancesTrackerPollInterval -gt 0) { If ($Variables.BalancesTrackerRunning) { "Balances tracker running." } Else { "Balances tracker starting..." } })"
                $Variables.SuspendCycle = $false
                $Variables.RestartCycle = $true
            }
            Break
        }
        "/functions/mining/stop" { 
            If ($Variables.MiningStatus -ne "Idle") { 
                $Variables.NewMiningStatus = "Idle"
                $Data = "$($Variables.Branding.ProductLabel) is stopping...`n"
                $Variables.SuspendCycle = $false
                $Variables.RestartCycle = $true
            }
            Break
        }
        "/functions/querypoolapi" { 
            If (-not $Config.PoolsConfig.$($Parameters.Pool).BrainConfig.$($Parameters.Type)) { 
                $Data = "No pool configuration data for '/functions/querypoolapi?Pool=$($Parameters.Pool)&Type=$($Parameters.Type)'."
            }
            ElseIf (-not ($Data = (Invoke-RestMethod -Uri $Config.PoolsConfig.$($Parameters.Pool).BrainConfig.$($Parameters.Type) -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec 5) | ConvertTo-Json)) { 
                $Data = "No data for '/functions/querypoolapi?Pool=$($Parameters.Pool)&Type=$($Parameters.Type)'."
            }
            Break
        }
        "/functions/removeorphanedminerstats" { 
            If ($StatNames = Remove-ObsoleteMinerStats) { 
                $Data = $StatNames | ConvertTo-Json
            }
            Else { 
                $Data = "No matching stats found."
            }
            Remove-Variable StatNames -ErrorAction Ignore
            Break
        }
        "/functions/stat/disable" { 
            If ($Parameters.Miners) { 
                If ($Miners = (Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info).Where({ -not $_.Disabled })) { 
                    $Data = @()
                    $Miners.ForEach(
                        { 
                            Set-MinerDisabled $_
                            $Data += $_.Name
                        }
                    )
                    $Message = "Disabled $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                }
                Else { 
                    $Data = "No matching miners found."
                }
                Remove-Variable Miners, Message, Worker -ErrorAction Ignore
                Break
            }
        }
        "/functions/stat/enable" { 
            If ($Parameters.Miners) { 
                If ($Miners = (Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info).Where({ $_.Disabled })) { 
                    $Data = @()
                    $Miners.ForEach(
                        { 
                            Set-MinerEnabled $_
                            $Data += $_.Name
                        }
                    )
                    $Message = "Enabled $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                }
                Else { 
                    $Data = "No matching miners found."
                }
                Remove-Variable Message, Miners, Worker -ErrorAction Ignore
                Break
            }
        }
        "/functions/stat/get" { 
            If ($TempStats = @(If ($null -ne $Parameters.Value) { (Get-Stat).Where({ $_.Name -like "*_$($Parameters.Type)" -and $_.Live -eq $Parameters.Value }) } Else { Get-Stat })) { 
                If ($null -ne $Parameters.Value) { 
                    ($TempStats.Name | Sort-Object).ForEach({ $Data += "$($_ -replace "(_Hashrate|_PowerConsumption)$")`n" })
                    If ($Parameters.Type -eq "Hashrate") { $Data += "`n$($TempStats.Count) stat file$(If ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)H/s hashrate." }
                    ElseIf ($Parameters.Type -eq "PowerConsumption") { $Data += "`n$($TempStats.Count) stat file$(If ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)W power consumption." }
                }
                Else { 
                    $Data = $TempStats | ConvertTo-Json
                }
            }
            Else { 
                $Data = "No matching stats found."
            }
            Remove-Variable TempStats -ErrorAction Ignore
            Break
        }
        "/functions/stat/remove" { 
            If ($Parameters.Pools) { 
                If ($Pools = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Pools | Select-Object) @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Algorithm, Currency, Name) { 
                    $Data = @()
                    ($Pools | Sort-Object -Property Name, Algorithm, Currency).ForEach(
                        { 
                            $StatName = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                            $Data += $StatName

                            Remove-Stat -Name "$($StatName)_Profit"

                            $_.Available = $true
                            $_.Disabled = $false
                            $_.Price = $_.Price_Bias = $_.StablePrice = $_.Accuracy = [Double]::Nan
                            $_.Reasons = [System.Collections.Generic.SortedSet[String]]::New()
                        }
                    )
                    $Message = "Reset pool stats for $($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" })."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                }
                Else { 
                    $Data = "No matching pool stats found."
                }
                Remove-Variable Message, Pools, StatName -ErrorAction Ignore
                Break
            }
            ElseIf ($Parameters.Miners -and $Parameters.Type -eq "Hashrate") { 
                If ($Miners = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info) { 
                    $Data = @()
                    $Miners.ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerReBenchmark $_
                        }
                    )
                    $Message = "Re-benchmark triggered for $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                }
                Else { 
                    $Data = "No matching hashrate stats found."
                }
                Remove-Variable Message, Miners, Worker -ErrorAction Ignore
                Break
            }
            ElseIf ($Parameters.Miners -and $Parameters.Type -eq "PowerConsumption") { 
                If ($Miners = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info) { 
                    $Data = @()
                    $Miners.ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerMeasurePowerConsumption $_
                        }
                    )
                    $Message = "Re-measure power consumption triggered for $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" })."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                }
                Else { 
                    $Data = "No matching power consumption stats found."
                }
                Remove-Variable Message, Miners -ErrorAction Ignore
                Break
            }
            If ($TempStats = @(If ($null -ne $Parameters.Value) { (Get-Stat).Where({ $_.Name -like "*_$($Parameters.Type)" -and $_.Live -eq $Parameters.Value }) } Else { (Get-Stat).Where({ $_.Name -like "*_$($Parameters.Type)" }) })) { 
                $Data = @()
                ($TempStats | Sort-Object -Property Name).ForEach(
                    { 
                        Remove-Stat -Name $_.Name
                        $Data += $_.Name -replace "(_Hashrate|_PowerConsumption)$"
                    }
                )
                If ($Parameters.Type -eq "Hashrate") { $Message = "Reset $($TempStats.Count) stat file$(If ($TempStats.Count -ne 1) { "s" })$(If ($null -ne $Parameters.Value) { " with $($Parameters.Value)H/s hashrate" })." }
                ElseIf ($Parameters.Type -eq "PowerConsumption") { $Message = "Reset $($TempStats.Count) stat file$(If ($TempStats.Count -ne 1) { "s" })$(If ($null -ne $Parameters.Value) { " with $($Parameters.Value)W power consumption" })." }
                ElseIf ($Parameters.Type -eq "Profit") { $Message = "Reset $($TempStats.Count) pool stat file$(If ($TempStats.Count -ne 1) { "s" })." }
                Write-Message -Level Info "Web GUI: $Message"
                $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
            }
            Else { 
                $Data = "No matching stats found."
            }
            Remove-Variable Message, TempStats -ErrorAction Ignore
            Break
        }
        "/functions/stat/set" { 
            If ($Parameters.Miners) { 
                $Data = @()
                If ($Parameters.Type -eq "Hashrate" -and $Parameters.Value -eq 0) { 
                    If ($Miners = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info) { 
                        $Miners.ForEach(
                            { 
                                Set-MinerFailed $_
                                $Data += $_.Name
                            }
                        )
                        $Message = "Marked $($Data.Count) miner$(If ($Data.Count -ne 1) { "s" }) as failed."
                        Write-Message -Level Verbose "Web GUI: $Message"
                        $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message" 
                    }
                    Else { 
                        $Data = "No matching miners found."
                    }
                    Remove-Variable Algorithm, Message, Miners, StatName -ErrorAction Ignore
                    Break
                }
            }
        }
        "/functions/switchinglog/clear" { 
            Get-ChildItem -Path ".\Logs\SwitchingLog.csv" -File | Remove-Item -Force
            Write-Message -Level Verbose "Web GUI: Switching log '.\Logs\SwitchingLog.csv' cleared."
            $Data = "Switching log '.\Logs\SwitchingLog.csv' cleared."
            Break
        }
        "/functions/variables/get" { 
            If ($Key) { 
                $Data = $Variables.($Key -replace "\\|/", "." -split "\."[-1]) | Get-SortedObject | ConvertTo-Json -Depth 10
            }
            Else { 
                $Data = $Variables.psBase.Keys | Sort-Object | ConvertTo-Json -Depth 1
            }
            Break
        }
        "/functions/watchdogtimers/remove" { 
            If ($Parameters.Miners -or $Parameters.Pools) { 
                $Data = @()
                ForEach ($Miner in (Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Name)) { 
                    If ($Variables.WatchdogTimers.Where({ $_.MinerName -eq $Miner.Name })) { 
                        # Update miner
                        $Data += $Miner.Name
                        $Miner.Reasons.Where({ $_ -like "Miner suspended by watchdog *" }).ForEach({ $Miner.Reasons.Remove($_) | Out-Null })
                        If (-not $Miner.Reasons.Count) { $Miner.Available = $true }

                        # Remove Watchdog timers
                        $Variables.WatchdogTimers = $Variables.WatchdogTimers.Where({ $_.MinerName -ne $Miner.Name })
                    }
                }
                Remove-Variable Miner

                ForEach ($Pool in (Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Pools | Select-Object) @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Key)) { 
                    # Update pool
                    If ($Variables.Pools.Where({ $_.Key -eq $Pool.Key })) { 
                        $Data += "$($Pool.Key) [$($Pool.Region)]"
                        $Pool.Reasons.Where({ $_ -like "Miner suspended by watchdog *" }).ForEach({ $Pool.Reasons.Remove($_) | Out-Null })
                        If (-not $Pool.Reasons.Count) { $Pool.Available = $true }

                        # Remove Watchdog timers
                        $Variables.WatchdogTimers = $Variables.WatchdogTimers.Where({ $_.Key -ne $Pool.Key })
                    }
                }
                Remove-Variable Pool
                If ($Data.Count) {
                    $Message = "$($Data.Count) watchdog $(If ($Data.Count -eq 1) { "timer" } Else { "timers" }) removed."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                }
                Else { 
                    $Data = "No matching watchdog timer found."
                }
                Remove-Variable Message, Miner, Pool -ErrorAction Ignore
            }
            Else { 
                $Variables.WatchdogTimers = [System.Collections.Generic.List[PSCustomObject]]::new()
                Foreach ($Miner in $Variables.Miners) { 
                    $Miner.Reasons.Where({ $_ -like "Miner suspended by watchdog *" }).ForEach({ $Miner.Reasons.Remove($_) | Out-Null })
                    If (-not $Miner.Reasons.Count) { $_.Available = $true }
                }
                Remove-Variable Miner

                ForEach ($Pool in $Variables.Pools.ForEach) { 
                    $Pool.Reasons.Where({ $_ -like "Pool suspended by watchdog *" }).ForEach({ $Pool.Reasons.Remove($_) | Out-Null })
                    If (-not $Pool.Reasons.Count) { $Pool.Available = $true }
                }
                Remove-Variable Pool

                Write-Message -Level Verbose "Web GUI: All watchdog timers removed."
                $Data = "All watchdog timers removed.`nWatchdog timers will be recreated in the next cycle."
            }
            Break
        }
        "/algorithms" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.Algorithms | Select-Object)
            Break
        }
        "/algorithms/lastused" { 
            $Data = ConvertTo-Json -Depth 10 $Variables.AlgorithmsLastUsed
            Break
        }
        "/allcurrencies" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.AllCurrencies)
            Break
        }
        "/apiversion" { 
            $Data = $Variables.APIversion
            Break
        }
        "/balances" { 
            $Data = ConvertTo-Json -Depth 10 ($Variables.Balances | Sort-Object -Property DateTime -Bottom 10000 | Select-Object)
            Break
        }
        "/balancedata" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.BalancesData | Sort-Object -Property DateTime -Descending)
            Break
        }
        "/btc" { 
            $Data = $Variables.Rates.BTC.($Config.FIATcurrency)
            Break
        }
        "/balancescurrencies" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.BalancesCurrencies)
            Break
        }
        "/braindata" { 
            $Data = ConvertTo-Json -Depth 2 ($Variables.BrainData | Get-SortedObject)
            Break
        }
        "/coinnames" { 
            $Data = [System.IO.File]::ReadAllLines(".\Data\CoinNames.json")
            Break
        }
        "/config" { 
            $Data = ConvertTo-Json -Depth 10 ([System.IO.File]::ReadAllLines($Variables.ConfigFile) | ConvertFrom-Json -Depth 10 | Get-SortedObject)
            If (-not ($Data | ConvertFrom-Json).ConfigFileVersion) { 
                $Data = ConvertTo-Json -Depth 10 ($Config | Select-Object -ExcludeProperty PoolsConfig)
            }
            Break
        }
        "/configfile" { 
            $Data = $Variables.ConfigFile.Replace("$(Convert-Path ".\")\", ".\")
            Break
        }
        "/configrunning" { 
            $Data = ConvertTo-Json -Depth 10 ($Config | Get-SortedObject)
            Break
        }
        "/cpufeatures" { 
            $Data = ConvertTo-Json $Variables.CPUfeatures
            Break
        }
        "/currency" { 
            $Data = $Config.FIATcurrency
            Break
        }
        "/currencyalgorithm" { 
            $Data = [System.IO.File]::ReadAllLines("$PWD\Data\CurrencyAlgorithm.json")
            Break
        }
        "/dagdata" { 
            $Data = ConvertTo-Json -Depth 10 ($Variables.DAGdata | Get-SortedObject)
            Break
        }
        "/devices" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.Devices | Sort-Object -Property Name)
            Break
        }
        "/devices/enabled" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.Devices.Where({ $_.State -eq "Enabled" }) | Sort-Object -Property Name)
            Break
        }
        "/devices/disabled" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.Devices.Where({ $_.State -eq "Disabled" }) | Sort-Object -Property Name)
            Break
        }
        "/devices/unsupported" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.Devices.Where({ $_.State -eq "Unsupported" }) | Sort-Object -Property Name)
            Break
        }
        "/donationdata" { 
            $Data = ConvertTo-Json $Variables.DonationData
            Break
        }
        "/donationlog" { 
            $Data = ConvertTo-Json -Depth 10 @([System.IO.File]::ReadAllLines("$PWD\Logs\DonationLog.csv") | ConvertFrom-Csv -ErrorAction Ignore)
            Break
        }
        "/driverversion" { 
            $Data = ConvertTo-Json -Depth 10 ($Variables.DriverVersion | Select-Object)
            Break
        }
        "/earningschartdata" { 
            $Data = ConvertTo-Json $Variables.EarningsChartData
            Break
        }
        "/equihashcoinpers" { 
            $Data = [System.IO.File]::ReadAllLines("$PWD\Data\EquihashCoinPers.json")
            Break
        }
        "/extracurrencies" { 
            $Data = ConvertTo-Json -Depth 10 $Config.ExtraCurrencies
            Break
        }
        "/fiatcurrencies" { 
            $Data = ConvertTo-Json -Depth 10 ($Variables.FIATcurrencies | Select-Object)
            Break
        }
        "/miners" { 
            $Bias = If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { "Profit_Bias" } Else { "Earnings_Bias" }
            $Data = ConvertTo-Json -Depth 5 @($Variables.Miners.PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true })
            Remove-Variable Bias
            Break
        }
        "/miners/available" { 
            $Bias = If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { "Profit_Bias" } Else { "Earnings_Bias" }
            $Data = ConvertTo-Json -Depth 5 @($Variables.Miners.Where({ $_.Available }).PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true })
            Remove-Variable Bias
            Break
        }
        "/miners/bestperdevice" { 
            $Data = ConvertTo-Json -Depth 5 @($Variables.MinersBestPerDevice.PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object { $_.BaseName_Version_Device -replace ".+-" })
            Break
        }
        "/miners/best" { 
            $Bias = If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { "Profit_Bias" } Else { "Earnings_Bias" }
            $Data = ConvertTo-Json -Depth 5 @($Variables.MinersBest.PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true })
            Remove-Variable Bias
            Break
        }
        "/miners/disabled" { 
            $Data = ConvertTo-Json -Depth 5 @($Variables.Miners.Where({ $_.Status -eq [MinerStatus]::Disabled }).PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }, EndTime)
            Break
        }
        "/miners/failed" { 
            $Data = ConvertTo-Json -Depth 5 @($Variables.Miners.Where({ $_.Status -eq [MinerStatus]::Failed }).PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }, EndTime)
            Break
        }
        "/miners/launched" { 
            $Data = ConvertTo-Json -Depth 5 @($Variables.MinersBest.PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object -Property Info)
            Break
        }
        "/miners/missingbinary" { 
            $Data = ConvertTo-Json -Depth 5 @($Variables.MinersMissingBinary.PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object -Property Info)
            Break
        }
        "/miners/missingfirewallrule" { 
            $Data = ConvertTo-Json -Depth 5 @($Variables.MinersMissingFirewallRule.PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object -Property Info)
            Break
        }
        "/miners/missingprerequisite" { 
            $Data = ConvertTo-Json -Depth 5 @($Variables.MinersMissingPrerequisite.PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object -Property Info)
            Break
        }
        "/miners/optimal" { 
            $Bias = If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { "Profit_Bias" } Else { "Earnings_Bias" }
            $Data = ConvertTo-Json -Depth 5 @($Variables.MinersOptimal.PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true })
            Remove-Variable Bias
            Break
        }
        "/miners/running" { 
            $Data = ConvertTo-Json -Depth 5 @($Variables.Miners.Where({ $_.Status -eq [MinerStatus]::Running }).PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object { $_.BaseName_Version_Device -replace ".+-" })
            Break
        }
        "/miners/unavailable" { 
            $Data = ConvertTo-Json -Depth 5 @($Variables.Miners.Where({ $_.Available -ne $true }).PsObject.Copy().ForEach({ If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }, Name, Algorithm)
            Break
        }
        "/miningpowercost" { 
            $Data = $Variables.MiningPowerCost
            Break
        }
        "/miningearnings" { 
            $Data = $Variables.MiningEarnings
            Break
        }
        "/miningprofit" { 
            $Data = $Variables.MiningProfit
            Break
        }
        "/poolname" { 
            $Data = ConvertTo-Json -Depth 10 $Config.PoolName
            Break
        }
        "/pooldata" { 
            $Data = ConvertTo-Json -Depth 10 $Variables.PoolData
            Break
        }
        "/poolsconfig" { 
            $Data = ConvertTo-Json -Depth 10 ($Config.PoolsConfig | Select-Object)
            Break
        }
        "/poolsconfigfile" { 
            $Data = $Config.PoolsConfigFile.Replace("$(Convert-Path ".\")\", ".\")
            Break
        }
        "/pools" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Sort-Object -Property Algorithm, Name, Region)
            Break
        }
        "/pools/added" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsAdded | Sort-Object -Property Algorithm, Name, Region)
            Break
        }
        "/pools/available" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.Pools.Where({ $_.Available }) | Sort-Object -Property Algorithm, Name, Region)
            Break
        }
        "/pools/best" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsBest | Sort-Object -Property Algorithm, Name, Region)
            Break
        }
        "/pools/expired" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsExpired | Sort-Object -Property Algorithm, Name, Region)
            Break
        }
        "/pools/new" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsNew | Sort-Object -Property Algorithm, Name, Region)
            Break
        }
        "/pools/minersprimaryalgorithm" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.MinerPools[0] | Select-Object)
            Break
        }
        "/pools/minerssecondaryalgorithm" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.MinerPools[1] | Select-Object)
            Break
        }
        "/pools/lastearnings" { 
            $Data = ConvertTo-Json -Depth 10 $Variables.PoolsLastEarnings
            Break
        }
        "/pools/lastused" { 
            $Data = ConvertTo-Json -Depth 10 $Variables.PoolsLastUsed
            Break
        }
        "/pools/unavailable" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.Pools.Where({ -not $_.Available }) | Sort-Object -Property Algorithm, Name, Region)
            Break
        }
        "/pools/updated" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsUpdated | Sort-Object -Property Algorithm, Name, Region)
            Break
        }
        "/poolreasons" { 
            $Data = ConvertTo-Json -Depth 10 ($Variables.Pools.Where({ -not $_.Available }).Reasons | Sort-Object -Unique)
            Break
        }
        "/poolvariants" { 
            $Data = ConvertTo-Json -Depth 10 $Variables.PoolVariants
            Break
        }
        "/rates" { 
            $Data = ConvertTo-Json -Depth 10 ($Variables.Rates | Select-Object)
            Break
        }
        "/refreshtimestamp" { 
            $Data = $Variables.RefreshTimestamp | ConvertTo-Json
            Break
        }
        "/regions" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.Regions[0] | Sort-Object)
            Break
        }
        "/regionsdata" { 
            $Data = ConvertTo-Json -Depth 10 $Variables.Regions
            Break
        }
        "/stats" { 
            $Data = ConvertTo-Json -Depth 10 ($Stats | Select-Object)
            Break
        }
        "/summarytext" { 
            $Data = ConvertTo-Json -Depth 10 @((($Variables.Summary -replace " / ", "/" -replace "&ensp;", " " -replace "   ", "  ") -split "<br>").trim())
            Break
        }
        "/summary" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.Summary | Select-Object)
            Break
        }
        "/switchinglog" { 
            $Data = ConvertTo-Json -Depth 10 @([System.IO.File]::ReadAllLines("$PWD\Logs\SwitchingLog.csv") | ConvertFrom-Csv | Select-Object -Last 1000 | Sort-Object -Property DateTime -Descending)
            Break
        }
        "/unprofitablealgorithms" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.UnprofitableAlgorithms | Select-Object)
            Break
        }
        "/version" { 
            $Data = ConvertTo-Json @("$($Variables.Branding.ProductLabel) Version: $($Variables.Branding.Version)", "API Version: $($Variables.APIversion)", "PWSH Version: $($PSVersionTable.PSVersion.ToString())")
            Break
        }
        "/watchdogtimers" { 
            $Data = ConvertTo-Json -Depth 10 @($Variables.WatchdogTimers | Select-Object)
            Break
        }
        "/wallets" { 
            $Data = ConvertTo-Json -Depth 10 ($Config.Wallets | Select-Object)
            Break
        }
        "/watchdogexpiration" { 
            $Data = $Variables.WatchdogReset
            Break
        }
        "/workers" { 
            If ($Config.ShowWorkerStatus -and $Config.MonitoringUser -and $Config.MonitoringServer -and $Variables.WorkersLastUpdated -lt [DateTime]::Now.AddSeconds(-30)) { 
                Read-MonitoringData
            }
            If ($Variables.Workers) { 
                $Workers = [System.Collections.ArrayList]@(
                    $Variables.Workers | Select-Object @(
                        @{ Name = "Algorithm"; Expression = { $_.data.ForEach({ $_.Algorithm -split "," -join " & " }) -join "<br>" } },
                        @{ Name = "Benchmark Hashrate"; Expression = { $_.data.ForEach({ ($_.EstimatedSpeed.ForEach({ If ([Double]$_ -gt 0) { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " } Else { "-" } })) -join " & " }) -join "<br>" } },
                        @{ Name = "Currency"; Expression = { $_.Data.Currency | Select-Object -Unique } },
                        @{ Name = "EstimatedEarnings"; Expression = { [Decimal]((($_.Data.Earnings | Measure-Object -Sum).Sum) * $Variables.Rates.BTC.($_.Data.Currency | Select-Object -Unique)) } },
                        @{ Name = "EstimatedProfit"; Expression = { [Decimal]($_.Profit * $Variables.Rates.BTC.($_.Data.Currency | Select-Object -Unique)) } },
                        @{ Name = "LastSeen"; Expression = { $_.date } },
                        @{ Name = "Live Hashrate"; Expression = { $_.data.ForEach({ ($_.CurrentSpeed.ForEach({ If ([Double]$_ -gt 0) { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " } Else { "-" } })) -join " & " }) -join "<br>" } },
                        @{ Name = "Miner"; Expression = { $_.data.name -join "<br/>"} },
                        @{ Name = "Pool"; Expression = { $_.data.ForEach({ $_.Pool -split "," -join " & " }) -join "<br>" } },
                        @{ Name = "Status"; Expression = { $_.status } },
                        @{ Name = "Version"; Expression = { $_.version } },
                        @{ Name = "Worker"; Expression = { $_.worker } }
                    ) | Sort-Object -Property "Worker"
                )
                $Data = ConvertTo-Json @($Workers | Select-Object) -Depth 4
            }
            Else { 
                $Data = "No worker data from reporting server"
            }
            Break
        }
        Default { 
            # Set index page
            If ($Path -eq "/") { $Path = "/index.html" }

            # Check if there is a file with the requested path
            $Filename = "$BasePath$Path"
            If (Test-Path -LiteralPath $Filename -PathType Leaf) { 
                # If the file is a PowerShell script, execute it and return the output. A $Parameters parameter is sent built from the query string
                # Otherwise, just return the contents of the file
                $File = Get-ChildItem $Filename -File

                If ($File.Extension -eq ".ps1") { 
                    $Data = & $File.FullName -Parameters $Parameters
                }
                Else { 
                    $Data = Get-Content $Filename -Raw

                    # Process server side includes for html files
                    # Includes are in the traditional '<!-- #include file="/path/filename.html" -->' format used by many web servers
                    If ($File.Extension -eq ".html") { 
                        $IncludeRegex = [regex]'<!-- *#include *file="(.*)" *-->'
                        $IncludeRegex.Matches($Data).ForEach(
                            { 
                                $IncludeFile = $BasePath + "/" + $_.Groups[1].Value
                                If (Test-Path -LiteralPath $IncludeFile -PathType Leaf) { 
                                    $IncludeData = Get-Content $IncludeFile -Raw
                                    $Data = $Data -replace $_.Value, $IncludeData
                                }
                            }
                        )
                    }
                }

                # Set content type based on file extension
                If ($MIMEtypes.ContainsKey($File.Extension)) { 
                    $ContentType = $MIMEtypes[$File.Extension]
                }
                Else { 
                    # If it's an unrecognized file type, prompt for download
                    $ContentType = "application/octet-stream"
                }
            }
            Else { 
                $StatusCode = 404
                $ContentType = "text/html"
                $Data = "URI '$Path' is not a valid resource."
            }
            Remove-Variable File, Filename, IncludeData, IncludeFile, IncludeRegex, Key -ErrorAction Ignore
        }
    }

    # If $Data is null, the API will just return whatever data was in the previous request. Instead, show an error
    # This happens if the script just started and hasn't filled all the properties in yet.
    If ($null -eq $Data) { 
        $Data = @{ "Error" = "API data not available" } | ConvertTo-Json
    }

    # Send the response
    $Response.Headers.Add("Content-Type", $ContentType)
    $Response.StatusCode = $StatusCode
    $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes($Data)
    $Response.ContentLength64 = $ResponseBuffer.Length
    # If ($Config.APIlogfile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Response: $Data" | Out-File $Config.APIlogfile -Append -ErrorAction Ignore }
    $Response.OutputStream.Write($ResponseBuffer, 0, $ResponseBuffer.Length)
    $Response.Close()

    Remove-Variable ContentType, Data, Parameters, Response, ResponseBuffer, StatusCode -ErrorAction Ignore

    If ($GCstopWatch.Elapsed.TotalMinutes -gt 10) { 
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
        $GCstopWatch.Restart()
    }
}

# Only gets here if something is wrong and the server couldn't start or stops listening
$Server.Stop()
$Server.Close()
$Server.Dispose()