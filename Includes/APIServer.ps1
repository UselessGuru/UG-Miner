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
Version:        6.7.2
Version date:   2025/11/29
#>

using module .\Include.psm1

$APIversion = "6.0.20"

(Get-Process -Id $PID).PriorityClass = "Normal"

# Set the starting directory
$BasePath = "$PWD\web"

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
$Server.Prefixes.Add("http://localhost:$($Session.Config.APIport)/")
$Server.Start()
$Session.APIversion = $APIversion
$Session.APIserver = $Server

$GCstopWatch = [System.Diagnostics.StopWatch]::new()
$GCstopWatch.Start()

while ($Session.APIversion -and $Server.IsListening) { 
    $Context = $Server.GetContext()
    $Request = $Context.Request

    # Determine the requested resource and parse query strings
    $Path = $Request.Url.LocalPath

    if ($Request.HttpMethod -eq "GET") { 
        # Parse any parameters in the URL - $Request.Url.Query looks like "+ ?a=b&c=d&message=Hello%20world"
        # Decode any url escaped characters in the key and value
        $Parameters = @{ }
        ($Request.Url.Query -replace "\?" -split "&").foreach(
            { 
                $Key, $Value = $_ -split "="
                # Decode any url escaped characters in the key and value
                $Key = [System.Web.HttpUtility]::UrlDecode($Key)
                $Value = [System.Web.HttpUtility]::UrlDecode($Value)
                if ($Key -and $Value) { $Parameters.$Key = $Value }
            }
        )
        if ($Session.Config.APIlogfile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): $($Request.Url)" | Out-File $Session.Config.APIlogfile -Append -ErrorAction Ignore }
    }
    elseif ($Request.HttpMethod -eq "POST") { 
        $Length = $Request.contentlength64
        $Buffer = New-Object "byte[]" $Length

        [Void]$Request.inputstream.read($Buffer, 0, $Length)
        $Body = [Text.Encoding]::ascii.getstring($Buffer)

        if ($Session.Config.APIlogfile -and $Session.Config.LogLevel -contains "Debug") { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): $($Request.Url) POST:$Body" | Out-File $Session.Config.APIlogfile -Append -ErrorAction Ignore }

        $Parameters = @{ }
        ($Body -split "&").foreach(
            { 
                $Key, $Value = $_ -split "="
                # Decode any url escaped characters in the key and value
                $Key = [System.Web.HttpUtility]::UrDecode($Key)
                $Value = [System.Web.HttpUtility]::UrlDecode($Value)
                if ($Key -and $Value) { $Parameters.$Key = $Value }
            }
        )
    }
    Remove-Variable Buffer, Body, Length, Request, Value -ErrorAction Ignore

    # Create a new response and the defaults for associated settings
    $Response = $Context.Response
    $ContentType = "application/json"
    $StatusCode = 200
    $Data = ""

    # Set the proper content type, status code and data for each resource
    switch ($Path) { 
        "/functions/algorithm/disable" { 
            # Disable algorithm@pool in poolsconfig.json
            $PoolNames = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Name
            $Algorithms = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Algorithm
            if ($Pools = @($Session.Pools.where({ $PoolNames -contains $_.Name -and $Algorithms -contains $_.Algorithm }))) { 
                $Config.Pools = [System.IO.File]::ReadAllLines($Session.PoolsConfigFile) | ConvertFrom-Json
                foreach ($Pool in $Pools) { 
                    if ($PoolsConfig.($Pool.Name).Algorithm -like "-*") { 
                        $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm += "-$($Pool.Algorithm)") | Sort-Object -Unique
                        $Pool.Reasons = $Pool.Reasons.Add("Algorithm disabled (`-$($Pool.Algorithm)` in $($Pool.Name) pool config)") | Out-Null
                    }
                    else { 
                        $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm.where({ $_ -ne "+$($Pool.Algorithm)" }) | Sort-Object -Unique)
                        $Pool.Reasons = $Pool.Reasons.Add("Algorithm not enabled in $($Pool.Name) pool config") | Out-Null
                    }
                    $Pool.Available = $false
                    $Data += "$($Pool.Algorithm)@$($Pool.Name)"
                }
                $Message = "$($Pools.Count) $(if ($Pools.Count -eq 1) { "pool" } Else { "pools" }) disabled."
                Write-Message -Level Verbose "Web GUI: $Message"
                $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"

                # Get mutex. Mutexes are shared across all threads and processes.
                # This lets us ensure only one thread is trying to write to the file at a time.
                $Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_PoolsConfigFile")

                # Attempt to aquire mutex, waiting up to 1 second if necessary
                if ($Mutex.WaitOne(1000)) { 
                    $Config.Pools | Get-SortedObject | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $Session.PoolsConfigFile -Force
                    $Mutex.ReleaseMutex()
                }
                Remove-Variable Mutex
            }
            else { 
                $Data = "No matching stats found."
            }
            Remove-Variable Algorithms, Message, Pool, PoolNames, Pools, Config.Pools -ErrorAction Ignore
            break
        }
        "/functions/algorithm/enable" { 
            # Enable algorithm@pool in poolsconfig.json
            $PoolNames = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Name
            $Algorithms = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Algorithm
            if ($Pools = @($Session.Pools.where({ $PoolNames -contains $_.Name -and $Algorithms -contains $_.Algorithm }))) { 
                $Config.Pools = [System.IO.File]::ReadAllLines($Session.PoolsConfigFile) | ConvertFrom-Json
                foreach ($Pool in $Pools) { 
                    if ($PoolsConfig.($Pool.Name).Algorithm -like "+*") { 
                        $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm += "+$($Pool.Algorithm)" | Sort-Object -Unique)
                        $Pool.Reasons.Remove("Algorithm not enabled in $($Pool.Name) pool config") | Out-Null
                    }
                    else { 
                        $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm.where({ $_ -ne "-$($Pool.Algorithm)" }) | Sort-Object -Unique)
                        $Pool.Reasons.Remove("Algorithm disabled (`-$($Pool.Algorithm)` in $($Pool.Name) pool config)") | Out-Null
                    }
                    if (-not $Pool.Reasons.Count) { 
                        $Pool.Available = $true
                        $Pool.Reasons = [System.Collections.Generic.SortedSet[String]]::new()
                    }
                    $Data += "$($Pool.Algorithm)@$($Pool.Name)"
                }
                $Message = "$($Pools.Count) $(if ($Pools.Count -eq 1) { "pool" } Else { "pools" }) enabled."
                Write-Message -Level Verbose "Web GUI: $Message"
                $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"

                # Get mutex. Mutexes are shared across all threads and processes.
                # This lets us ensure only one thread is trying to write to the file at a time.
                $Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_PoolsConfigFile")

                # Attempt to aquire mutex, waiting up to 1 second if necessary
                if ($Mutex.WaitOne(1000)) { 
                    $Config.Pools | Get-SortedObject | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $Session.PoolsConfigFile -Force
                    $Mutex.ReleaseMutex()
                }
                Remove-Variable Mutex
            }
            else { 
                $Data = "No matching stats found."
            }
            Remove-Variable Algorithms, Message, Pool, PoolNames, Pools, Config.Pools -ErrorAction Ignore
            break
        }
        "/functions/api/stop" { 
            Write-Message -Level Verbose "API: API stopped!"
            return
        }
        "/functions/balancedata/remove" { 
            if ($Parameters.Data) { 
                $BalanceDataEntries = $Session.BalancesData
                $Session.BalancesData = @((Compare-Object $Session.BalancesData @($Parameters.Data | ConvertFrom-Json -ErrorAction Ignore) -PassThru -Property DateTime, Pool, Currency, Wallet).where({ $_.SideIndicator -eq "<=" }) | Select-Object -ExcludeProperty SideIndicator)

                # Get mutex. Mutexes are shared across all threads and processes.
                # This lets us ensure only one thread is trying to write to the file at a time.
                $Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_BalancesData")

                # Attempt to aquire mutex, waiting up to 1 second if necessary
                if ($Mutex.WaitOne(1000)) { 
                    $Session.BalancesData | ConvertTo-Json | Out-File ".\Data\BalancesTrackerData.json"
                    $Mutex.ReleaseMutex()
                }
                Remove-Variable Mutex

                $RemovedEntriesCount = $BalanceDataEntries.Count - $Session.BalancesData.Count
                if ($RemovedEntriesCount -gt 0) { 
                    $Message = "$RemovedEntriesCount balance data $(if ($RemovedEntriesCount -eq 1) { "entry" } Else { "entries" }) removed."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = $Message
                }
                else { 
                    $Data = "No matching entries found."
                }
                Remove-Variable BalanceDataEntries, Message, RemovedEntriesCount -ErrorAction Ignore
                break
            }
        }
        "/functions/config/device/disable" { 
            foreach ($Key in $Parameters.Keys) { 
                if ($Values = @(($Parameters.$Key -split ",").where({ $_ -notin $Session.Config.ExcludeDeviceName }))) { 
                    try { 
                        $ExcludeDeviceName = $Session.Config.ExcludeDeviceName
                        $Session.Config.ExcludeDeviceName = @((@($Session.Config.ExcludeDeviceName) + $Values) | Sort-Object -Unique)
                        Write-Configuration -Config $Session.Config
                        $Data = "Device configuration changed`n`nOld values:"
                        $Data += "`nExcludeDeviceName: '[$($ExcludeDeviceName -join ", ")]'"
                        $Data += "`n`nNew values:"
                        $Data += "`nExcludeDeviceName: '[$($Session.Config."ExcludeDeviceName" -join ", ")]'"
                        $Data += "`n`nConfiguration saved to '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`nIt will become active in the next cycle."
                        $Session.Devices.where({ $Values -contains $_.Name }).foreach(
                            { 
                                $_.State = [DeviceState]::Disabled
                                if ("Benchmarking", "Running", "WarmingUp" -contains $_.SubStatus) { $_.StatusInfo = "$($_.StatusInfo); will get disabled at end of cycle" }
                                else { 
                                    $_.StatusInfo = "Disabled (ExcludeDeviceName: '$($_.Name)')"
                                    $_.Status = "Idle"
                                }
                            }
                        )
                        Write-Message -Level Verbose "Web GUI: Device$(if ($Values.Count -ne 1) { "s" }) $($Values -join ", " -replace ",([^,]*)$", " &`$1") marked as disabled. Configuration saved to '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'. It will become active in the next cycle."
                    }
                    catch { 
                        $Data = "Error saving configuration file '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`n`n[ $($_) ]"
                    }
                }
                else { 
                    $Data = "No configuration change."
                }
            }
            Remove-Variable ExcludeDeviceName, Key, Values -ErrorAction Ignore
            break
        }
        "/functions/config/device/enable" { 
            foreach ($Key in $Parameters.Keys) { 
                if ($Values = @(($Parameters.$Key -split ",").where({ $Session.Config.ExcludeDeviceName -contains $_ }))) { 
                    try { 
                        $ExcludeDeviceName = $Session.Config.ExcludeDeviceName
                        $Session.Config.ExcludeDeviceName = @($Session.Config.ExcludeDeviceName.where({ $_ -notin $Values }) | Sort-Object -Unique)
                        Write-Configuration -Config $Session.Config
                        $Session.ConfigurationHasChangedDuringUpdate = $false
                        $Data = "Device configuration changed`n`nOld values:"
                        $Data += "`nExcludeDeviceName: '[$($ExcludeDeviceName -join ", ")]'"
                        $Data += "`n`nNew values:"
                        $Data += "`nExcludeDeviceName: '[$($Session.Config."ExcludeDeviceName" -join ", " )]'"
                        $Data += "`n`nConfiguration saved to '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`nIt will become active in the next cycle."
                        $Session.Devices.where({ $Values -contains $_.Name }).foreach(
                            { 
                                $_.State = [DeviceState]::Enabled
                                if ($_.StatusInfo -like "* {*@*}; will get enabled at end of cycle") { $_.StatusInfo = $_.StatusInfo -replace "; will get enabled at end of cycle" }
                                else { $_.Status = $_.StatusInfo = $_.SubStatus = "Idle" }
                            }
                        )
                        Write-Message -Level Verbose "Web GUI: Device$(if ($Values.Count -ne 1) { "s" }) $($Values -join ", " -replace ",([^,]*)$", " &`$1") marked as enabled. Configuration saved to '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'. It will become fully active in the next cycle."
                    }
                    catch { 
                        $Data = "Error saving configuration file '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`n`n[ $($_) ]"
                    }
                }
                else { 
                    $Data = "No configuration change."
                }
            }
            Remove-Variable ExcludedDeviceName, Key, Values -ErrorAction Ignore
            break
        }
        "/functions/config/set" { 
            try { 
                $TempConfig = ($Key | ConvertFrom-Json -AsHashtable)
                Write-Configuration -Config $TempConfig
                Write-Message -Level Verbose "Web GUI: Configuration saved to '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'. It will become fully active in the next cycle."
                $TempConfig.Keys.ForEach({ $Config.$_ = $TempConfig.$_ })

                $Session.Devices.where({ $_.State -ne [DeviceState]::Unsupported }).foreach(
                    { 
                        if ($Session.Config.ExcludeDeviceName -contains $_.Name) { 
                            $_.State = [DeviceState]::Disabled
                            if ($_.Status -like "Mining *}") { $_.Status = "$($_.Status); will get disabled at end of cycle" }
                        }
                        else { 
                            $_.State = [DeviceState]::Enabled
                            if ($_.Status -like "*; will get disabled at end of cycle") { $_.Status = $_.Status -replace "; will get disabled at end of cycle" }
                        }
                    }
                )
                $Session.Remove("ConfigurationHasChangedDuringUpdate")
                $Session.RestartCycle = $true

                $Data = "Configuration saved to '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`nIt will become active in the next cycle."
            }
            catch { 
                $Data = "Error saving configuration file '$($Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\"))'.`n`n[ $($_) ]"
            }
            Remove-Variable Key, TempConfig -ErrorAction Ignore
            break
        }
        "/functions/file/edit" { 
            $Data = Edit-File $Parameters.FileName
            if (Test-Path -LiteralPath $Parameters.FileName) { 
                if ($Parameters.FileName -eq $Session.ConfigFile -or $Parameters.FileName -eq $Session.PoolsConfigFile) { Read-ConfigFiles }
            }
            break
        }
        "/functions/file/showcontent" { 
            $Data = (Get-Content -Path $Parameters.FileName -Raw)
            $ContentType = "text/html"
            break
        }
        "/functions/getminerdetail" { 
            $Miner = $Session.Miners.where({ $_.Info -eq $Key })
            if ($Miner) { 
                $Data = $Miner | ConvertTo-Json -Depth 10
            }
            else { 
                $Data = "Miner with key '$Key' not found."
            }
            Remove-Variable Miner -ErrorAction Ignore
            break
        }
        "/functions/log/get" { 
            $Lines = if ([Int]$Parameters.Lines) { [Int]$Parameters.Lines } else { 100 }
            $Data = "$((Get-Content -Path $Session.LogFile -Tail $Lines).foreach({ "$($_)`n" }))"
            Remove-Variable Lines
            break
        }
        "/functions/mining/getstatus" { 
            if ($Session.ConfigurationHasChangedDuringUpdate) { 
                $Data = "ConfigurationHasChangedDuringUpdate" | ConvertTo-Json
            }
            else { 
                $Data = $Session.NewMiningStatus | ConvertTo-Json
            }
            break
        }
        "/functions/mining/pause" { 
            if ($Session.MiningStatus -ne "Paused") { 
                $Session.NewMiningStatus = "Paused"
                $Data = "Mining is being paused...`n$(if ($Session.BalancesTrackerPollInterval -gt 0) { If ($Session.BalancesTrackerRunning) { "Balances tracker running." } Else { "Balances tracker starting..." } })"
                $Session.SuspendCycle = $false
                $Session.RestartCycle = $true
            }
            break
        }
        "/functions/mining/start" { 
            if ($Session.MiningStatus -ne "Running") { 
                $Session.NewMiningStatus = "Running"
                $Data = "Mining processes starting...`n$(if ($Session.BalancesTrackerPollInterval -gt 0) { If ($Session.BalancesTrackerRunning) { "Balances tracker running." } Else { "Balances tracker starting..." } })"
                $Session.SuspendCycle = $false
                $Session.RestartCycle = $true
            }
            break
        }
        "/functions/mining/stop" { 
            if ($Session.MiningStatus -ne "Idle") { 
                $Session.NewMiningStatus = "Idle"
                $Data = "$($Session.Branding.ProductLabel) is stopping...`n"
                $Session.SuspendCycle = $false
                $Session.RestartCycle = $true
            }
            break
        }
        "/functions/querypoolapi" { 
            if (-not $Session.Config.Pools.$($Parameters.Pool).BrainConfig.$($Parameters.Type)) { 
                $Data = "No pool configuration data for '/functions/querypoolapi?Pool=$($Parameters.Pool)&Type=$($Parameters.Type)'."
            }
            elseif (-not ($Data = (Invoke-RestMethod -Uri $Session.Config.Pools.$($Parameters.Pool).BrainConfig.$($Parameters.Type) -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec 5) | ConvertTo-Json)) { 
                $Data = "No data for '/functions/querypoolapi?Pool=$($Parameters.Pool)&Type=$($Parameters.Type)'."
            }
            break
        }
        "/functions/removeorphanedminerstats" { 
            if ($StatNames = Remove-ObsoleteMinerStats) { 
                $Data = $StatNames | ConvertTo-Json
            }
            else { 
                $Data = "No matching stats found."
            }
            Remove-Variable StatNames -ErrorAction Ignore
            break
        }
        "/functions/stat/disable" { 
            if ($Parameters.Miners) { 
                if ($Miners = (Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Session.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info).where({ -not $_.Disabled })) { 
                    $Data = @()
                    $Miners.ForEach(
                        { 
                            Set-MinerDisabled $_
                            $Data += $_.Name
                        }
                    )
                    $Message = "Disabled $($Data.Count) miner$(if ($Data.Count -ne 1) { "s" })."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                }
                else { 
                    $Data = "No matching miners found."
                }
                Remove-Variable Miners, Message, Worker -ErrorAction Ignore
                break
            }
        }
        "/functions/stat/enable" { 
            if ($Parameters.Miners) { 
                if ($Miners = (Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Session.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info).where({ $_.Disabled })) { 
                    $Data = @()
                    $Miners.ForEach(
                        { 
                            Set-MinerEnabled $_
                            $Data += $_.Name
                        }
                    )
                    $Message = "Enabled $($Data.Count) miner$(if ($Data.Count -ne 1) { "s" })."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                }
                else { 
                    $Data = "No matching miners found."
                }
                Remove-Variable Message, Miners, Worker -ErrorAction Ignore
                break
            }
        }
        "/functions/stat/get" { 
            if ($TempStats = @(if ($null -ne $Parameters.Value) { (Get-Stat).where({ $_.Name -like "*_$($Parameters.Type)" -and $_.Live -eq $Parameters.Value }) } else { Get-Stat })) { 
                if ($null -ne $Parameters.Value) { 
                    ($TempStats.Name | Sort-Object).foreach({ $Data += "$($_ -replace "(_Hashrate|_PowerConsumption)$")`n" })
                    if ($Parameters.Type -eq "Hashrate") { $Data += "`n$($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)H/s hashrate." }
                    elseif ($Parameters.Type -eq "PowerConsumption") { $Data += "`n$($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)W power consumption." }
                }
                else { 
                    $Data = $TempStats | ConvertTo-Json
                }
            }
            else { 
                $Data = "No matching stats found."
            }
            Remove-Variable TempStats -ErrorAction Ignore
            break
        }
        "/functions/stat/remove" { 
            if ($Parameters.Pools) { 
                if ($Pools = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Session.Pools | Select-Object) @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Algorithm, Currency, Name) { 
                    $Data = @()
                    ($Pools | Sort-Object -Property Name, Algorithm, Currency).foreach(
                        { 
                            $StatName = "$($_.Name)_$($_.Algorithm)$(if ($_.Currency) { "-$($_.Currency)" })"
                            $Data += $StatName

                            Remove-Stat -Name "$($StatName)_Profit"

                            $_.Available = $true
                            $_.Disabled = $false
                            $_.Price = $_.Price_Bias = $_.StablePrice = $_.Accuracy = [Double]::NaN
                            $_.Reasons = [System.Collections.Generic.SortedSet[String]]::new()
                        }
                    )
                    $Message = "Reset pool stats for $($Pools.Count) $(if ($Pools.Count -eq 1) { "pool" } Else { "pools" })."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                }
                else { 
                    $Data = "No matching pool stats found."
                }
                Remove-Variable Message, Pools, StatName -ErrorAction Ignore
                break
            }
            elseif ($Parameters.Miners -and $Parameters.Type -eq "Hashrate") { 
                if ($Miners = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Session.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info) { 
                    $Data = @()
                    $Miners.ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerReBenchmark $_
                        }
                    )
                    $Message = "Re-benchmark triggered for $($Data.Count) miner$(if ($Data.Count -ne 1) { "s" })."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                    if ($Session.Config.DryRun -and $Session.NewMiningStatus -eq "Running") { $Session.EndCycleTime = [DateTime]::Now.ToUniversalTime() }
                }
                else { 
                    $Data = "No matching hashrate stats found."
                }
                Remove-Variable Message, Miners, Worker -ErrorAction Ignore
                break
            }
            elseif ($Parameters.Miners -and $Parameters.Type -eq "PowerConsumption") { 
                if ($Miners = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Session.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info) { 
                    $Data = @()
                    $Miners.ForEach(
                        { 
                            $Data += $_.Name
                            Set-MinerMeasurePowerConsumption $_
                        }
                    )
                    $Message = "Re-measure power consumption triggered for $($Data.Count) miner$(if ($Data.Count -ne 1) { "s" })."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                    if ($Session.Config.DryRun -and $Session.NewMiningStatus -eq "Running") { $Session.EndCycleTime = [DateTime]::Now.ToUniversalTime() }
                }
                else { 
                    $Data = "No matching power consumption stats found."
                }
                Remove-Variable Message, Miners -ErrorAction Ignore
                break
            }
            if ($TempStats = @(if ($null -ne $Parameters.Value) { (Get-Stat).where({ $_.Name -like "*_$($Parameters.Type)" -and $_.Live -eq $Parameters.Value }) } else { (Get-Stat).where({ $_.Name -like "*_$($Parameters.Type)" }) })) { 
                $Data = @()
                ($TempStats | Sort-Object -Property Name).foreach(
                    { 
                        Remove-Stat -Name $_.Name
                        $Data += $_.Name -replace "(_Hashrate|_PowerConsumption)$"
                    }
                )
                if ($Parameters.Type -eq "Hashrate") { $Message = "Reset $($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" })$(if ($null -ne $Parameters.Value) { " with $($Parameters.Value)H/s hashrate" })." }
                elseif ($Parameters.Type -eq "PowerConsumption") { $Message = "Reset $($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" })$(if ($null -ne $Parameters.Value) { " with $($Parameters.Value)W power consumption" })." }
                elseif ($Parameters.Type -eq "Profit") { $Message = "Reset $($TempStats.Count) pool stat file$(if ($TempStats.Count -ne 1) { "s" })." }
                Write-Message -Level Info "Web GUI: $Message"
                $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
            }
            else { 
                $Data = "No matching stats found."
            }
            Remove-Variable Message, TempStats -ErrorAction Ignore
            break
        }
        "/functions/stat/set" { 
            if ($Parameters.Miners) { 
                $Data = @()
                if ($Parameters.Type -eq "Hashrate" -and $Parameters.Value -eq 0) { 
                    if ($Miners = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Session.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info) { 
                        $Miners.ForEach(
                            { 
                                Set-MinerFailed $_
                                $Data += $_.Name
                            }
                        )
                        $Message = "Marked $($Data.Count) miner$(if ($Data.Count -ne 1) { "s" }) as failed."
                        Write-Message -Level Verbose "Web GUI: $Message"
                        $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message" 
                    }
                    else { 
                        $Data = "No matching miners found."
                    }
                    Remove-Variable Algorithm, Message, Miners, StatName -ErrorAction Ignore
                    break
                }
            }
        }
        "/functions/switchinglog/clear" { 
            # Get mutex. Mutexes are shared across all threads and processes.
            # This lets us ensure only one thread is trying to write to the file at a time.
            $Mutex = [System.Threading.Mutex]::new($false, "$($Session.Branding.ProductLabel)_SwitchingLog")

            # Attempt to aquire mutex, waiting up to 1 second if necessary
            if ($Mutex.WaitOne(1000)) { 
                Get-ChildItem -Path ".\Logs\SwitchingLog.csv" -File | Remove-Item -Force
                $Mutex.ReleaseMutex()
            }
            Remove-Variable Mutex

            Write-Message -Level Verbose "Web GUI: Switching log '.\Logs\SwitchingLog.csv' cleared."
            $Data = "Switching log '.\Logs\SwitchingLog.csv' cleared."
            break
        }
        "/functions/variables/get" { 
            if ($Key) { 
                $Key = $Key -replace "\\|/", "."
                $TempVar = Get-Variable ($Key -split "\.")[0]
                $TempVarValue = $TempVar.Value
                if ($TempVarValue.GetType().Name -like "*SortedList") { 
                    if ($Key = ($Key -split "\.")[1]) { 
                        $Data = $TempVarValue.$Key | ConvertTo-Json
                    }
                    else { 
                        $Data = $TempVarValue.Keys | ConvertTo-Json
                    }
                }
                else { 
                    $Data = $TempVarValue
                }
                if (-not $Data) { $Data = "null" }
                Remove-Variable Key, TempVar, TempVarValue
            }
            break
        }
        "/functions/watchdogtimers/remove" { 
            if ($Parameters.Miners -or $Parameters.Pools) { 
                $Data = @()
                foreach ($Miner in (Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Session.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Name)) { 
                    if ($Session.WatchdogTimers.where({ $_.MinerName -eq $Miner.Name })) { 
                        # Update miner
                        $Data += $Miner.Name
                        $Miner.Reasons.where({ $_ -like "Miner suspended by watchdog *" }).foreach({ $Miner.Reasons.Remove($_) | Out-Null })
                        if (-not $Miner.Reasons.Count) { $Miner.Available = $true }

                        # Remove Watchdog timers
                        $Session.WatchdogTimers = $Session.WatchdogTimers.where({ $_.MinerName -ne $Miner.Name })
                    }
                }
                Remove-Variable Miner

                foreach ($Pool in (Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Session.Pools | Select-Object) @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Key)) { 
                    # Update pool
                    if ($Session.Pools.where({ $_.Key -eq $Pool.Key })) { 
                        $Data += "$($Pool.Key) [$($Pool.Region)]"
                        $Pool.Reasons.where({ $_ -like "Miner suspended by watchdog *" }).foreach({ $Pool.Reasons.Remove($_) | Out-Null })
                        if (-not $Pool.Reasons.Count) { $Pool.Available = $true }

                        # Remove Watchdog timers
                        $Session.WatchdogTimers = $Session.WatchdogTimers.where({ $_.Key -ne $Pool.Key })
                    }
                }
                Remove-Variable Pool
                if ($Data.Count) { 
                    $Message = "$($Data.Count) watchdog $(if ($Data.Count -eq 1) { "timer" } Else { "timers" }) removed."
                    Write-Message -Level Verbose "Web GUI: $Message"
                    $Data = "$(($Data | Sort-Object) -join "`n")`n`n$Message"
                }
                else { 
                    $Data = "No matching watchdog timer found."
                }
                Remove-Variable Message, Miner, Pool -ErrorAction Ignore
            }
            else { 
                $Session.WatchdogTimers = [System.Collections.Generic.List[PSCustomObject]]::new()
                foreach ($Miner in $Session.Miners) { 
                    $Miner.Reasons.where({ $_ -like "Miner suspended by watchdog *" }).foreach({ $Miner.Reasons.Remove($_) | Out-Null })
                    if (-not $Miner.Reasons.Count) { $_.Available = $true }
                }
                Remove-Variable Miner

                foreach ($Pool in $Session.Pools.ForEach) { 
                    $Pool.Reasons.where({ $_ -like "Pool suspended by watchdog *" }).foreach({ $Pool.Reasons.Remove($_) | Out-Null })
                    if (-not $Pool.Reasons.Count) { $Pool.Available = $true }
                }
                Remove-Variable Pool

                Write-Message -Level Verbose "Web GUI: All watchdog timers removed."
                $Data = "All watchdog timers removed.`nWatchdog timers will be recreated in the next cycle."
            }
            break
        }
        "/algorithms" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.Algorithms | Select-Object)
            break
        }
        "/algorithms/lastused" { 
            $Data = ConvertTo-Json -Depth 10 $Session.AlgorithmsLastUsed
            break
        }
        "/allcurrencies" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.AllCurrencies)
            break
        }
        "/apiversion" { 
            $Data = $Session.APIversion
            break
        }
        "/balances" { 
            $Data = ConvertTo-Json -Depth 10 ($Session.Balances | Sort-Object -Property DateTime -Bottom 10000 | Select-Object)
            break
        }
        "/balancedata" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.BalancesData | Sort-Object -Property DateTime -Descending)
            break
        }
        "/balancescurrencies" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.BalancesCurrencies)
            break
        }
        "/balancesupdatedtimestamp" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.BalancesUpdatedTimestamp)
            break
        }
        "/btc" { 
            $Data = $Session.Rates.BTC.($Session.Config.FIATcurrency)
            break
        }
        "/braindata" { 
            $Data = ConvertTo-Json -Depth 2 $Session.BrainData
            break
        }
        "/coinnames" { 
            $Data = [System.IO.File]::ReadAllLines(".\Data\CoinNames.json")
            break
        }
        "/config" { 
            $Data = ConvertTo-Json -Depth 10 ([System.IO.File]::ReadAllLines($Session.ConfigFile) | ConvertFrom-Json -Depth 10 -AsHashtable | Select-Object)
            if (-not ($Data | ConvertFrom-Json).ConfigFileVersion) { 
                $ConfigCopy = $Config.PsObject.Copy()
                $ConfigCopy.Remove("PoolsConfig")
                $Data = ConvertTo-Json -Depth 10 $ConfigCopy
                Remove-Variable ConfigCopy
            }
            break
        }
        "/configfile" { 
            $Data = $Session.ConfigFile.Replace("$(Convert-Path ".\")\", ".\")
            break
        }
        "/configrunning" { 
            $Data = ConvertTo-Json -Depth 10 $Session.Config
            break
        }
        "/cpufeatures" { 
            $Data = ConvertTo-Json $Session.CPUfeatures
            break
        }
        "/currency" { 
            $Data = $Session.Config.FIATcurrency
            break
        }
        "/currencyalgorithm" { 
            $Data = [System.IO.File]::ReadAllLines("$PWD\Data\CurrencyAlgorithm.json")
            break
        }
        "/dagdata" { 
            $Data = ConvertTo-Json -Depth 10 $Session.DAGdata
            break
        }
        "/devices" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.Devices | Sort-Object -Property Name)
            break
        }
        "/devices/enabled" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.Devices.where({ $_.State -eq "Enabled" }) | Sort-Object -Property Name)
            break
        }
        "/devices/disabled" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.Devices.where({ $_.State -eq "Disabled" }) | Sort-Object -Property Name)
            break
        }
        "/devices/unsupported" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.Devices.where({ $_.State -eq "Unsupported" }) | Sort-Object -Property Name)
            break
        }
        "/donationdata" { 
            $Data = ConvertTo-Json $Session.DonationData
            break
        }
        "/donationlog" { 
            $Data = ConvertTo-Json -Depth 10 @([System.IO.File]::ReadAllLines("$PWD\Logs\DonationLog.csv") | ConvertFrom-Csv -ErrorAction Ignore)
            break
        }
        "/driverversion" { 
            $Data = ConvertTo-Json -Depth 10 ($Session.DriverVersion | Select-Object)
            break
        }
        "/earningschartdata" { 
            $Data = ConvertTo-Json $Session.EarningsChartData
            break
        }
        "/equihashcoinpers" { 
            $Data = [System.IO.File]::ReadAllLines("$PWD\Data\EquihashCoinPers.json")
            break
        }
        "/extracurrencies" { 
            $Data = ConvertTo-Json -Depth 10 $Session.Config.ExtraCurrencies
            break
        }
        "/fiatcurrencies" { 
            $Data = ConvertTo-Json -Depth 10 ($Session.FIATcurrencies | Select-Object)
            break
        }
        "/miners" { 
            $Bias = if ($Session.CalculatePowerCost -and -not $Session.Config.IgnorePowerCost) { "Profit_Bias" } else { "Earnings_Bias" }
            $Data = ConvertTo-Json -Depth 5 @($Session.Miners.PsObject.Copy().foreach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true })
            Remove-Variable Bias
            break
        }
        "/miners/available" { 
            $Bias = if ($Session.CalculatePowerCost -and -not $Session.Config.IgnorePowerCost) { "Profit_Bias" } else { "Earnings_Bias" }
            $Data = ConvertTo-Json -Depth 5 @($Session.Miners.where({ $_.Available }).PsObject.Copy().foreach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true })
            Remove-Variable Bias
            break
        }
        "/miners/bestperdevice" { 
            $Data = ConvertTo-Json -Depth 5 @($Session.MinersBestPerDevice.PsObject.Copy().foreach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object { $_.BaseName_Version_Device -replace ".+-" })
            break
        }
        "/miners/best" { 
            $Bias = if ($Session.CalculatePowerCost -and -not $Session.Config.IgnorePowerCost) { "Profit_Bias" } else { "Earnings_Bias" }
            $Data = ConvertTo-Json -Depth 5 @($Session.MinersBest.PsObject.Copy().foreach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true })
            Remove-Variable Bias
            break
        }
        "/miners/disabled" { 
            $Data = ConvertTo-Json -Depth 5 @($Session.Miners.where({ $_.Status -eq [MinerStatus]::Disabled }).PsObject.Copy().foreach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }, EndTime)
            break
        }
        "/miners/failed" { 
            $Data = ConvertTo-Json -Depth 5 @($Session.Miners.where({ $_.Status -eq [MinerStatus]::Failed }).PsObject.Copy().foreach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }, EndTime)
            break
        }
        "/miners/launched" { 
            $Data = ConvertTo-Json -Depth 5 @($Session.MinersBest.PsObject.Copy().foreach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object -Property Info)
            break
        }
        "/miners/lastused" { 
            $Data = ConvertTo-Json -Depth 10 $Session.MinersLastUsed
            break
        }
        "/miners/missingbinary" { 
            $Data = ConvertTo-Json -Depth 5 @($Session.MinersMissingBinary.PsObject.Copy().foreach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object -Property Info)
            break
        }
        "/miners/missingfirewallrule" { 
            $Data = ConvertTo-Json -Depth 5 @($Session.MinersMissingFirewallRule.PsObject.Copy().foreach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object -Property Info)
            break
        }
        "/miners/missingprerequisite" { 
            $Data = ConvertTo-Json -Depth 5 @($Session.MinersMissingPrerequisite.PsObject.Copy().foreach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object -Property Info)
            break
        }
        "/miners/optimal" { 
            $Bias = if ($Session.CalculatePowerCost -and -not $Session.Config.IgnorePowerCost) { "Profit_Bias" } else { "Earnings_Bias" }
            $Data = ConvertTo-Json -Depth 5 @($Session.MinersOptimal.PsObject.Copy().foreach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true })
            Remove-Variable Bias
            break
        }
        "/miners/running" { 
            $Data = ConvertTo-Json -Depth 5 @($Session.Miners.where({ $_.Status -eq [MinerStatus]::Running }).PsObject.Copy().foreach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object { $_.BaseName_Version_Device -replace ".+-" })
            break
        }
        "/miners/unavailable" { 
            $Data = ConvertTo-Json -Depth 5 @($Session.Miners.where({ $_.Available -ne $true }).PsObject.Copy().foreach({ if ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp, WorkersRunning | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }, Name, Algorithm)
            break
        }
        "/miningpowercost" { 
            $Data = $Session.MiningPowerCost
            break
        }
        "/miningearnings" { 
            $Data = $Session.MiningEarnings
            break
        }
        "/miningprofit" { 
            $Data = $Session.MiningProfit
            break
        }
        "/poolname" { 
            $Data = ConvertTo-Json -Depth 10 $Session.Config.PoolName
            break
        }
        "/pooldata" { 
            $Data = ConvertTo-Json -Depth 10 $Session.PoolData
            break
        }
        "/poolsconfig" { 
            $Data = ConvertTo-Json -Depth 10 ($Session.Config.Pools | Select-Object)
            break
        }
        "/poolsconfigfile" { 
            $Data = $Session.PoolsConfigFile.Replace("$(Convert-Path ".\")\", ".\")
            break
        }
        "/pools" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.Pools | Sort-Object -Property Algorithm, Name, Region)
            break
        }
        "/pools/added" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.PoolsAdded | Sort-Object -Property Algorithm, Name, Region)
            break
        }
        "/pools/available" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.Pools.where({ $_.Available }) | Sort-Object -Property Algorithm, Name, Region)
            break
        }
        "/pools/best" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.PoolsBest | Sort-Object -Property Algorithm, Name, Region)
            break
        }
        "/pools/expired" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.PoolsExpired | Sort-Object -Property Algorithm, Name, Region)
            break
        }
        "/pools/new" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.PoolsNew | Sort-Object -Property Algorithm, Name, Region)
            break
        }
        "/pools/lastearnings" { 
            $Data = ConvertTo-Json -Depth 10 $Session.PoolsLastEarnings
            break
        }
        "/pools/lastused" { 
            $Data = ConvertTo-Json -Depth 10 $Session.PoolsLastUsed
            break
        }
        "/pools/unavailable" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.Pools.where({ -not $_.Available }) | Sort-Object -Property Algorithm, Name, Region)
            break
        }
        "/pools/updated" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.PoolsUpdated | Sort-Object -Property Algorithm, Name, Region)
            break
        }
        "/poolreasons" { 
            $Data = ConvertTo-Json -Depth 10 ($Session.Pools.where({ -not $_.Available }).Reasons | Sort-Object -Unique)
            break
        }
        "/poolvariants" { 
            $Data = ConvertTo-Json -Depth 10 $Session.PoolVariants
            break
        }
        "/rates" { 
            $Data = ConvertTo-Json -Depth 10 ($Session.Rates | Select-Object)
            break
        }
        "/refreshtimestamp" { 
            $Data = $Session.RefreshTimestamp | ConvertTo-Json
            break
        }
        "/regions" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.Regions[0] | Sort-Object)
            break
        }
        "/regionsdata" { 
            $Data = ConvertTo-Json -Depth 10 $Session.Regions
            break
        }
        "/stats" { 
            $Data = ConvertTo-Json -Depth 10 ($Stats | Select-Object)
            break
        }
        "/summarytext" { 
            $Data = ConvertTo-Json -Depth 10 @((($Session.Summary -replace " / ", "/" -replace "&ensp;", " " -replace "   ", "  ") -split "<br>").trim())
            break
        }
        "/summary" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.Summary | Select-Object)
            break
        }
        "/switchinglog" { 
            $Data = ConvertTo-Json -Depth 10 @([System.IO.File]::ReadAllLines("$PWD\Logs\SwitchingLog.csv") | ConvertFrom-Csv | Select-Object -Last 1000 | Sort-Object -Property DateTime -Descending)
            break
        }
        "/unprofitablealgorithms" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.UnprofitableAlgorithms | Select-Object)
            break
        }
        "/version" { 
            $Data = ConvertTo-Json @("$($Session.Branding.ProductLabel) Version: $($Session.Branding.Version)", "API Version: $($Session.APIversion)", "PWSH Version: $($PSVersionTable.PSVersion.ToString())")
            break
        }
        "/watchdogtimers" { 
            $Data = ConvertTo-Json -Depth 10 @($Session.WatchdogTimers | Select-Object)
            break
        }
        "/wallets" { 
            $Data = ConvertTo-Json -Depth 10 ($Session.Config.Wallets | Select-Object)
            break
        }
        "/watchdogexpiration" { 
            $Data = $Session.WatchdogReset
            break
        }
        "/workers" { 
            if ($Session.ShowWorkerStatus -and $Session.Config.MonitoringUser -and $Session.Config.MonitoringServer -and $Session.WorkersLastUpdated -lt [DateTime]::Now.AddSeconds(-30)) { 
                Read-MonitoringData
            }
            if ($Session.Workers) { 
                $Workers = [System.Collections.ArrayList]@(
                    $Session.Workers | Select-Object @(
                        @{ Name = "Algorithm"; Expression = { $_.data.ForEach({ $_.Algorithm -split "," -join " & " }) -join "<br>" } },
                        @{ Name = "Benchmark Hashrate"; Expression = { $_.data.ForEach({ ($_.EstimatedSpeed.ForEach({ if ([Double]$_ -gt 0) { "$($_ | ConvertTo-Hash)/s" -replace " \s+" } else { "-" } })) -join " & " }) -join "<br>" } },
                        @{ Name = "Currency"; Expression = { $_.Data.Currency | Select-Object -Unique } },
                        @{ Name = "EstimatedEarnings"; Expression = { [Decimal]((($_.Data.Earnings | Measure-Object -Sum).Sum) * $Session.Rates.BTC.($_.Data.Currency | Select-Object -Unique)) } },
                        @{ Name = "EstimatedProfit"; Expression = { [Decimal]($_.Profit * $Session.Rates.BTC.($_.Data.Currency | Select-Object -Unique)) } },
                        @{ Name = "LastSeen"; Expression = { $_.date } },
                        @{ Name = "Live Hashrate"; Expression = { $_.data.ForEach({ ($_.CurrentSpeed.ForEach({ if ([Double]$_ -gt 0) { "$($_ | ConvertTo-Hash)/s" -replace " \s+" } else { "-" } })) -join " & " }) -join "<br>" } },
                        @{ Name = "Miner"; Expression = { $_.data.name -join "<br/>" } },
                        @{ Name = "Pool"; Expression = { $_.data.ForEach({ $_.Pool -split "," -join " & " }) -join "<br>" } },
                        @{ Name = "Status"; Expression = { $_.status } },
                        @{ Name = "Version"; Expression = { $_.version } },
                        @{ Name = "Worker"; Expression = { $_.worker } }
                    ) | Sort-Object -Property "Worker"
                )
                $Data = ConvertTo-Json @($Workers | Select-Object) -Depth 4
            }
            else { 
                $Data = "No worker data from reporting server"
            }
            break
        }
        default { 
            # Set index page
            if ($Path -eq "/") { $Path = "/index.html" }

            # Check if there is a file with the requested path
            $Filename = "$BasePath$Path"
            if (Test-Path -LiteralPath $Filename -PathType Leaf) { 
                # If the file is a PowerShell script, execute it and return the output. A $Parameters parameter is sent built from the query string
                # Otherwise, just return the contents of the file
                $File = Get-ChildItem $Filename -File

                if ($File.Extension -eq ".ps1") { 
                    $Data = & $File.FullName -Parameters $Parameters
                }
                else { 
                    $Data = Get-Content $Filename -Raw

                    # Process server side includes for html files
                    # Includes are in the traditional '<!-- #include file="/path/filename.html" -->' format used by many web servers
                    if ($File.Extension -eq ".html") { 
                        $IncludeRegex = [regex]'<!-- *#include *file="(.*)" *-->'
                        $IncludeRegex.Matches($Data).foreach(
                            { 
                                $IncludeFile = $BasePath + "/" + $_.Groups[1].Value
                                if (Test-Path -LiteralPath $IncludeFile -PathType Leaf) { 
                                    $IncludeData = Get-Content $IncludeFile -Raw
                                    $Data = $Data -replace $_.Value, $IncludeData
                                }
                            }
                        )
                    }
                }

                # Set content type based on file extension
                if ($MIMEtypes.ContainsKey($File.Extension)) { 
                    $ContentType = $MIMEtypes[$File.Extension]
                }
                else { 
                    # If it's an unrecognized file type, prompt for download
                    $ContentType = "application/octet-stream"
                }
            }
            else { 
                $StatusCode = 404
                $ContentType = "text/html"
                $Data = "URI '$Path' is not a valid resource."
            }
            Remove-Variable File, Filename, IncludeData, IncludeFile, IncludeRegex, Key -ErrorAction Ignore
        }
    }

    Remove-Variable Key

    # If $Data is null, the API will just return whatever data was in the previous request. Instead, show an error
    # This happens if the script just started and hasn't filled all the properties in yet.
    if ($null -eq $Data) { 
        $Data = @{ "Error" = "API data not available" } | ConvertTo-Json
    }

    # Send the response
    $Response.Headers.Add("Content-Type", $ContentType)
    $Response.StatusCode = $StatusCode
    $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes($Data)
    $Response.ContentLength64 = $ResponseBuffer.Length
    if ($Session.Config.APIlogfile -and $Session.Config.LogLevel -contains "Debug") { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Response: $Data" | Out-File $Session.Config.APIlogfile -Append -ErrorAction Ignore }
    $Response.OutputStream.Write($ResponseBuffer, 0, $ResponseBuffer.Length)
    $Response.Close()

    Remove-Variable ContentType, Data, Parameters, Response, ResponseBuffer, StatusCode -ErrorAction Ignore

    if ($GCstopWatch.Elapsed.TotalMinutes -gt 10) { 
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