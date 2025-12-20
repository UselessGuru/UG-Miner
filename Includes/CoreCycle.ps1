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
File:           Core.ps1
Version:        6.7.9
Version date:   2025/12/20
#>

using module .\Include.psm1

# Set process priority to BelowNormal to avoid hashrate drops on systems with weak CPUs
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$ErrorLogFile = "Logs\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"

(Get-ChildItem -Path ".\Includes\MinerAPIs" -File).ForEach({ . $_.FullName })

$Session.Miners = [Miner[]]@()
$Session.Pools = [Pool[]]@()

try { 
    do { 
        Write-Message -Level Info "Started new cycle."

        # Read-Config will read and apply configuration if configuration files have changed
        Read-Config -ConfigFile $Session.ConfigFile -PoolsConfigFile $Session.PoolsConfigFile

        $Session.CoreLoopCounter ++
        $Session.EndCycleMessage = ""

        # Set master timer
        $Session.Timer = [DateTime]::Now.ToUniversalTime()

        $Session.BeginCycleTime = $Session.Timer
        $Session.EndCycleTime = if ($Session.EndCycleTime) { $Session.EndCycleTime.AddSeconds($Session.Config.Interval) } else { $Session.BeginCycleTime.AddSeconds($Session.Config.Interval) }

        $Session.CycleStarts += $Session.Timer
        $Session.CycleStarts = @($Session.CycleStarts | Sort-Object -Bottom (3, ($Session.Config.SyncWindow + 1) | Measure-Object -Maximum).Maximum)

        # Internet connection must be available
        if (-not $Session.MyIPaddress) { 
            $Message = "No internet connection - will retry in $($Session.Config.Interval) seconds..."
            Write-Message -Level Error $Message
            $Session.Summary = $Message
            Remove-Variable Message

            Clear-PoolData
            Clear-MinerData

            $Session.RefreshNeeded = $true

            Start-Sleep -Seconds $Session.Config.Interval

            Write-Message -Level Info "Ending cycle."
            continue
        }

        if (-not $Session.Config.PoolName) { 
            $Message = "No configured pools - will retry in $($Session.Config.Interval) seconds..."
            Write-Message -Level Warn $Message
            $Session.Summary = $Message
            Remove-Variable Message

            Clear-PoolData
            Clear-MinerData

            $Session.RefreshNeeded = $true

            Start-Sleep -Seconds $Session.Config.Interval

            Write-Message -Level Info "Ending cycle."
            continue
        }

        # Tuning parameters require local admin rights
        $Session.ApplyMinerTweaks = $Session.Config.UseMinerTweaks -and $Session.IsLocalAdmin

        # Miner naming scheme has changed. Must clear all existing miners & watchdog timers due to different miner names
        if ($Session.Miners -and $Session.Config.BenchmarkAllPoolAlgorithmCombinations -ne $Session.BenchmarkAllPoolAlgorithmCombinations) { 
            Write-Message -Level Info "Miner naming scheme has changed. Stopping all running miners..."

            Clear-MinerData
        }

        # Use values from config
        $Session.BenchmarkAllPoolAlgorithmCombinations = $Session.Config.BenchmarkAllPoolAlgorithmCombinations
        $Session.PoolTimeout = [Math]::Floor($Session.Config.PoolTimeout)

        $Session.EnabledDevices = [Device[]]@($Session.Devices.where({ $_.State -ne [DeviceState]::Unsupported -and $_.Name -notin $Session.Config.ExcludeDeviceName }).ForEach({ $_ | Select-Object -Property * }))
        if (-not $Session.EnabledDevices) { 
            $Message = "No enabled devices - will retry in $($Session.Config.Interval) seconds..."
            Write-Message -Level Warn $Message
            $Session.Summary = $Message
            Remove-Variable Message

            Clear-PoolData
            Clear-MinerData

            $Session.RefreshNeeded = $true

            Start-Sleep -Seconds $Session.Config.Interval

            Write-Message -Level Info "Ending cycle."
            continue
        }

        # Update enabled devices
        $Session.EnabledDevices.ForEach(
            { 
                # Miner name must not contain spaces
                $_.Model = $_.Model -replace " "
                if ($_.Type -eq "GPU") { $_.Type = $_.Vendor } # For GPUs set type equal to vendor
            }
        )

        # Power cost preparations
        if ($Session.CalculatePowerCost = $Session.Config.CalculatePowerCost) { 
            if ($Session.EnabledDevices.Count -ge 1) { 
                # HWiNFO64 verification
                $RegistryPath = "HKCU:\Software\HWiNFO64\VSB"
                if ($RegValue = Get-ItemProperty -Path $RegistryPath -ErrorAction Ignore) { 
                    $HWiNFO64RegTime = Get-RegTime $RegistryPath
                    if ($Session.HWiNFO64RegTime -eq $HWiNFO64RegTime.AddSeconds(5)) { 
                        Write-Message -Level Warn "Power consumption data in registry has not been updated since $($Session.HWiNFO64RegTime.ToString("yyyy-MM-dd HH:mm:ss")) [HWiNFO64 not running???] - disabling power consumption readout and profit calculations."
                        $Session.CalculatePowerCost = $false
                    }
                    else { 
                        $Session.HWiNFO64RegTime = $HWiNFO64RegTime
                        $PowerConsumptionData = @{ }
                        $DeviceName = ""
                        $RegValue.PSObject.Properties.where({ $_.Name -match "^Label[0-9]+$" -and (Compare-Object @($_.Value -split " " | Select-Object) @($Session.EnabledDevices.Name) -IncludeEqual -ExcludeDifferent) }).ForEach(
                            { 
                                $DeviceName = ($_.Value -split " ")[-1]
                                try { 
                                    $PowerConsumptionData[$DeviceName] = $RegValue.($_.Name -replace "Label", "Value")
                                }
                                catch { 
                                    Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [duplicate sensor for $DeviceName] - disabling power consumption and profit calculations."
                                    $Session.CalculatePowerCost = $false
                                }
                            }
                        )
                        # Add configured power consumption
                        $Session.Devices.Name.ForEach(
                            { 
                                $DeviceName = $_
                                if ($ConfiguredPowerConsumption = $Session.Config.PowerConsumption.$_ -as [Double]) { 
                                    if ($Session.EnabledDevices.Name -contains $_ -and -not $PowerConsumptionData.$_) { Write-Message -Level Info "HWiNFO64 cannot read power consumption data for device ($_). Using configured value of $ConfiguredPowerConsumption W." }
                                    $PowerConsumptionData[$_] = "$ConfiguredPowerConsumption W"
                                }
                                $Session.EnabledDevices.where({ $_.Name -eq $DeviceName }).ForEach({ $_.ConfiguredPowerConsumption = $ConfiguredPowerConsumption })
                                $Session.Devices.where({ $_.Name -eq $DeviceName }).ForEach({ $_.ConfiguredPowerConsumption = $ConfiguredPowerConsumption })
                            }
                        )
                        if ($DeviceNamesMissingSensor = (Compare-Object @($Session.EnabledDevices.Name) @($PowerConsumptionData.psBase.Keys) -PassThru).where({ $_.SideIndicator -eq "<=" })) { 
                            Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [missing sensor configuration for $($DeviceNamesMissingSensor -join ", ")] - disabling power consumption and profit calculations."
                            $Session.CalculatePowerCost = $false
                        }

                        # Enable read power consumption for configured devices
                        $Session.EnabledDevices.ForEach({ $_.ReadPowerConsumption = $PowerConsumptionData.psBase.Keys -contains $_.Name })
                        Remove-Variable ConfiguredPowerConsumption, DeviceName, DeviceNamesMissingSensor, PowerConsumptionData, HWiNFO64RegTime -ErrorAction Ignore
                    }
                }
                else { 
                    Write-Message -Level Warn "Cannot read power consumption data from registry [Key '$RegistryPath' does not exist - HWiNFO64 not running???] - disabling power consumption and profit calculations."
                    $Session.CalculatePowerCost = $false
                }
                Remove-Variable RegistryPath, RegValue -ErrorAction Ignore
            }
            else { $Session.CalculatePowerCost = $false }
        }
        if (-not $Session.CalculatePowerCost ) { $Session.EnabledDevices.ForEach({ $_.ReadPowerConsumption = $false }) }

        # Power price
        if (-not $Session.Config.PowerPricekWh.psBase.Keys) { 
            $Session.Config.PowerPricekWh."00:00" = 0
        }
        elseif ($null -eq $Session.Config.PowerPricekWh."00:00") { 
            # 00:00h power price is the same as the latest price of the previous day
            $Session.Config.PowerPricekWh."00:00" = $Session.Config.PowerPricekWh.($Session.Config.PowerPricekWh.psBase.Keys | Sort-Object -Bottom 1)
        }
        $Session.PowerPricekWh = [Double]($Session.Config.PowerPricekWh.($Session.Config.PowerPricekWh.psBase.Keys.where({ $_ -le (Get-Date -Format HH:mm).ToString() }) | Sort-Object -Bottom 1))
        $Session.PowerCostBTCperW = [Double](1 / 1000 * 24 * $Session.PowerPricekWh / $Session.Rates.BTC.($Session.Config.FIATcurrency))

        # Core suspended with <Ctrl><Alt>P in MainLoop
        while ($Session.SuspendCycle) { Start-Sleep -Seconds 1 }

        # Set minimum Watchdog count 3
        $Session.WatchdogCount = (3, $Session.Config.WatchdogCount | Measure-Object -Maximum).Maximum

        # Expire watchdog timers
        $Session.WatchdogReset = $Session.WatchdogCount * $Session.WatchdogCount * $Session.WatchdogCount * $Session.WatchdogCount * $Session.Config.Interval
        if ($Session.Config.Watchdog) { $Session.WatchdogTimers = $Session.WatchdogTimers.where({ $_.Kicked -ge $Session.Timer.AddSeconds(- $Session.WatchdogReset) }) }
        else { $Session.WatchdogTimers = [System.Collections.Generic.List[PSCustomObject]]::new() }

        # Load unprofitable algorithms as sorted case insensitive hash table, cannot use one-liner (Error 'Cannot find an overload for "new" and the argument count: "2"')
        try { 
            if (-not $Session.UnprofitableAlgorithmsTimestamp -or (Get-ChildItem -Path ".\Data\UnprofitableAlgorithms.json").LastWriteTime -gt $Session.UnprofitableAlgorithmsTimestamp) { 
                $UnprofitableAlgorithms = [System.IO.File]::ReadAllLines("$PWD\Data\UnprofitableAlgorithms.json") | ConvertFrom-Json -AsHashtable
                $Session.UnprofitableAlgorithms = [System.Collections.SortedList]::New([StringComparer]::OrdinalIgnoreCase)
                $UnprofitableAlgorithms.Keys.ForEach({ $Session.UnprofitableAlgorithms.$_ = $UnprofitableAlgorithms.$_ })
                Remove-Variable UnprofitableAlgorithms
                Write-Message -Level Info "$(if ($Session.UnprofitableAlgorithmsTimestamp) { "Refreshed" } else { "Loaded" }) list of unprofitable algorithms ($($Session.UnprofitableAlgorithms.Count) $(if ($Session.UnprofitableAlgorithms.Count -ne 1) { "entries" } else { "entry" }))."
                $Session.UnprofitableAlgorithmsTimestamp = (Get-ChildItem -Path ".\Data\UnprofitableAlgorithms.json").LastWriteTime
            }
        }
        catch { 
            Write-Message -Level Error "Error loading list of unprofitable algorithms. File '.\Data\UnprofitableAlgorithms.json' is not a valid $($Session.Branding.ProductLabel) JSON data file. Please restore it from your original download."
            $Session.Remove("UnprofitableAlgorithms")
            $Session.Remove("UnprofitableAlgorithmsTimestamp")
        }

        if ($Session.Config.Donation -gt 0) { 
            if (-not $Session.Donation.Start) { 
                # Re-Randomize donation start and data once per day
                if ((Get-Item -Path "$PWD\Logs\DonationLog.csv" -ErrorAction Ignore).LastWriteTime -lt [DateTime]::Today) { 
                    # Do not donate if remaing time for today is less than donation duration
                    if ($Session.Config.Donation -lt (1440 - [Math]::Floor([DateTime]::Now.TimeOfDay.TotalMinutes))) { $Session.Donation.Start = [DateTime]::Now.AddMinutes((Get-Random -Minimum 0 -Maximum (1440 - [Math]::Floor([DateTime]::Now.TimeOfDay.TotalMinutes) - $Session.Config.Donation))) }
                }
            }

            if ($Session.Donation.Start -and [DateTime]::Now -ge $Session.Donation.Start) { 
                if (-not $Session.Donation.End) { 
                    $Session.Donation.Start = [DateTime]::Now
                    # Add pool config to config (in-memory only)
                    $Session.Donation.Username = $Session.DonationData.Keys | Get-Random
                    $Session.Donation.PoolsConfig = Get-DonationConfig -DonateUsername $Session.Donation.Username
                    # Ensure full donation period
                    $Session.Donation.End = $Session.Donation.Start.AddMinutes($Session.Config.Donation)
                    $Session.EndCycleTime = ($Session.Donation.End).ToUniversalTime()
                    Write-Message -Level Info "Donation run: Mining for '$($Session.Donation.Username)' for the next $(if (($Session.Config.Donation - ([DateTime]::Now - $Session.Donation.Start).Minutes) -gt 1) { "$($Session.Config.Donation - ([DateTime]::Now - $Session.Donation.Start).Minutes) minutes" } else { "minute" })."
                    $Session.Donation.Running = $true
                }
            }
        }

        if ($Session.Donation.Running) { 
            if ($Session.Config.Donation -gt 0 -and [DateTime]::Now -lt $Session.Donation.End) { 
                # Use donation pool config, use same pool variant to avoid extra benchmarking
                $Session.Config.PoolName = $Session.Config.PoolName.where({ (Get-PoolBaseName $_) -in $Session.Donation.PoolsConfig.Keys })
                $Session.Config.Pools = $Session.Donation.PoolsConfig
                # Setting 0 -> miner keepalive will not be of relevance and miners will be restartet at end of donation run
                $Session.Config.MinCycle = 0
            }
            else { 
                # Donation end
                $Session.DonationLog = $Session.DonationLog | Select-Object -Last 365 # Keep data for one year
                [Array]$Session.DonationLog += [PSCustomObject]@{ 
                    Start = $Session.Donation.Start
                    End   = $Session.Donation.End
                    Name  = $Session.Donation.Username
                }
                $Session.DonationLog | Export-Csv -LiteralPath ".\Logs\DonationLog.csv" -Force -ErrorAction Ignore
                $Session.Donation.PoolsConfig = $null
                $Session.Donation.Start = $null
                $Session.Donation.End = $null
                Write-Message -Level Info "Donation run complete - thank you! Mining for you again. :-)"
                $Session.Miners.where({ [MinerStatus]::Running, [MinerStatus]::DryRun -contains $_.Status }).ForEach({ $_.KeepRunning = $false; $_.Restart = $true })
                $Session.Donation.Running = $false
                # Setting 0 -> miner keepalive will not be of relevance and miners will be restarted at end of donation run
                $Session.Config.MinCycle = 0
                $Session.Config.Pools = $Config.Pools
                $Session.Config.PoolName = $Config.PoolName
            }
        }

        # Skip some stuff when
        # - not donating and
        # - configuration unchanged and
        # - we have pools and
        # - the previous cycle was less than half a cycle duration
        if ($Session.Donation.Running -or $Session.ConfigTimestamp -gt $Session.Timer -or -not $Session.Pools -or $Session.PoolDataCollectedTimeStamp.AddSeconds($Session.Config.Interval / 2) -lt $Session.Timer) { 

            # Check for new version
            if (-not $Session.Donation.Running -and $Session.Config.AutoUpdateCheckInterval -and $Session.CheckedForUpdate -lt [DateTime]::Now.AddDays(-$Session.Config.AutoUpdateCheckInterval)) { Get-Version }

            # Stop / start brain background jobs
            $PoolBaseNames = Get-PoolBaseName $Session.Config.PoolName
            $Session.Brains.Keys.where({ $PoolBaseNames -notcontains $_ }).ForEach({ Stop-Brain $_ })
            Remove-Variable PoolBaseNames
            Start-Brain @(Get-PoolBaseName $Session.Config.PoolName)

            # Core suspended with <Ctrl><Alt>P in MainLoop
            while ($Session.SuspendCycle) { Start-Sleep -Seconds 1 }

            # Remove stats that have been deleted from disk
            try { 
                if ($StatFiles = (Get-ChildItem -Path "Stats" -File).BaseName) { 
                    if ($Stats.Keys) { 
                        (Compare-Object -PassThru $StatFiles $Stats.Keys).where({ $_.SideIndicator -eq "=>" }).ForEach({ $Stats.Remove($_) })
                    }
                }
            }
            catch {}
            Remove-Variable StatFiles -ErrorAction Ignore

            # Read latest DAG data from web
            $Session.DAGdata = Get-AllDAGdata $Session.DAGdata

            # Core suspended with <Ctrl><Alt>P in MainLoop
            while ($Session.SuspendCycle) { Start-Sleep -Seconds 1 }

            # Collect pool data
            if ($Session.Config.PoolName) { 
                $Session.PoolsCount = $Session.Pools.Count

                # Wait for pool data message
                if ($Session.Brains.Keys.where({ $Session.Brains[$_].StartTime -gt $Session.Timer.AddSeconds(- $Session.Config.Interval) }) -or -not $Session.Miners) { 
                    # Newly started brains, allow extra time for brains to get ready
                    $Session.PoolTimeout = 60
                    $Message = "Loading initial pool data from $((Get-PoolBaseName $Session.Config.PoolName) -join ", " -replace ",([^,]*)$", " &`$1").<br>This may take up to $($Session.PoolTimeout) seconds..."
                    if (-not $Session.Miners) { 
                        $Session.Summary = $Message
                        $Session.RefreshTimestamp = (Get-Date -Format "G")
                        $Session.RefreshNeeded = $true
                    }
                    Write-Message -Level Info ($Message -replace "<br>", " ")
                    Remove-Variable Message
                }
                else { 
                    Write-Message -Level Info "Loading pool data from $((Get-PoolBaseName $Session.Config.PoolName) -join ", " -replace ",([^,]*)$", " &`$1")..."
                }

                # Wait for all brains
                $PoolDataCollectedTimeStamp = if ($Session.PoolDataCollectedTimeStamp) { $Session.PoolDataCollectedTimeStamp } else { $Session.ScriptStartTime }
                while ([DateTime]::Now.ToUniversalTime() -lt $Session.Timer.AddSeconds($Session.PoolTimeout) -and ($Session.Brains.Keys.where({ $Session.Brains[$_].Updated -lt $PoolDataCollectedTimeStamp }))) { 
                    Start-Sleep -Seconds 1
                }
                Remove-Variable PoolDataCollectedTimeStamp

                $Session.Remove("PoolsNew")
                $Session.PoolsNew = $Session.Config.PoolName.ForEach(
                    { 
                        $PoolName = Get-PoolBaseName $_
                        if (Test-Path -LiteralPath ".\Pools\$PoolName.ps1") { 
                            try { 
                                Write-Message -Level Debug "Pool definition file '$PoolName': Start building pool objects"
                                & ".\Pools\$PoolName.ps1" -PoolVariant $_
                                Write-Message -Level Debug "Pool definition file '$PoolName': End building pool objects"
                            }
                            catch { 
                                Write-Message -Level Error "Error in pool file 'Pools\$PoolName.ps1'."
                                "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                                $_.Exception | Format-List -Force >> $ErrorLogFile
                                $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
                            }
                        }
                    }
                ).ForEach(
                    { 
                        $Pool = [Pool]$_
                        $Pool.CoinName = $Session.CoinNames[$Pool.Currency]
                        $Pool.Fee = if ($Session.Config.IgnorePoolFee -or $Pool.Fee -lt 0 -or $Pool.Fee -gt 1) { 0 } else { $Pool.Fee }
                        $Factor = $Pool.EarningsAdjustmentFactor * (1 - $Pool.Fee)
                        $Pool.Price *= $Factor
                        $Pool.Price_Bias = $Pool.Price * $Pool.Accuracy
                        $Pool.StablePrice *= $Factor
                        # Set algorithm variant
                        if ($Pool.Algorithm -match $Session.RegexAlgoHasDAG) { 
                            if ($Session.DAGdata.Currency.($Pool.Currency).BlockHeight) { 
                                $Pool.BlockHeight = $Session.DAGdata.Currency.($Pool.Currency).BlockHeight
                                $Pool.DAGsizeGiB = $Session.DAGdata.Currency.($Pool.Currency).DAGsize / 1GB
                                $Pool.Epoch = $Session.DAGdata.Currency.($Pool.Currency).Epoch
                            }
                            elseif ($Session.DAGdata.Algorithm.($Pool.Algorithm).BlockHeight) { 
                                $Pool.BlockHeight = $Session.DAGdata.Algorithm.($Pool.Algorithm).BlockHeight
                                $Pool.DAGsizeGiB = $Session.DAGdata.Algorithm.($Pool.Algorithm).DAGsize / 1GB
                                $Pool.Epoch = $Session.DAGdata.Algorithm.($Pool.Algorithm).Epoch
                            }
                        }
                        if ($Pool.DAGsizeGiB -and $Pool.Algorithm -match $Session.RegexAlgoHasDynamicDAG) { 
                            $Pool.AlgorithmVariant = "$($Pool.Algorithm)($([Math]::Ceiling($Pool.DAGsizeGiB))GiB)"
                        }
                        else { 
                            $Pool.AlgorithmVariant = $Pool.Algorithm
                        }
                        $Pool
                    }
                )
                Remove-Variable Factor, Pool, PoolName -ErrorAction Ignore

                if ($PoolsWithoutData = Compare-Object -PassThru @($Session.Config.PoolName) @($Session.PoolsNew.Variant | Sort-Object -Unique)) { Write-Message -Level Warn "No data received from pool$(if ($PoolsWithoutData.Count -gt 1) { "s" }) $($PoolsWithoutData -join ", " -replace ",([^,]*)$", " &`$1")." }
                Remove-Variable PoolsWithoutData
                $Session.PoolDataCollectedTimeStamp = [DateTime]::Now.ToUniversalTime()

                # Remove and count deconfigured pools
                $PoolsCount = $Session.Pools.Count
                $Session.Pools = $Session.Pools.where({ $_.Variant -in $Session.Config.PoolName })
                $PoolsDeconfiguredCount = $PoolsCount - $Session.Pools.Count

                # Expire pools that have not been updated for 1 day
                $Timestamp = [DateTime]::Now.ToUniversalTime().AddHours(-24)
                $Session.PoolsExpired = $Session.Pools.where({ $_.Updated -lt $Timestamp })
                $Session.Pools = $Session.Pools.where({ $_.Updated -ge $Timestamp })
                Remove-Variable Timestamp

                if ($Pools = Compare-Object -PassThru @($Session.Pools | Select-Object) @($Session.PoolsNew | Select-Object) -Property Key -IncludeEqual) { 
                    # Find added & updated pools
                    $Session.PoolsAdded = $Pools.where({ $_.SideIndicator -eq "=>" })
                    $Session.PoolsUpdated = $Pools.where({ $_.SideIndicator -eq "==" })
                    $Pools.ForEach({ $_.PSObject.Properties.Remove("SideIndicator") })

                    # Update existing pools, must not replace pool object. Doing so would break the reference to the miner worker pool
                    $Session.PoolsUpdated.ForEach(
                        { 
                            $Key = $_.Key
                            # Get data from new pool and update existing one
                            if ($Pool = $Session.PoolsNew.where({ $_.Key -eq $Key })[0]) { 
                                $_.Accuracy = $Pool.Accuracy
                                $_.AlgorithmVariant = $Pool.AlgorithmVariant
                                $_.BlockHeight = $Pool.BlockHeight
                                $_.CoinName = $Pool.CoinName
                                $_.Currency = $Pool.Currency
                                $_.DAGsizeGiB = $Pool.DAGsizeGiB
                                $_.Disabled = $Pool.Disabled
                                $_.EarningsAdjustmentFactor = $Pool.EarningsAdjustmentFactor
                                $_.Epoch = $Pool.Epoch
                                $_.Fee = $Pool.Fee
                                $_.Host = $Pool.Host
                                $_.Pass = $Pool.Pass
                                $_.Port = $Pool.Port
                                $_.PortSSL = $Pool.PortSSL
                                $_.Price = $Pool.Price
                                $_.Price_Bias = $Pool.Price_Bias
                                $_.Reasons = $Pool.Reasons
                                $_.Region = $Pool.Region
                                $_.StablePrice = $Pool.StablePrice
                                $_.Updated = $Pool.Updated
                                $_.User = $Pool.User
                                $_.WorkerName = $Pool.WorkerName
                                $_.Workers = $Pool.Workers
                            }
                        }
                    )
                    Remove-Variable Key, Pool -ErrorAction Ignore

                    $Pools.ForEach(
                        { 
                            $_.Best = $false
                            $_.Prioritize = $false

                            # PoolPorts[0] = non-SSL, PoolPorts[1] = SSL
                            $_.PoolPorts = $(if ($Session.Config.SSL -ne "Always" -and $_.Port) { [UInt16]$_.Port } else { $null }), $(if ($Session.Config.SSL -ne "Never" -and $_.PortSSL) { [UInt16]$_.PortSSL } else { $null })
                        }
                    )

                    # Reduce price on older pool data
                    $Pools.where({ $_.Updated -lt $Session.CycleStarts[0] }).ForEach({ $_.Price_Bias *= [Math]::Pow(0.9, ($Session.CycleStarts[0] - $_.Updated).TotalMinutes) })

                    # Pool disabled by stat file
                    $Pools.where({ $_.Disabled }).ForEach({ $_.Reasons.Add("Disabled (by stat file)") | Out-Null })
                    # Min accuracy not reached
                    $Pools.where({ $_.Accuracy -lt $Session.Config.MinAccuracy }).ForEach({ $_.Reasons.Add("MinAccuracy ($($Session.Config.MinAccuracy * 100)%) not reached") | Out-Null })
                    # Filter unavailable algorithms
                    if (-not $Session.Config.UseUnprofitableAlgorithms) { $Pools.where({ $Session.UnprofitableAlgorithms[$_.Algorithm] -eq "*" }).ForEach({ $_.Reasons.Add("Unprofitable algorithm") | Out-Null }) }
                    # Pool price 0
                    $Pools.where({ $_.Price -eq 0 -and -not ($Session.Config.Pools[$_.Name].PoolAllow0Price -or $Session.Config.PoolAllow0Price) }).ForEach({ $_.Reasons.Add("Price -eq 0") | Out-Null })
                    # No price data
                    $Pools.where({ [Double]::IsNaN($_.Price) }).ForEach({ $_.Reasons.Add("Price information not available") | Out-Null })
                    # Ignore pool if price is more than $Session.Config.UnrealisticPoolPriceFactor higher than the medium price of all pools with same algorithm; NiceHash & MiningPoolHub are always right
                    if ($Session.Config.UnrealisticPoolPriceFactor -gt 1) { 
                        ($Pools.where({ $_.Price_Bias -gt 0 }) | Group-Object -Property Algorithm).where({ $_.Count -gt 3 }).ForEach(
                            { 
                                if ($PriceThreshold = (Get-Median $_.Group.Price_Bias) * $Session.Config.UnrealisticPoolPriceFactor) { 
                                    $_.Group.where({ $_.Name -notin @("NiceHash", "MiningPoolHub") -and $_.Price_Bias -gt $PriceThreshold }).ForEach({ $_.Reasons.Add("Unrealistic price (more than $($Session.Config.UnrealisticPoolPriceFactor)x higher than median price)") | Out-Null })
                                }
                            }
                        )
                        Remove-Variable PriceThreshold -ErrorAction Ignore
                    }
                    # Per pool config algorithm filter
                    $Pools.where({ $Session.Config.Pools[$_.Name].Algorithm -like "+*" -and $Session.Config.Pools[$_.Name].Algorithm -split "," -notcontains "+$($_.AlgorithmVariant)" -and $Session.Config.Pools[$_.Name].Algorithm -split "," -notcontains "+$($_.Algorithm)" }).ForEach({ $_.Reasons.Add("Algorithm not enabled in $($_.Name) pool config") | Out-Null })
                    $Pools.where({ $Session.Config.Pools[$_.Name].Algorithm -split "," -contains "-$($_.Algorithm)" -or $Session.Config.Pools[$_.Name].Algorithm -split "," -contains "-$($_.AlgorithmVariant)" }).ForEach({ $_.Reasons.Add("Algorithm disabled (``-$($_.Algorithm)`` in $($_.Name) pool config)") | Out-Null })
                    # Filter non-enabled algorithms
                    if ($Session.Config.Algorithm -like "+*") { 
                        $IncludeAlgorithmNames = @($Session.Config.Algorithm -replace "^\+" | Select-Object)
                        $Pools.where({ $IncludeAlgorithmNames -notcontains $_.Algorithm -and $IncludeAlgorithmNames -notcontains $_.AlgorithmVariant }).ForEach({ $_.Reasons.Add("Algorithm not enabled in generic config") | Out-Null })
                        Remove-Variable IncludeAlgorithmNames
                    }
                    # Filter disabled algorithms
                    elseif ($Session.Config.Algorithm -like "-*") { 
                        $ExcludeAlgorithmNames = @($Session.Config.Algorithm -replace "^-" | Select-Object)
                        $Pools.where({ $ExcludeAlgorithmNames -contains $_.Algorithm }).ForEach({ $_.Reasons.Add("Algorithm disabled (``-$($_.Algorithm)`` in generic config)") | Out-Null })
                        $Pools.where({ $ExcludeAlgorithmNames -contains $_.AlgorithmVariant }).ForEach({ $_.Reasons.Add("Algorithm disabled (``-$($_.AlgorithmVariant)`` in generic config)") | Out-Null })
                        Remove-Variable ExcludeAlgorithmNames
                    }
                    # Per pool config currency filter
                    $Pools.where({ $Session.Config.Pools[$_.Name].Currency -like "+*" -and $Session.Config.Pools[$_.Name].Currency -split "," -notcontains "+$($_.Currency)" }).ForEach({ $_.Reasons.Add("Currency not enabled in $($_.Name) pool config") | Out-Null })
                    $Pools.where({ $Session.Config.Pools[$_.Name].Currency -split "," -contains "-$($_.Currency)" }).ForEach({ $_.Reasons.Add("Currency disabled (``-$($_.Currency)`` in $($_.Name) pool config)") | Out-Null })
                    # Filter non-enabled currencies
                    if ($Session.Config.Currency -like "+*") { $Pools.where({ $Session.Config.Currency -split "," -notcontains "+$($_.Currency)" }).ForEach({ $_.Reasons.Add("Currency not enabled in generic config") | Out-Null }) }
                    # Filter disabled currencies
                    elseif ($Session.Config.Currency -like "-*") { $Pools.where({ $Session.Config.Currency -split "," -contains "-$($_.Currency)" }).ForEach({ $_.Reasons.Add("Currency disabled (``-$($_.Currency)`` in generic config)") | Out-Null }) }
                    # MinWorkers
                    $Pools.where({ $null -ne $_.Workers -and $_.Workers -lt $Session.Config.Pools[$_.Name].MinWorkers }).ForEach({ $_.Reasons.Add("Not enough workers at pool (MinWorker ``$($Session.Config.Pools[$_.Name].MinWorker)`` in $($_.Name) pool config)") | Out-Null })
                    $Pools.where({ $null -ne $_.Workers -and $_.Workers -lt $Session.Config.MinWorker -and $Session.Config.Pools[$_.Name].MinWorkers -ne 0 -and $Session.Config.Pools[$_.Name].MinWorkers -lt $Session.Config.MinWorker }).ForEach({ $_.Reasons.Add("Not enough workers at pool (MinWorker ``$($Session.Config.MinWorker)`` in generic config)") | Out-Null })
                    # SSL
                    $Pools.where({ $Session.Config.Pools[$_.Name].SSL -eq "Never" }).ForEach({ $_.PoolPorts[1] = $null })
                    $Pools.where({ $Session.Config.Pools[$_.Name].SSL -eq "Always" }).ForEach({ $_.PoolPorts[0] = $null })
                    $Pools.where({ $Session.Config.Pools[$_.Name].SSL -eq "Never" -and -not $_.PoolPorts[0] }).ForEach({ $_.Reasons.Add("Non-SSL port not available (SSL -eq 'Never' in $($_.Name) pool config)") | Out-Null })
                    $Pools.where({ $Session.Config.Pools[$_.Name].SSL -eq "Always" -and -not $_.PoolPorts[1] }).ForEach({ $_.Reasons.Add("SSL port not available (SSL -eq 'Always' in $($_.Name) pool config)") | Out-Null })
                    if ($Session.Config.SSL -eq "Never") { $Pools.where({ -not $_.PoolPorts[0] -and $_.Reasons -notmatch "Non-SSL port not available .+" }).ForEach({ $_.Reasons.Add("Non-SSL port not available (SSL -eq 'Never' in generic config)") | Out-Null }) }
                    elseif ($Session.Config.SSL -eq "Always") { $Pools.where({ -not $_.PoolPorts[1] -and $_.Reasons -notmatch "SSL port not available .+" }).ForEach({ $_.Reasons.Add("SSL port not available (SSL -eq 'Always' in generic config)") | Out-Null }) }
                    # SSL Allow selfsigned certificate
                    $Pools.where({ $_.SSLselfSignedCertificate -and $null -ne $Session.Config.Pools[$_.Name].SSLallowSelfSignedCertificate -and $Session.Config.Pools[$_.Name].SSLallowSelfSignedCertificate -eq $false }).ForEach({ $_.Reasons.Add("Pool uses self signed certificate (SSLallowSelfSignedCertificate -eq '`$false' in $($_.Name) pool config)") | Out-Null })
                    if (-not $Session.Config.SSLallowSelfSignedCertificate) { $Pools.where({ $_.SSLselfSignedCertificate -and $null -eq $Session.Config.Pools[$_.Name].SSLallowSelfSignedCertificate }).ForEach({ $_.Reasons.Add("Pool uses self signed certificate (SSLallowSelfSignedCertificate -eq '`$false' in generic config)") | Out-Null }) }
                    # At least one port (SSL or non-SSL) must be available
                    $Pools.where({ -not ($_.PoolPorts | Select-Object) }).ForEach({ $_.Reasons.Add("No ports available") | Out-Null })
                    # Apply watchdog to pools
                    if ($Pools.Count) { $Pools = Update-PoolWatchdog -Pools $Pools }
                    # Second best pools per algorithm
                    ($Pools.where({ -not $_.Reasons.Count }) | Group-Object -Property AlgorithmVariant, Name).ForEach({ ($_.Group | Sort-Object -Property Price_Bias -Descending | Select-Object -Skip 1).ForEach({ $_.Reasons.Add("Second best algorithm") | Out-Null }) })

                    # Make pools unavailable
                    $Pools.ForEach({ $_.Available = -not $_.Reasons.Count })

                    # Filter pools on miner set
                    if (-not $Session.Config.UseUnprofitableAlgorithms) { 
                        $Pools.where({ $Session.UnprofitableAlgorithms[$_.Algorithm] -eq 1 }).ForEach({ $_.Reasons.Add("Unprofitable primary algorithm") | Out-Null })
                        $Pools.where({ $Session.UnprofitableAlgorithms[$_.Algorithm] -eq 2 }).ForEach({ $_.Reasons.Add("Unprofitable secondary algorithm") | Out-Null })
                    }

                    $Message = if ($PoolsCount -gt 0) { "Had $($PoolsCount) pool$(if ($PoolsCount -ne 1) { "s" }) from previous run" } else { "Loaded $($Session.PoolsNew.Count) pool$(if ($Session.PoolsNew.Count -ne 1) { "s" })" }
                    if ($Session.PoolsExpired.Count) { $Message += ", expired $($Session.PoolsExpired.Count) pool$(if ($Session.PoolsExpired.Count -gt 1) { "s" })" }
                    if ($PoolsDeconfiguredCount) { $Message += ", removed $PoolsDeconfiguredCount deconfigured pool$(if ($PoolsDeconfiguredCount -gt 1) { "s" })" }
                    if ($Session.Pools.Count -and $Session.PoolsAdded.Count) { $Message += ", found $($Session.PoolsAdded.Count) new pool$(if ($Session.PoolsAdded.Count -ne 1) { "s" })" }
                    if ($Session.PoolsUpdated.Count) { $Message += ", updated $($Session.PoolsUpdated.Count) existing pool$(if ($Session.PoolsUpdated.Count -ne 1) { "s" })" }
                    if ($Pools.where({ -not $_.Available })) { $Message += ", filtered out $(@($Pools.where({ -not $_.Available })).Count) pool$(if (@($Pools.where({ -not $_.Available })).Count -ne 1) { "s" })" }
                    $Message += ". $(@($Pools.where({ $_.Available })).Count) available pool$(if (@($Pools.where({ $_.Available })).Count -ne 1) { "s" }) remain$(if (@($Pools.where({ $_.Available })).Count -eq 1) { "s" })."
                    Write-Message -Level Info $Message
                    Remove-Variable Message, PoolsCount

                    # Keep pool balances alive; force mining at pool even if it is not the best for the algo
                    if ($Session.Config.BalancesKeepAlive -and $Global:BalancesTrackerRunspace -and $Session.PoolsLastEarnings.Count -gt 0 -and $Session.PoolsLastUsed) { 
                        $Session.Config.PoolNamesToKeepBalancesAlive = @()
                        foreach ($Pool in @($Pools.where({ $_.Name -notin $Session.Config.BalancesTrackerExcludePool }) | Sort-Object -Property Name -Unique)) { 
                            if ($Session.PoolsLastEarnings[$Pool.Name] -and $Session.Config.Pools[$Pool.Name].BalancesKeepAlive -gt 0 -and ([DateTime]::Now.ToUniversalTime() - $Session.PoolsLastEarnings[$Pool.Name]).Days -ge ($Session.Config.Pools[$Pool.Name].BalancesKeepAlive - 10)) { 
                                $Session.Config.PoolNamesToKeepBalancesAlive += $Pool.Name
                                Write-Message -Level Warn "Pool '$($Pool.Name)' prioritized to avoid forfeiting balance (pool would clear balance in 10 days)."
                            }
                        }
                        Remove-Variable Pool

                        if ($Session.Config.PoolNamesToKeepBalancesAlive) { 
                            $Pools.ForEach(
                                { 
                                    if ($Session.Config.PoolNamesToKeepBalancesAlive -contains $_.Name) { $_.Available = $true; $_.Prioritize = $true }
                                    else { $_.Reasons.Add("BalancesKeepAlive prioritizes other pools") | Out-Null }
                                }
                            )
                        }
                    }


                    # Mark best pools, allow all DAG pools (optimal pool might not fit in GPU memory)
                    ($Pools.where({ $_.Available }) | Group-Object -Property Algorithm).ForEach({ ($_.Group | Sort-Object -Property Prioritize, Price_Bias -Bottom $(if ($Session.Config.MinerUseBestPoolsOnly -or $_.Group.Algorithm -notmatch $Session.RegexAlgoHasDAG) { 1 } else { $_.Group.Count })).ForEach({ $_.Best = $true }) })
                }
                $Session.PoolsUpdatedTimestamp = [DateTime]::Now.ToUniversalTime()

                # Update data in API
                $Session.Pools = $Pools
                $Session.PoolsBest = $Session.Pools.where({ $_.Best }) | Sort-Object -Property Algorithm

                Remove-Variable Pools, PoolsDeconfiguredCount, PoolsExpiredCount -ErrorAction Ignore

                # Core suspended with <Ctrl><Alt>P in MainLoop
                while ($Session.SuspendCycle) { Start-Sleep -Seconds 1 }

            }
        }
        if (-not $Session.PoolsBest) { 
            $Message = "No minable pools - will retry in $($Session.Config.Interval) seconds..."
            Write-Message -Level Warn $Message
            $Session.Summary = $Message
            Remove-Variable Message

            Clear-PoolData
            Clear-MinerData

            $Session.RefreshNeeded = $true

            Start-Sleep -Seconds $Session.Config.Interval

            Write-Message -Level Info "Ending cycle."
            continue
        }

        if ($Session.Donation.Running) { $Session.EndCycleTime = ($Session.Donation.End).ToUniversalTime() }

        # Ensure we get the hashrate for running miners prior looking for best miner
        foreach ($Miner in $Session.MinersBest) { 
            if ($Miner.DataReaderJob.HasMoreData -and $Miner.Status -ne [MinerStatus]::DryRun) { 
                if ($Samples = @($Miner.DataReaderJob | Receive-Job).where({ $_.Date })) { 
                    $Sample = $Samples[-1]
                    if ([Math]::Floor(($Sample.Date - $Miner.ValidDataSampleTimestamp).TotalSeconds) -ge 0) { $Samples.where({ $_.Hashrate.PSObject.Properties.Value -notcontains 0 }).ForEach({ $Miner.Data.Add($_) | Out-Null }) }
                    $Miner.Hashrates_Live = $Sample.Hashrate.PSObject.Properties.Value
                    # Hashrate from primary algorithm is relevant
                    if ($Sample.Hashrate.($Miner.Algorithms[0])) { $Miner.DataSampleTimestamp = $Sample.Date }
                }
                Remove-Variable Sample, Samples -ErrorAction Ignore
            }
            if ($Miner.Data.Count -gt $Miner.MinDataSample * 5) { $Miner.Data = [System.Collections.Generic.List[PSCustomObject]]($Miner.Data | Select-Object -Last ($Miner.MinDataSample * 5)) } # Reduce data to MinDataSample * 5

            if ([MinerStatus]::DryRun, [MinerStatus]::Running -contains $Miner.Status) { 
                if ($Miner.Status -eq [MinerStatus]::DryRun -or $Miner.GetStatus() -eq [MinerStatus]::Running) { 
                    $Miner.ContinousCycle ++
                    if ($Session.Config.Watchdog) { 
                        foreach ($Worker in $Miner.WorkersRunning) { 
                            if ($WatchdogTimer = $Session.WatchdogTimers.where({ $_.MinerName -eq $Miner.Name -and $_.PoolName -eq $Worker.Pool.Name -and $_.PoolRegion -eq $Worker.Pool.Region -and $_.Algorithm -eq $Worker.Pool.Algorithm }) | Sort-Object -Property Kicked -Bottom 1) { 
                                # Update watchdog timer
                                $WatchdogTimer.Kicked = [DateTime]::Now.ToUniversalTime()
                            }
                            else { 
                                # Create watchdog timer in case it got cleared
                                $Session.WatchdogTimers.Add(
                                    [PSCustomObject]@{ 
                                        Algorithm                    = $Worker.Pool.Algorithm
                                        AlgorithmVariant             = $Worker.Pool.AlgorithmVariant
                                        CommandLine                  = $Miner.CommandLine
                                        DeviceNames                  = $Miner.DeviceNames
                                        Kicked                       = [DateTime]::Now.ToUniversalTime()
                                        MinerBaseName                = $Miner.BaseName
                                        MinerBaseName_Version        = $Miner.BaseName_Version
                                        MinerBaseName_Version_Device = $Miner.BaseName_Version_Device
                                        MinerName                    = $Miner.Name
                                        MinerVersion                 = $Miner.Version
                                        PoolKey                      = $Worker.Pool.Key
                                        PoolName                     = $Worker.Pool.Name
                                        PoolRegion                   = $Worker.Pool.Region
                                        PoolVariant                  = $Worker.Pool.Variant
                                    }
                                )
                            }
                        }
                        Remove-Variable WatchdogTimer, Worker -ErrorAction Ignore
                    }
                    if ($Miner.Status -eq [MinerStatus]::Running -and $Session.Config.BadShareRatioThreshold -gt 0) { 
                        if ($Shares = ($Miner.Data | Select-Object -Last 1).Shares) { 
                            foreach ($Algorithm in $Miner.Algorithms) { 
                                if ($Shares.$Algorithm -and $Shares.$Algorithm[1] -gt 0 -and $Shares.$Algorithm[3] -gt [Math]::Floor(1 / $Session.Config.BadShareRatioThreshold) -and $Shares.$Algorithm[1] / $Shares.$Algorithm[3] -gt $Session.Config.BadShareRatioThreshold) { 
                                    $Miner.StatusInfo = "$($Miner.Info) stopped. Too many bad shares: ($($Algorithm): A$($Shares.$Algorithm[0])+R$($Shares.$Algorithm[1])+I$($Shares.$Algorithm[2])=T$($Shares.$Algorithm[3]))"
                                    Write-Message -Level Error "Miner $($Miner.StatusInfo)"
                                    $Miner.Data = [System.Collections.Generic.HashSet[PSCustomObject]]::new()
                                    $Miner.SetStatus([MinerStatus]::Failed)
                                    $Session.Devices.where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                                }
                            }
                        }
                        Remove-Variable Algorithm, Shares -ErrorAction Ignore
                    }
                }
                else { 
                    $Miner.StatusInfo = "$($Miner.Info) ($($Miner.Data.Count) sample$(if ($Miner.Data.Count -ne 1) { "s" })) exited unexpectedly"
                    Write-Message -Level Error "Miner $($Miner.StatusInfo)"
                    $Miner.SetStatus([MinerStatus]::Failed)
                    $Session.Devices.where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                }
            }

            # Do not save data if stat just got removed (Miner.Activated < 1, set by API)
            if ($Miner.Activated -gt 0 -and $Miner.Status -ne [MinerStatus]::DryRun) { 
                $MinerHashrates = @{ }
                if ($Miner.Data.Count) { 
                    # Collect hashrate from miner, returns an array of two values (safe, unsafe)
                    $Miner.Hashrates_Live = @()
                    foreach ($Algorithm in $Miner.Algorithms) { 
                        $CollectedHashrate = $Miner.CollectHashrate($Algorithm, (-not $Miner.Benchmark -and $Miner.Data.Count -lt $Miner.MinDataSample))
                        $MinerHashrates.$Algorithm = $CollectedHashrate[0]
                        $Miner.Hashrates_Live += $CollectedHashrate[1]
                    }
                    if ($Miner.ReadPowerConsumption) { 
                        # Collect power consumption from miner, returns an array of two values (safe, unsafe)
                        $CollectedPowerConsumption = $Miner.CollectPowerConsumption(-not $Miner.MeasurePowerConsumption -and $Miner.Data.Count -lt $Miner.MinDataSample)
                        $MinerPowerConsumption = $CollectedPowerConsumption[0]
                        $Miner.PowerConsumption_Live = $CollectedPowerConsumption[1]
                    }
                }

                # We don't want to store hashrates or power consumption if we have less than $MinDataSample
                if ($Miner.Data.Count -ge $Miner.MinDataSample -or $Miner.Activated -gt $Session.WatchdogCount) { 
                    $Miner.StatEnd = [DateTime]::Now.ToUniversalTime()
                    $StatSpan = [TimeSpan]($Miner.StatEnd - $Miner.StatStart)

                    foreach ($Worker in $Miner.Workers) { 
                        $Algorithm = $Worker.Pool.Algorithm
                        $MinerData = ($Miner.Data | Select-Object -Last 1).Shares
                        if ($Miner.Data.Count -gt $Miner.MinDataSample -and -not $Miner.Benchmark -and $Session.Config.SubtractBadShares -and $MinerData.$Algorithm -gt 0) { 
                            # Need $Miner.MinDataSample shares before adjusting hashrate
                            $Factor = (1 - $MinerData.$Algorithm[1] / $MinerData.$Algorithm[3])
                            $MinerHashrates.$Algorithm *= $Factor
                        }
                        else { 
                            $Factor = 1
                        }
                        $StatName = "$($Miner.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                        $Stat = Set-Stat -Name $StatName -Value $MinerHashrates.$Algorithm -Duration $StatSpan -FaultDetection ($Miner.Data.Count -lt $Miner.MinDataSample -or $Miner.Activated -lt $Session.WatchdogCount) -ToleranceExceeded ($Session.WatchdogCount + 1)
                        if ($Stat.Updated -gt $Miner.StatStart) { 
                            Write-Message -Level Info "Saved hashrate for '$($Miner.Name)'$(if ($Miner.Workers.Count -gt 1) { " [$($Worker.Pool.Algorithm)]" }): $(($MinerHashrates.$Algorithm | ConvertTo-Hash) -replace " ")$(if ($Factor -le 0.999) { " (adjusted by factor $($Factor.ToString("N3")) [Shares: A$($MinerData.$Algorithm[0])|R$($MinerData.$Algorithm[1])|I$($MinerData.$Algorithm[2])|T$($MinerData.$Algorithm[3])])" }) ($($Miner.Data.Count) sample$(if ($Miner.Data.Count -ne 1) { "s" }))$(if ($Miner.Benchmark) { " [Benchmark done]" })."
                            $Session.AlgorithmsLastUsed.($Worker.Pool.Algorithm) = @{ Updated = $Stat.Updated; Benchmark = $Miner.Benchmark; MinerName = $Miner.Name }
                            $Session.PoolsLastUsed.($Worker.Pool.Name) = $Stat.Updated # most likely this will count at the pool to keep balances alive
                        }
                        elseif ($Stat.Week) { 
                            if ($MinerHashrates.$Algorithm -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and ($MinerHashrates.$Algorithm -gt $Stat.Week * 2 -or $MinerHashrates.$Algorithm -lt $Stat.Week / 2)) { 
                                # Stop miner if new value is outside ±200% of current value
                                Write-Message -Level Warn "Reported hashrate by '$($Miner.Name)' is unrealistic ($($Algorithm): $(($MinerHashrates.$Algorithm | ConvertTo-Hash) -replace " ") is not within ±200% of stored value of $(($Stat.Week | ConvertTo-Hash) -replace " "))"
                                $Miner.SetStatus([MinerStatus]::Idle)
                                $Session.Devices.where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                                if ($Stat.ToleranceExceeded -ge $Session.Config.WatchdogCount) { Remove-Stat $StatName }
                            }
                        }
                    }
                    Remove-Variable Factor -ErrorAction Ignore

                    $Session.MinersLastUsed.($Miner.Name) = @{ Updated = $Stat.Updated; Benchmark = $Miner.Benchmark; Info = $Miner.Info }

                    if ($Miner.ReadPowerConsumption) { 
                        if ([Double]::IsNaN($MinerPowerConsumption )) { $MinerPowerConsumption = 0 }
                        $StatName = "$($Miner.Name)_PowerConsumption"
                        # Always update power consumption when benchmarking
                        $Stat = Set-Stat -Name $StatName -Value $MinerPowerConsumption -Duration $StatSpan -FaultDetection (-not $Miner.Benchmark -and ($Miner.Data.Count -lt $Miner.MinDataSample -or $Miner.Activated -lt $Session.WatchdogCount)) -ToleranceExceeded ($Session.WatchdogCount + 1)
                        if ($Stat.Updated -gt $Miner.StatStart) { 
                            Write-Message -Level Info "Saved power consumption for '$($Miner.Name)': $($Stat.Live.ToString("N2"))W ($($Miner.Data.Count) sample$(if ($Miner.Data.Count -ne 1) { "s" }))$(if ($Miner.MeasurePowerConsumption) { " [Power consumption measurement done]" })."
                        }
                        elseif ($Stat.Week) { 
                            if ($MinerPowerConsumption -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and ($MinerPowerConsumption -gt $Stat.Week * 2 -or $MinerPowerConsumption -lt $Stat.Week / 2)) { 
                                # Stop miner if new value is outside ±200% of current value
                                Write-Message -Level Warn "Reported power consumption by '$($Miner.Name)' is unrealistic ($($MinerPowerConsumption.ToString("N2"))W is not within ±200% of stored value of $(([Double]$Stat.Week).ToString("N2"))W)"
                                $Miner.SetStatus([MinerStatus]::Idle)
                                $Session.Devices.where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                                if ($Stat.ToleranceExceeded -ge $Session.Config.WatchdogCount) { Remove-Stat $StatName }
                            }
                        }
                    }
                }
                Remove-Variable Algorithm, CollectedHashrateFactor, CollectedPowerConsumption, MinerData, MinerHashrates, MinerPowerConsumption, Stat, StatName, StatSpan, Worker -ErrorAction Ignore
            }
        }
        Remove-Variable Miner -ErrorAction Ignore

        if ($Session.AlgorithmsLastUsed.Values.Updated -gt $Session.BeginCycleTime) { $Session.AlgorithmsLastUsed | ConvertTo-Json | Out-File -LiteralPath ".\Data\AlgorithmsLastUsed.json" -Force }
        if ($Session.MinersLastUsed.Values.Updated -gt $Session.BeginCycleTime) { $Session.MinersLastUsed | ConvertTo-Json | Out-File -LiteralPath ".\Data\MinersLastUsed.json" -Force }
        # Update pools last used data, required for BalancesKeepAlive
        if ($Session.PoolsLastUsed.Values -gt $Session.BeginCycleTime) { $Session.PoolsLastUsed | ConvertTo-Json | Out-File -LiteralPath ".\Data\PoolsLastUsed.json" -Force }

        # Send data to monitoring server
        # if ($Session.Config.ReportToServer) { Write-MonitoringData }

        # Core suspended with <Ctrl><Alt>P in MainLoop
        while ($Session.SuspendCycle) { Start-Sleep -Seconds 1 }

        # Get new miners
        if ($AvailableMinerPools = if ($Session.Config.MinerUseBestPoolsOnly) { $Session.Pools.where({ $_.Available -and ($_.Best -or $_.Prioritize) }) } else { $Session.Pools.where({ $_.Available }) }) { 
            $MinerPools = [System.Collections.SortedList]::new([StringComparer]::OrdinalIgnoreCase), [System.Collections.SortedList]::new([StringComparer]::OrdinalIgnoreCase)
            $MinerPools[1]."" = ""
            if ($Session.Config.UseUnprofitableAlgorithms) { 
                ($AvailableMinerPools | Group-Object -Property Algorithm).ForEach({ $MinerPools[0][$_.Name] = $_.Group })
                ($AvailableMinerPools | Group-Object -Property Algorithm).ForEach({ $MinerPools[1][$_.Name] = $_.Group })
            }
            Else { 
                ($AvailableMinerPools.where({ $Session.UnprofitableAlgorithms[$_.Algorithm] -notmatch "\*|1" }) | Group-Object -Property Algorithm).ForEach({ $MinerPools[0][$_.Name] = $_.Group })
                ($AvailableMinerPools.where({ $Session.UnprofitableAlgorithms[$_.Algorithm] -notmatch "\*|2" }) | Group-Object -Property Algorithm).ForEach({ $MinerPools[1][$_.Name] = $_.Group })
            }

            $Message = "Loading miners.$(if (-not $Session.Miners) { "<br>This may take a while." }).."
            if (-not $Session.Miners) { 
                $Session.Summary = $Message
                $Session.RefreshNeeded = $true
            }
            Write-Message -Level Info ($Message -replace "<br>", " ")
            Remove-Variable Message

            $MinersNew = (
                (Get-ChildItem -Path ".\Miners\*.ps1").ForEach(
                    { 
                        $MinerFileName = $_.Name
                        try { 
                            Write-Message -Level Debug "Miner definition file '$MinerFileName': Start building miner objects"
                            & $_.ResolvedTarget
                            Write-Message -Level Debug "Miner definition file '$MinerFileName': End building miner objects"
                        }
                        catch { 
                            Write-Message -Level Error "Miner file 'Miners\$MinerFileName': $_."
                            "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                            $_.Exception | Format-List -Force >> $ErrorLogFile
                            $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
                        }
                    }
                ).ForEach(
                    { 
                        $Miner = $_
                        try { 
                            foreach ($Worker in $Miner.Workers) { 
                                $Miner.Workers[$Miner.Workers.IndexOf($Worker)].Fee = if ($Session.Config.IgnoreMinerFee) { 0 } else { $Miner.Fee[$Miner.Workers.IndexOf($Worker)] }
                            }
                            $Miner.PSObject.Properties.Remove("Fee")
                            $Miner | Add-Member BaseName_Version_Device (($Miner.Name -split "-")[0..2] -join "-")
                            $Miner | Add-Member Info "$($Miner.BaseName_Version_Device) {$($Miner.Workers.ForEach({ $_.Pool.AlgorithmVariant, $_.Pool.Name -join "@" }) -join " & ")}$(if (($Miner.Name -split "-")[4]) { " ($(($Miner.Name -split "-")[4]))" })"
                            $Miner -as $Miner.API
                        }
                        catch { 
                            Write-Message -Level Error "Failed to add miner '$($Miner.Name)' as '$($Miner.API)' ($($Miner | ConvertTo-Json -Compress))"
                            "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                            $_.Exception | Format-List -Force >> $ErrorLogFile
                            $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
                        }
                    }
                )
             | Sort-Object -Property Info)
            Remove-Variable Algorithm, AvailableMinerPools, Miner, MinerFileName, MinerPools -ErrorAction Ignore

            if ($Session.Config.BenchmarkAllPoolAlgorithmCombinations) { $MinersNew.ForEach({ $_.Name = $_.Info }) }

            $Miners = Compare-Object @($Session.Miners | Sort-Object -Property Info) @($MinersNew) -Property Info -IncludeEqual -PassThru
            $MinerDevices = $Session.EnabledDevices | Select-Object -Property Bus, ConfiguredPowerConsumption, Name, ReadPowerConsumption, Status

            # Make smaller groups for faster update
            $MinersNewGroups = $MinersNew | Group-Object -Property BaseName_Version_Device
            ($Miners.where({ $_.SideIndicator -ne "<=" }) | Group-Object -Property BaseName_Version_Device).ForEach(
                { 
                    $Name = $_.Name
                    $MinersNewGroup = $MinersNewGroups.where({ $Name -eq $_.Name }).Group
                    $_.Group.ForEach(
                        { 
                            try { 
                                $Miner = $_
                                if ($_.SideIndicator -eq "=>") { 
                                    # Newly added miners, these properties need to be set only once because they are not dependent on any config or pool information
                                    $_.BaseName = ($_.Name -split "-")[0]
                                    $_.Version = ($_.Name -split "-")[1]
                                    $_.BaseName_Version = "$($_.BaseName)-$($_.Version)"

                                    $_.Algorithms = $_.Workers.Pool.Algorithm
                                    $_.CommandLine = $_.GetCommandLine()
                                    $_.Devices = [System.Collections.Generic.SortedSet[Object]]::new($MinerDevices.where({ $Miner.DeviceNames -contains $_.Name }))
                                }
                                elseif ($Miner = $MinersNewGroup.where({ $Miner.Info -eq $_.Info })) { 
                                    if ($_.KeepRunning = [MinerStatus]::Running, [MinerStatus]::DryRun -contains $_.Status -and $_.ContinousCycle -lt $Session.Config.MinCycle) { 
                                        # Minimum numbers of cycles not yet reached
                                        $_.Restart = $false
                                    }
                                    # Update existing miners
                                    elseif ($_.Restart = $_.Arguments -ne $Miner.Arguments) { 
                                        $_.Arguments = $Miner.Arguments
                                        $_.CommandLine = $Miner.GetCommandLine()
                                        $_.Port = $Miner.Port
                                    }
                                    $_.PrerequisitePath = $Miner.PrerequisitePath
                                    $_.PrerequisiteURI = $Miner.PrerequisiteURI
                                    $_.Reasons = [System.Collections.Generic.SortedSet[String]]::new()
                                    $_.WarmupTimes = $Miner.WarmupTimes
                                    $_.Workers = $Miner.Workers
                                }
                                $_.MeasurePowerConsumption = $Session.CalculatePowerCost
                                $_.Refresh($Session.PowerCostBTCperW, $Session.Config)
                            }
                            catch { 
                                Write-Message -Level Error "Failed to update miner '$($Miner.Name)': Error $_ ($($Miner | ConvertTo-Json -Compress))"
                                "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                                $_.Exception | Format-List -Force >> $ErrorLogFile
                                $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
                            }
                        }
                    )
                }
            )
            Remove-Variable Info, Miner, MinersNew, MinersNewGroup, MinersNewGroups, Name -ErrorAction Ignore
        }

        # Core suspended with <Ctrl><Alt>P in MainLoop
        while ($Session.SuspendCycle) { Start-Sleep -Seconds 1 }

        # Mark miners that will be gone as not available
        $Miners.where({ (Compare-Object $MinerDevices.Name $_.DeviceNames -IncludeEqual | Where-Object -Property SideIndicator -EQ "=>")}).ForEach({ $_.SideIndicator = "!" })
        $Miners.where({ $_.Workers.Pool.Variant.where({ $_ -notin $Session.Config.PoolName }) }).ForEach({ $_.SideIndicator = "!" })
        $Miners.where({ $_.Updated -lt $Session.BeginCycleTime.AddDays(-1) }).ForEach({ $_.SideIndicator = "!" })
        $Miners.where({ -not $_.Workers.Pool[0].Available -or ($_.Workers.Pool[1] -and -not $_.Workers.Pool[1].Available) }).ForEach({ $_.SideIndicator = "!" })
        $Miners.where({ $_.SideIndicator -eq "!" }).ForEach({ $_.Available = $false; $_.Benchmark = $false; $_.Best = $false; $_.MeasurePowerConsumption = $false; $_.KeepRunning = $false })
        Remove-Variable MinerDevices

        $Miners.where({ $_.SideIndicator -eq "<=" }).ForEach({ $_.Benchmark = $false; $_.MeasurePowerConsumption = $false; $_.KeepRunning = $false })

        # Filter miners
        $Miners.where({ $_.Disabled }).ForEach({ $_.Reasons.Add("Disabled by user") | Out-Null })
        $ExcludeMinerNameRegex = ($Session.Config.ExcludeMinerName.ForEach({ "^$([Regex]::Escape($_))$" -replace "\\\*", ".*" })) -join "|"
        if ($Session.Config.ExcludeMinerName.Count) { $Miners.where({ $_.BaseName_Version_Device -match $ExcludeMinerNameRegex }).ForEach({ $_.Reasons.Add("ExcludeMinerName ($($Session.Config.ExcludeMinerName -join ", "))") | Out-Null }) }
        Remove-Variable ExcludeMinerNameRegex
        if (-not $Session.Config.PoolAllow0Price) { $Miners.where({ $_.Earnings -eq 0 }).ForEach({ $_.Reasons.Add("Earnings -eq 0") | Out-Null }) }
        $Miners.where({ -not $_.Benchmark -and $_.Workers.Hashrate -contains 0 }).ForEach({ $_.Reasons.Add("0 H/s stat file") | Out-Null })
        if ($Session.Config.DisableMinersWithFee) { $Miners.where({ $_.Workers.Fee }).ForEach({ $_.Reasons.Add("Config.DisableMinersWithFee") | Out-Null }) }
        if ($Session.Config.DisableDualAlgoMining) { $Miners.where({ $_.Workers.Count -eq 2 }).ForEach({ $_.Reasons.Add("Config.DisableDualAlgoMining") | Out-Null }) }
        if ($Session.Config.DisableSingleAlgoMining) { $Miners.where({ $_.Workers.Count -eq 1 }).ForEach({ $_.Reasons.Add("Config.DisableSingleAlgoMining") | Out-Null }) }

        # Add reason 'Config.DisableCpuMiningOnBattery' for CPU miners when running on battery
        if ($Session.Config.DisableCpuMiningOnBattery -and (Get-CimInstance Win32_Battery).BatteryStatus -eq 1) { $Miners.where({ $_.Type -eq "CPU" }).ForEach({ $_.Reasons.Add("Config.DisableCpuMiningOnBattery") | Out-Null }) }

        # Add reason 'Unrealistic earnings...' for miners with earnings > x times higher than any other miner for this device
        if ($Session.Config.UnrealisticAlgorithmDeviceEarningsFactor -gt 1) { 
            ($Miners.where({ $_.Available -and -not $_.Reasons.Count -and -not $_.Benchmark -and -not $_.MeasurePowerConsumption }) | Group-Object { $_.BaseName_Version_Device -replace ".+-" }).ForEach(
                { 
                    $HighestEarningAlgorithm = ($_.Group | Sort-Object -Property Earnings_Bias -Descending | Select-Object -Index 0).Workers.Pool.Algorithm -join " "
                    if ($ReasonableEarnings = ($_.Group.where({ ($_.Workers.Pool.Algorithm -join " ") -ne $HighestEarningAlgorithm }) | Sort-Object -Property Earnings_Bias -Descending | Select-Object -Index 0).Earnings_Bias * $Session.Config.UnrealisticAlgorithmDeviceEarningsFactor) { 
                        $Group = $_.Group.where({ $_.Earnings -gt $ReasonableEarnings })
                        $Group.ForEach(
                            { 
                                $_.Reasons.Add("Unrealistic earnings (biased earnings more than $($Session.Config.UnrealisticAlgorithmDeviceEarningsFactor)x higher than any other miner for this device & algorithm)") | Out-Null
                            }
                        )
                    }
                }
            )
            Remove-Variable Group, HighestEarningAlgorithm, ReasonableEarnings -ErrorAction Ignore
        }

        # Add reason 'Unrealistic earnings (biased earnings...' for miners with unrealistic earnings > x times higher than average of the next best 10% or at least 5 available miners
        if ($Session.Config.UnrealisticMinerEarningsFactor -gt 1) { 
            ($Miners.where({ $_.Available -and -not $_.Reasons.Count -and -not $_.Benchmark -and -not $_.MeasurePowerConsumption }) | Group-Object { $_.BaseName_Version_Device -replace ".+-" }).ForEach(
                { 
                    if ($ReasonableEarnings = [Double]($_.Group | Sort-Object -Property Earnings_Bias -Descending | Select-Object -Skip 1 -First (5, [Math]::Floor($_.Group.Count / 10) | Measure-Object -Maximum).Maximum | Measure-Object Earnings_Bias -Average).Average * $Session.Config.UnrealisticMinerEarningsFactor) { 
                        $Group = $_.Group.where({ $_.Group.Count -ge 5 -and $_.Earnings -gt $ReasonableEarnings })
                        $Group.ForEach(
                            { 
                                $_.Reasons.Add("Unrealistic earnings (biased earnings more than $($Session.Config.UnrealisticMinerEarningsFactor)x higher than the next best $($Group.Count - 1) miners available miners)") | Out-Null
                            }
                        )
                    }
                }
            )
            Remove-Variable Group, ReasonableEarnings -ErrorAction Ignore
        }

        $Session.MinersMissingBinary = ($Miners.where({ -not $_.Reasons.Count }) | Group-Object -Property Path).where({ -not (Test-Path -LiteralPath $_.Name -Type Leaf) }).Group.ForEach(
            { 
                $_.Reasons.Add("Binary missing") | Out-Null
                $_
            }
        )

        $Session.MinersMissingPrerequisite = ($Miners.where({ $_.PrerequisitePath }) | Group-Object -Property PrerequisitePath).where({ -not (Test-Path -LiteralPath $_.Name -Type Leaf) }).Group.ForEach(
            { 
                $_.Reasons.Add("Prerequisite missing ($(Split-Path -Path $_.PrerequisitePath -Leaf))") | Out-Null
                $_
            }
        )

        if ($DownloadList = @($Session.MinersMissingBinary | Sort-Object Uri -Unique | Select-Object URI, Path, @{ Name = "Searchable"; Expression = { $false } }, @{ Name = "Type"; Expression = { "miner binary" } }) + @($Session.MinersMissingPrerequisite | Sort-Object PrerequisiteURI -Unique | Select-Object @{ Name = "URI"; Expression = { $_.PrerequisiteURI } }, @{ Name = "Path"; Expression = { $_.PrerequisitePath } }, @{ Name = "Searchable"; Expression = { $false } }, @{ Name = "Type"; Expression = { "miner pre-requisite" } })) { 
            if ($Session.Downloader.State -ne "Running") { 
                # Download miner binaries
                Write-Message -Level Info "Some files are missing ($($DownloadList.Count) item$(if ($DownloadList.Count -ne 1) { "s" })). Starting downloader..."
                $DownloaderParameters = @{ 
                    Config       = $Session.Config
                    DownloadList = $DownloadList
                    Session      = $Session
                }
                $Session.Downloader = Start-ThreadJob -Name Downloader -StreamingHost $null -FilePath ".\Includes\Downloader.ps1" -InitializationScript ([ScriptBlock]::Create("Set-Location '$($Session.MainPath)'")) -ArgumentList $DownloaderParameters
                Remove-Variable DownloaderParameters
            }
        }
        Remove-Variable DownloadList

        # Open firewall ports for all miners
        if ($Session.Config.OpenFirewallPorts) { 
            if (Get-Command Get-MpPreference) { 
                if ((Get-Command Get-MpComputerStatus) -and (Get-MpComputerStatus)) { 
                    if (Get-Command Get-NetFirewallRule) { 
                        if ($MissingFirewallRules = (Compare-Object @(Get-NetFirewallApplicationFilter | Select-Object -ExpandProperty Program -Unique | Sort-Object) @(($Miners.Path | Sort-Object -Unique).ForEach({ "$PWD\$($_)" })) -PassThru).where({ $_.SideIndicator -eq "=>" })) { 
                            try { 
                                if (-not $Session.IsLocalAdmin) { 
                                    Write-Message -Level Info "Initiating request to add inbound firewall rule$(if ($MissingFirewallRules.Count -ne 1) { "s" }) for $($MissingFirewallRules.Count) miner$(if ($MissingFirewallRules.Count -ne 1) { "s" })..."
                                    Start-Process "pwsh" ("-Command Write-Host 'Adding inbound firewall rule$(if ($MissingFirewallRules.Count -ne 1) { "s" }) for $($MissingFirewallRules.Count) miner$(if ($MissingFirewallRules.Count -ne 1) { "s" })...';  Write-Host ''; Import-Module NetSecurity; ('$($MissingFirewallRules | ConvertTo-Json -Compress)' | ConvertFrom-Json).ForEach({ New-NetFirewallRule -DisplayName (Split-Path `$_ | Split-Path -leaf) -Program `$_ -Description 'Inbound rule added by $($Session.Branding.ProductLabel) $($Session.Branding.Version) on $([DateTime]::Now.ToString())' -Group '$($Session.Branding.ProductLabel)' | Out-Null; `$Message = 'Added inbound firewall rule for ' + (Split-Path `$_ | Split-Path -leaf) + '.'; Write-Host `$Message }); Write-Host ''; Write-Host 'Added $($MissingFirewallRules.Count) inbound firewall rule$(if ($MissingFirewallRules.Count -ne 1) { "s" }).'; Start-Sleep -Seconds 3" -replace "`"", "\`"") -Verb runAs
                                }
                                else { 
                                    Import-Module NetSecurity
                                    $MissingFirewallRules.ForEach({ New-NetFirewallRule -DisplayName (Split-Path $_ | Split-Path -Leaf) -Program $_ -Description "Inbound rule added by $($Session.Branding.ProductLabel) $($Session.Branding.Version) on $([DateTime]::Now.ToString())" -Group $($Session.Branding.ProductLabel) })
                                }
                                Write-Message -Level Info "Added $($MissingFirewallRules.Count) inbound firewall rule$(if ($MissingFirewallRules.Count -ne 1) { "s" }) to Windows Defender inbound rules group '$($Session.Branding.ProductLabel)'."
                            }
                            catch { 
                                Write-Message -Level Error "Could not add inbound firewall rules. Some miners will not be available."
                                $Session.MinerMissingFirewallRule = $Miners.where({ $MissingFirewallRules -contains $_.Path })
                                $Session.MinerMissingFirewallRule.ForEach({ $_.Reasons.Add("Inbound firewall rule missing") | Out-Null })
                            }
                        }
                        Remove-Variable MissingFirewallRules
                    }
                }
            }
        }

        # Apply watchdog to miners
        if ($Session.Config.Watchdog) { 
            # We assume that miner is up and running, so watchdog timer is not relevant
            if ($RelevantWatchdogTimers = $Session.WatchdogTimers.where({ $_.MinerName -notin $Session.MinersRunning.Name })) { 
                # Only miners with a watchdog timer object are of interest
                if ($RelevantMiners = $Session.Miners.where({ $RelevantWatchdogTimers.MinerBaseName_Version -contains $_.BaseName_Version })) { 
                    # Add miner reason 'Miner suspended by watchdog [all algorithms & all devices]'
                    ($RelevantWatchdogTimers | Group-Object -Property MinerBaseName_Version).ForEach(
                        { 
                            if ($_.Count -gt 2 * $Session.WatchdogCount * ($_.Group[0].MinerName -split "&").Count * ($_.Group.DeviceNames | Sort-Object -Unique).Count) { 
                                $WatchdogGroup = $_.Group
                                if ($MinersToSuspend = $RelevantMiners.where({ $_.MinerBaseName_Version -eq $WatchdogGroup.Name })) { 
                                    $MinersToSuspend.ForEach({ $_.Reasons.Add("Miner suspended by watchdog [all algorithms & all devices]") | Out-Null })
                                    Write-Message -Level Warn "Miner '$($WatchdogGroup.Name) [all algorithms & all devices]' is suspended by watchdog until $(($WatchdogGroup.Kicked | Sort-Object -Top 1).AddSeconds($Session.WatchdogReset).ToLocalTime().ToString("T"))."
                                }
                            }
                        }
                    )
                    Remove-Variable MinersToSuspend, WatchdogGroup -ErrorAction Ignore

                    if ($RelevantMiners = $RelevantMiners.where({ -not ($_.Reasons -match "Miner suspended by watchdog .+") })) { 
                        # Add miner reason 'Miner suspended by watchdog [all algorithms]'
                        ($RelevantWatchdogTimers | Group-Object MinerBaseName_Version_Device).ForEach(
                            { 
                                if ($_.Count -gt 2 * $Session.WatchdogCount * ($_.Group[0].MinerName -split "&").Count) { 
                                    $WatchdogGroup = $_.Group
                                    if ($MinersToSuspend = $RelevantMiners.where({ $_.BaseName_Version_Device -eq $WatchdogGroup[0].MinerBaseName_Version_Device })) { 
                                        $MinersToSuspend.ForEach({ $_.Reasons.Add("Miner suspended by watchdog [all algorithms]") | Out-Null })
                                        Write-Message -Level Warn "Miner '$($WatchdogGroup[0].MinerBaseName_Version_Device) [all algorithms]' is suspended by watchdog until $(($WatchdogGroup.Kicked | Sort-Object -Top 1).AddSeconds($Session.WatchdogReset).ToLocalTime().ToString("T"))."
                                    }
                                }
                            }
                        )
                        Remove-Variable MinersToSuspend, WatchdogGroup -ErrorAction Ignore

                        if ($RelevantMiners = $RelevantMiners.where({ -not ($_.Reasons -match "Miner suspended by watchdog .+") })) { 
                            # Add miner reason 'Miner suspended by watchdog [Algorithm]'
                            ($RelevantWatchdogTimers.where({ $_.Algorithm -eq $_.AlgorithmVariant }) | Group-Object -Property MinerBaseName_Version_Device).ForEach(
                                { 
                                    if ($_.Count / ($_.Group[0].MinerName -split "&").Count -ge $Session.WatchdogCount) { 
                                        $WatchdogGroup = $_.Group
                                        if ($MinersToSuspend = $RelevantMiners.where({ $_.BaseName_Version_Device -eq $WatchdogGroup[0].MinerBaseName_Version_Device -and $_.Workers.Pool.Algorithm -contains $WatchdogGroup[0].Algorithm })) { 
                                            $MinersToSuspend.ForEach({ $_.Reasons.Add("Miner suspended by watchdog [Algorithm $($WatchdogGroup[0].Algorithm)]") | Out-Null })
                                            Write-Message -Level Warn "Miner '$($WatchdogGroup[0].MinerBaseName_Version_Device) [$($WatchdogGroup[0].Algorithm)]' is suspended by watchdog until $(($WatchdogGroup.Kicked | Sort-Object -Top 1).AddSeconds($Session.WatchdogReset).ToLocalTime().ToString("T"))."
                                        }
                                    }
                                }
                            )
                            Remove-Variable MinersToSuspend, WatchdogGroup -ErrorAction Ignore

                            if ($RelevantMiners = $RelevantMiners.where({ -not ($_.Reasons -match "Miner suspended by watchdog .+") })) { 
                                # Add miner reason 'Miner suspended by watchdog [AlgorithmVariant]'
                                ($RelevantWatchdogTimers.where({ $_.Algorithm -ne $_.AlgorithmVariant }) | Group-Object -Property MinerBaseName_Version_Device).ForEach(
                                    { 
                                        if ($_.Count / ($_.Group[0].MinerName -split "&").Count -ge $Session.WatchdogCount) { 
                                            $WatchdogGroup = $_.Group
                                            if ($MinersToSuspend = $RelevantMiners.where({ $_.BaseName_Version_Device -eq $WatchdogGroup[0].MinerBaseName_Version_Device -and $_.Workers.Pool.AlgorithmVariant -contains $WatchdogGroup[0].AlgorithmVariant })) { 
                                                $MinersToSuspend.ForEach({ $_.Reasons.Add("Miner suspended by watchdog [Algorithm $($WatchdogGroup[0].AlgorithmVariant)]") | Out-Null })
                                                Write-Message -Level Warn "Miner '$($WatchdogGroup[0].MinerBaseName_Version_Device) [$($WatchdogGroup[0].AlgorithmVariant)]' is suspended by watchdog until $(($WatchdogGroup.Kicked | Sort-Object -Top 1).AddSeconds($Session.WatchdogReset).ToLocalTime().ToString("T"))."
                                            }
                                        }
                                    }
                                )
                                Remove-Variable MinersToSuspend, WatchdogGroup -ErrorAction Ignore
                            }
                        }
                    }
                }
                Remove-Variable RelevantMiners -ErrorAction Ignore
            }
            Remove-Variable RelevantWatchdogTimers -ErrorAction Ignore
        }
        $Session.MinersUpdatedTimestamp = [DateTime]::Now.ToUniversalTime()

        $MinersAdded = $Miners.where({ $_.SideIndicator -eq "=>" })
        $MinersToBeRemoved = $Miners.where({ $_.SideIndicator -eq "!" })
        $Miners.where({ $_.Available }).ForEach({ $_.Available = -not $_.Reasons.Count })
        $MinersAvailableCount = $Miners.where({ $_.Available }).Count
        $MinersFilteredCount = $Miners.where({ -not $_.Available -and $_.SideIndicator -ne "!" }).Count
        $MinersUpdatedCount = $Miners.where({ $_.SideIndicator -eq "==" }).Count

        $Message = if ($Session.Miners) { "Had $($Session.Miners.Count) miner$(if ($Session.Miners.Count -ne 1) { "s" }) from previous run" } else { "Loaded $($Miners.Count) miner$(if ($Miners.Count -ne 1) { "s" })" }
        if ($Session.Miners.Count -and $MinersAdded.Count) { $Message += ", added $($MinersAdded.Count) miner$(if ($Miners.where({ $_.SideIndicator -ne "=>" }).Count -ne 1) { "s" })" }
        if ($MinersToBeRemoved.Count) { $Message += ", removed $($MinersToBeRemoved.Count) miner$(if ($MinersToBeRemoved.Count -ne 1) { "s" })" }
        if ($MinersUpdatedCount) { $Message += ", updated $MinersUpdatedCount existing miner$(if ($MinersUpdatedCount -ne 1) { "s" })" }
        if ($MinersFilteredCount) { $Message += ", filtered out $MinersFilteredCount miner$(if ($MinersFilteredCount -ne 1) { "s" })" }
        $Message += ". $MinersAvailableCount available miner$(if ($MinersAvailableCount -ne 1) { "s" }) remain$(if ($MinersAvailableCount -eq 1) { "s" })."
        Write-Message -Level Info $Message
        Remove-Variable Message, MinersAdded, MinersAvailableCount, MinersFilteredCount, MinersUpdatedCount

        if (-not $Miners.where({ $_.Available })) { 
            $Message = "No available miners - will retry in $($Session.Config.Interval) seconds..."
            Write-Message -Level Warn $Message
            $Session.Summary = $Message
            Remove-Variable Message

            Clear-MinerData -KeepMiners $true

            $Session.RefreshNeeded = $true

            Start-Sleep -Seconds $Session.Config.Interval

            Write-Message -Level Info "Ending cycle."
            continue
        }

        $Bias = if ($Session.CalculatePowerCost -and -not $Session.Config.IgnorePowerCost) { "Profit_Bias" } else { "Earnings_Bias" }
        if ($Miners.where({ $_.Available })) { 
            Write-Message -Level Info "Selecting best miner$(if (($Session.EnabledDevices.Model | Select-Object -Unique).Count -gt 1) { " combinations" }) based on$(if ($Session.CalculatePowerCost -and -not $Session.Config.IgnorePowerCost) { " profit (power cost $($Session.Config.FIATcurrency) $($Session.PowerPricekWh)/kW⋅h)" } else { " earnings" })..."

            if ($Miners.where({ $_.Available }).Count -eq 1) { 
                $MinersBest = $Session.MinersBestPerDevice = $MinersOptimal = $Miners.where({ $_.Available })
            }
            else { 
                # Add running miner bonus
                $RunningMinerBonusFactor = 1 + $Session.Config.MinerSwitchingThreshold / 100
                $Miners.where({ [MinerStatus]::DryRun, [MinerStatus]::Running -contains $_.Status }).ForEach({ $_.$Bias *= $RunningMinerBonusFactor })

                # Get the optimal miners per algorithm and device
                $MinersOptimal = ($Miners.where({ $_.Available -and -not ($_.Benchmark -or $_.MeasurePowerConsumption) }) | Group-Object { $_.BaseName_Version_Device -replace ".+-" }, { $_.Algorithms -join " " }).ForEach({ ($_.Group | Sort-Object -Descending -Property KeepRunning, Prioritize, $Bias, Activated, @{ Expression = { $_.WarmupTimes[1] + $_.MinDataSample }; Descending = $true }, @{ Expression = { $_.Algorithms -join " " }; Descending = $false } -Top 1).ForEach({ $_.Optimal = $true; $_ }) })
                # Get the best miners per device
                $Session.MinersBestPerDevice = ($Miners.where({ $_.Available }) | Group-Object { $_.BaseName_Version_Device -replace ".+-" }).ForEach({ $_.Group | Sort-Object -Descending -Property Benchmark, MeasurePowerConsumption, KeepRunning, Prioritize, $Bias, Activated, @{ Expression = { $_.WarmupTimes[1] + $_.MinDataSample }; Descending = $false } -Top 1 })

                # Hack: Temporarily make all bias -ge 0 by adding smallest bias, MinersBest produces wrong sort order when some profits are negative
                # Get smallest $Bias
                $SmallestBias = $Session.MinersBestPerDevice.$Bias | Sort-Object -Top 1

                $Session.MinersBestPerDevice.ForEach({ $_.$Bias += $SmallestBias })
                $MinerDeviceNamesCombinations = (Get-Combination @($Session.MinersBestPerDevice | Select-Object DeviceNames -Unique)).where({ (Compare-Object ($_.Combination | Select-Object -ExpandProperty DeviceNames -Unique) ($_.Combination | Select-Object -ExpandProperty DeviceNames) | Measure-Object).Count -eq 0 })

                # Get best miner combination i.e. AMD+INTEL+NVIDIA+CPU
                $MinerCombinations = $MinerDeviceNamesCombinations.ForEach(
                    { 
                        $DeviceNamesCombination = $_.Combination
                        [PSCustomObject]@{ 
                            Combination = $DeviceNamesCombination.ForEach(
                                { 
                                    $DeviceNames = $_.DeviceNames -join " "
                                    $Session.MinersBestPerDevice.where({ ($_.DeviceNames -join " ") -eq $DeviceNames })
                                }
                            )
                        }
                    }
                )
                $MinersBest = ($MinerCombinations | Sort-Object -Descending { $_.Combination.where({ $_.Benchmark }).Count }, { $_.Combination.where({ $_.MeasurePowerConsumption }).Count }, { $_.Combination.where({ [Double]::IsNaN($_.$Bias) }).Count }, { ($_.Combination.$Bias | Measure-Object -Sum).Sum }, { ($_.Combination.where({ $_.$Bias -ne 0 }) | Measure-Object).Count } -Top 1).Combination | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }

                # Revert smallest bias hack
                $Session.MinersBestPerDevice.ForEach({ $_.$Bias -= $SmallestBias })
                # Revert running miner bonus
                $Miners.where({ [MinerStatus]::DryRun, [MinerStatus]::Running -contains $_.Status }).ForEach({ $_.$Bias /= $RunningMinerBonusFactor })

                Remove-Variable DeviceNames, DeviceNamesCombination, MinerCombinations, MinerDeviceNamesCombinations, RunningMinerBonusFactor, SmallestBias -ErrorAction Ignore
            }

            $Session.PowerConsumptionIdleSystemW = (($Session.Config.PowerConsumptionIdleSystemW - ($MinersBest.where({ $_.Type -eq "CPU" }) | Measure-Object PowerConsumption -Sum).Sum), 0 | Measure-Object -Maximum).Maximum
            $Session.BasePowerCost = [Double]($Session.PowerConsumptionIdleSystemW / 1000 * 24 * $Session.PowerPricekWh / $Session.Rates.BTC.($Session.Config.FIATcurrency))
            $Session.MiningEarnings = [Double]($MinersBest | Measure-Object Earnings_Bias -Sum).Sum
            $Session.MiningPowerCost = [Double]($MinersBest | Measure-Object PowerCost -Sum).Sum
            $Session.MiningPowerConsumption = [Double]($MinersBest | Measure-Object PowerConsumption -Sum).Sum
            $Session.MiningProfit = [Double](($MinersBest | Measure-Object Profit_Bias -Sum).Sum - $Session.BasePowerCost)
        }
        else { 
            $Session.PowerConsumptionIdleSystemW = (($Session.Config.PowerConsumptionIdleSystemW), 0 | Measure-Object -Maximum).Maximum
            $Session.BasePowerCost = [Double]($Session.PowerConsumptionIdleSystemW / 1000 * 24 * $Session.PowerPricekWh / $Session.Rates.BTC.($Session.Config.FIATcurrency))
            $Session.MinersBestPerDevice = $MinersBest = $MinersOptimal = [Miner[]]@()
            $Session.MiningEarnings = $Session.MiningProfit = $Session.MiningPowerCost = $Session.MiningPowerConsumption = [Double]0
        }

        $Session.MinersNeedingBenchmark = $Miners.where({ $_.Available -and $_.Benchmark }) | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }, Info
        $Session.MinersNeedingPowerConsumptionMeasurement = $Miners.where({ $_.Available -and $_.MeasurePowerConsumption }) | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }, Info

        $Summary = ""
        if ($Session.Rates.($Session.Config.PayoutCurrency)) { 
            $PayoutCurrency = if ($Session.Config.PayoutCurrency -eq "BTC" -and $Session.Config.UsemBTC) { "mBTC" } else { $Session.Config.PayoutCurrency }
            # ProfitabilityThreshold check - OK to run miners?
            if ($Session.CalculatePowerCost -and ($Session.MiningProfit * $Session.Rates.BTC.($Session.Config.FIATcurrency)) -lt $Session.Config.ProfitabilityThreshold) { 
                # Mining earnings/profit is below threshold
                $MinersBest = [Miner[]]@()
                $Message = "Mining profit of {0} {1:n} / day is below the configured threshold of {0} {2:n} / day. Mining is suspended until the threshold is reached." -f $Session.Config.FIATcurrency, ($Session.MiningProfit * $Session.Rates.BTC.($Session.Config.FIATcurrency)), $Session.Config.ProfitabilityThreshold
                Write-Message -Level Warn ($Message -replace " / day", "/day")
                $Summary += "$Message`n"
                Remove-Variable Message
            }
            else { 
                $MinersBest.ForEach({ $_.Best = $true })

                if ($Session.MinersNeedingBenchmark.Count) { 
                    $Summary += "Earnings / day: n/a (Benchmarking: $($Session.MinersNeedingBenchmark.Count) miner$(if ($Session.MinersNeedingBenchmark.Count -ne 1) { "s" }) left [$((($Session.MinersNeedingBenchmark | Group-Object { $_.BaseName_Version_Device -replace ".+-" }).ForEach({ "$($_.Group[0].BaseName_Version_Device -replace(".+-")): $($_.Count)" }) | Sort-Object) -join ", ")])"
                }
                elseif ($Session.MiningEarnings -gt 0) { 
                    $Summary += "Earnings / day: {0:n} {1} ({2:N$(Get-DecimalsFromValue -Value ($Session.MiningProfit * ($Session.MiningProfit * $Session.Rates.BTC.$PayoutCurrency)) -DecimalsMax $Session.Config.DecimalsMax)} {3})" -f ($Session.MiningEarnings * $Session.Rates.BTC.($Session.Config.FIATcurrency)), $Session.Config.FIATcurrency, ($Session.MiningEarnings * $Session.Rates.BTC.$PayoutCurrency), $PayoutCurrency
                }

                if ($Session.CalculatePowerCost) { 
                    if ($Session.MinersNeedingPowerConsumptionMeasurement.Count -or [Double]::IsNaN($Session.MiningPowerCost)) { 
                        $Summary += "    Profit / day: n/a (Measuring power consumption: $($Session.MinersNeedingPowerConsumptionMeasurement.Count) miner$(if ($Session.MinersNeedingPowerConsumptionMeasurement.Count -ne 1) { "s" }) left [$((($Session.MinersNeedingPowerConsumptionMeasurement | Group-Object { $_.BaseName_Version_Device -replace ".+-" }).ForEach({ "$($_.Group[0].BaseName_Version_Device -replace(".+-")): $($_.Count)" }) | Sort-Object) -join ", ")])"
                    }
                    elseif ($Session.MinersNeedingBenchmark.Count) { 
                        $Summary += "    Profit / day: n/a"
                    }
                    elseif ($Session.MiningPowerConsumption -gt 0) { 
                        $Summary += "    Profit / day: {0:n} {1} ({2:N$(Get-DecimalsFromValue -Value ($Session.MiningProfit * $Session.Rates.BTC.$PayoutCurrency) -DecimalsMax $Session.Config.DecimalsMax)} {3})" -f ($Session.MiningProfit * $Session.Rates.BTC.($Session.Config.FIATcurrency)), $Session.Config.FIATcurrency, ($Session.MiningProfit * $Session.Rates.BTC.$PayoutCurrency), $PayoutCurrency
                    }
                    else { 
                        $Summary += "    Profit / day: n/a (no power data)"
                    }

                    if ([Double]::IsNaN($Session.MiningEarnings) -or [Double]::IsNaN($Session.MiningPowerCost)) { 
                        $Summary += "`nPower cost / day: n/a [Miner$(if ($MinersBest.Count -ne 1) { "s" }): n/a; Base: {1:n} {0} ({2:n2} W)]" -f $Session.Config.FIATcurrency, ($Session.BasePowerCost * $Session.Rates.BTC.($Session.Config.FIATcurrency)), $Session.PowerConsumptionIdleSystemW
                    }
                    elseif ($Session.MiningPowerConsumption -gt 0) { 
                        $Summary += "`nPower cost / day: {1:n} {0} [Miner$(if ($MinersBest.Count -ne 1) { "s" }): {2:n} {0} ({3:n2} W)$(if ($Session.PowerConsumptionIdleSystemW) { "; Base: {4:n} {0} ({5:n2} W)]" })" -f $Session.Config.FIATcurrency, (($Session.MiningPowerCost + $Session.BasePowerCost) * $Session.Rates.BTC.($Session.Config.FIATcurrency)), ($Session.MiningPowerCost * $Session.Rates.BTC.($Session.Config.FIATcurrency)), $Session.MiningPowerConsumption, ($Session.BasePowerCost * $Session.Rates.BTC.($Session.Config.FIATcurrency)), $Session.PowerConsumptionIdleSystemW
                    }
                    else { 
                        $Summary += "`nPower cost / day: n/a [Miner: n/a$(if ($Session.PowerConsumptionIdleSystemW) { "; Base: {1:n} {0} ({2:n2} W)]" })" -f $Session.Config.FIATcurrency, ($Session.BasePowerCost * $Session.Rates.BTC.($Session.Config.FIATcurrency)), $Session.PowerConsumptionIdleSystemW
                    }
                }
            }

            # Add currency conversion rates
            if ($Summary -ne "") { $Summary += "`n" }
            ((@(if ($Session.Config.UsemBTC) { "mBTC" } else { ($Session.Config.PayoutCurrency) }) + @($Session.Config.ExtraCurrencies)) | Select-Object -Unique).where({ $Session.Rates.$_.($Session.Config.FIATcurrency) }).ForEach(
                { 
                    $Summary += "1 $_ = {0:N$(Get-DecimalsFromValue -Value $Session.Rates.$_.($Session.Config.FIATcurrency) -DecimalsMax $Session.Config.DecimalsMax)} $($Session.Config.FIATcurrency)   " -f $Session.Rates.$_.($Session.Config.FIATcurrency)
                }
            )
            $Session.Summary = $Summary
            Remove-Variable PayoutCurrency, Summary
        }
        else { 
            $Message = "Error: Could not get BTC exchange rate from 'min-api.cryptocompare.com' for currency '$($Session.Config.PayoutCurrency)'. Cannot determine best miners to run - will retry in $($Session.Config.Interval) seconds..."
            Write-Message -Level Warn $Message
            $Session.Summary = $Message
            Remove-Variable Message

            Clear-PoolData
            Clear-MinerData

            $Session.RefreshNeeded = $true

            Start-Sleep -Seconds $Session.Config.Interval

            Write-Message -Level Info "Ending cycle."
            continue
        }

        foreach ($Miner in ($Miners.where({ [MinerStatus]::DryRun, [MinerStatus]::Running -contains $_.Status }) | Sort-Object { $_.BaseName_Version_Device -replace ".+-" })) { 
            if ($Miner.Status -eq [MinerStatus]::Running -and $Miner.GetStatus() -ne [MinerStatus]::Running) { 
                $Miner.StatusInfo = "$($Miner.Info) ($($Miner.Data.Count) sample$(if ($Miner.Data.Count -ne 1) { "s" })) exited unexpectedly"
                Write-Message -Level Error "Miner $($Miner.StatusInfo)"
                $Miner.SetStatus([MinerStatus]::Failed)
                $Session.Devices.where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
            }
            else { 
                if ($Miner.Benchmark -or $Miner.MeasurePowerConsumption) { 
                    if ($Miner.Activated -le 0 -or $Miner.Status -eq [MinerStatus]::DryRun ) { $Miner.Restart = $true } # Re-benchmark sets Activated to 0
                }
                elseif (($Session.Config.DryRun -and $Miner.Status -ne [MinerStatus]::DryRun) -or (-not $Session.Config.DryRun -and $Miner.Status -eq [MinerStatus]::DryRun)) { 
                    $Miner.Restart = $true
                }

                # Stop running miners
                if ($Miner.Disabled -or $Miner.Restart -or -not $Miner.Best -or $Session.NewMiningStatus -ne "Running") { 
                    foreach ($Worker in $Miner.WorkersRunning) { 
                        if ($WatchdogTimers = $Session.WatchdogTimers.where({ $_.MinerName -eq $Miner.Name -and $_.PoolName -eq $Worker.Pool.Name -and $_.PoolRegion -eq $Worker.Pool.Region -and $_.AlgorithmVariant -eq $Worker.Pool.AlgorithmVariant -and $_.DeviceNames -eq $Miner.DeviceNames })) { 
                            # Remove Watchdog timers
                            $Session.WatchdogTimers = $Session.WatchdogTimers.where({ $_ -notin $WatchdogTimers })
                        }
                    }
                    $Miner.SetStatus([MinerStatus]::Idle)
                    Remove-Variable WatchdogTimers, Worker -ErrorAction Ignore
                }
            }
            $Session.Devices.where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
        }
        Remove-Variable Miner -ErrorAction Ignore

        # Kill stuck miners on subsequent cycles
        $MinerPaths = ($Miners.Path | Sort-Object -Unique).ForEach({ "$PWD\$($_)" })
        $Loops = 0
        while ($StuckMinerProcesses = (Get-CimInstance CIM_Process).where({ $_.ExecutablePath -and $MinerPaths -contains $_.ExecutablePath -and $Miners.ProcessID -notcontains $_.ProcessID -and $Miners.ProcessID -notcontains $_.ParentProcessID }).ProcessId.ForEach({ (Get-Process -Id $_ -ErrorAction Ignore).where({ $_.MainWindowTitle -match ".+ \{.+@.+\}" }) })) { 
            foreach ($StuckMinerProcess in $StuckMinerProcesses) { 
                Stop-Process -Id $StuckMinerProcess.Id -Force -ErrorAction Ignore | Out-Null
                # Some miners, e.g. HellMiner spawn child process(es) that may need separate killing
                $ChildProcesses = (Get-CimInstance win32_process -Filter "ParentProcessId = $($StuckMinerProcess.Id)")
                $ChildProcesses.ForEach({ Stop-Process -Id $_.ProcessId -Force -ErrorAction Ignore })
                if (-not (Get-Process -Id $StuckMinerProcess.Id -ErrorAction Ignore)) { 
                    Write-Message -Level Warn "Successfully stopped stuck miner '$($StuckMinerProcess.MainWindowTitle -replace "\} .+", "}")'."
                }
                else { 
                    Write-Message -Level Warn "Found stuck miner '$($StuckMinerProcess.MainWindowTitle -replace "\} .+", "}")', trying to stop it..."
                }
            }
            Start-Sleep -Milliseconds 1000
            $Loops ++
            if ($Loops -gt 50) { 
                if ($Session.Config.AutoReboot) { 
                    Write-Message -Level Error "$(if ($StuckMinerProcesses.Count -eq 1) { "A miner is" } else { "Some miners are" }) stuck and cannot get stopped graciously. Restarting computer in 30 seconds..."
                    shutdown.exe /r /t 30 /c "$($Session.Branding.ProductLabel) detected stuck miner$(if ($StuckMinerProcesses.Count -ne 1) { "s" }) and will reboot the computer in 30 seconds."
                    Start-Sleep -Seconds 60
                }
                else { 
                    Write-Message -Level Error "$(if ($StuckMinerProcesses.Count -eq 1) { "A miner " } else { "Some miners are" }) stuck and cannot get stopped graciously. It is recommended to restart the computer."
                    Start-Sleep -Seconds 30
                }
            }
        }
        Remove-Variable ChildProcesses, Loops, MinerPaths, StuckMinerProcess, StuckMinerProcesses -ErrorAction Ignore

        # Remove miners
        $Miners = $Miners.where({ $_.SideIndicator -ne "!" })

        $Miners.ForEach(
            { 
                if ($_.Disabled) { 
                    $_.Status = [MinerStatus]::Disabled
                    $_.SubStatus = "disabled"
                }
                elseif (-not $_.Available) { 
                    $_.Status = [MinerStatus]::Unavailable
                    $_.SubStatus = "unavailable"
                }
                elseif ($_.Available -and $_.Status -notin [MinerStatus]::DryRun, [MinerStatus]::Running) { 
                    $_.Status = [MinerStatus]::Idle
                    $_.StatusInfo = $_.SubStatus = "idle"
                }
                elseif ($_.Status -eq [MinerStatus]::Failed) { 
                    $_.Status = [MinerStatus]::Idle
                    $_.StatusInfo = $_.SubStatus = "idle"
                }
                $Session.Devices.where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
            }
        )

        # Update data in API
        $Session.Miners = $Miners | Sort-Object -Property Info
        $Session.MinersBest = $MinersBest | Sort-Object { $_.BaseName_Version_Device -replace ".+-" }
        $Session.MinersOptimal = $MinersOptimal | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, { $_.BaseName_Version_Device -replace ".+-" }, @{ Expression = $Bias; Descending = $true }
        Remove-Variable Bias, Miners, MinersBest, MinersOptimal -ErrorAction Ignore

        if (-not $Session.MinersBest) { 
            $Message = "No profitable miners - will retry in $($Session.Config.Interval) seconds..."
            Write-Message -Level Warn $Message
            $Session.Summary = $Message
            Remove-Variable Message

            Clear-MinerData -KeepMiners $true

            $Session.RefreshNeeded = $true

            Start-Sleep -Seconds $Session.Config.Interval

            Write-Message -Level Info "Ending cycle."
            continue
        }

        # Core suspended with <Ctrl><Alt>P in MainLoop
        while ($Session.SuspendCycle) { Start-Sleep -Seconds 1 }

        # Optional delay to avoid blue screens
        Start-Sleep -Seconds $Session.Config.Delay

        if ($Session.APIport -and $Session.Config.APIport -ne $Session.APIport -or $Session.Miners.Port -contains $Session.Config.APIport) { 
            # API port has changed; must stop all running miners
            if ($Session.MinersRunning) { 
                Write-Message -Level Info "API port has changed. Stopping all running miners..."
                foreach ($Miner in $Session.MinersRunning.where({ $_.ProcessJob -or $_.Status -eq [MinerStatus]::DryRun })) { 
                    $Miner.SetStatus([MinerStatus]::Idle)
                    $Session.Devices.where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                }
                Remove-Variable Miner -ErrorAction Ignore
            }
            $Session.RefreshNeeded = $true
            while ($Session.Config.APIport -ne $Session.APIport) { Start-Sleep -Milliseconds 100 } # Wail until API has restarted
        }

        foreach ($Miner in $Session.MinersBest) { 

            $DataCollectInterval = if ($Miner.Benchmark -or $Miner.MeasurePowerConsumption) { if ($Session.Config.DryRun -and $Session.Config.BenchmarkAllPoolAlgorithmCombinations) { 0.5 } else { 1 } } else { 5 }

            if ($Miner.Status -ne [MinerStatus]::DryRun -and $Miner.GetStatus() -ne [MinerStatus]::Running) { 
                if ($Session.Config.DryRun -and -not ($Miner.Benchmark -or $Miner.MeasurePowerConsumption)) { 
                    $Miner.SetStatus([MinerStatus]::DryRun)
                }
                else { 
                    # Launch prerun if exists
                    if (Test-Path -LiteralPath ".\Utils\Prerun\$($Miner.Type)Prerun.bat" -PathType Leaf) { 
                        Write-Message -Level Info "Launching Prerun: .\Utils\Prerun\$($Miner.Type)Prerun.bat"
                        Start-Process ".\Utils\Prerun\$($Miner.Type)Prerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                        Start-Sleep -Seconds 2
                    }
                    $MinerAlgorithmPrerunName = ".\Utils\Prerun\$($Miner.BaseName_Version_Device)_$($Miner.Algorithms -join "&").bat"
                    $AlgorithmPrerunName = ".\Utils\Prerun\$($Miner.Algorithms -join "&").bat"
                    $DefaultPrerunName = ".\Utils\Prerun\default.bat"
                    if (Test-Path -LiteralPath $MinerAlgorithmPrerunName -PathType Leaf) { 
                        Write-Message -Level Info "Launching Prerun: $MinerAlgorithmPrerunName"
                        Start-Process $MinerAlgorithmPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                        Start-Sleep -Seconds 2
                    }
                    elseif (Test-Path -LiteralPath $AlgorithmPrerunName -PathType Leaf) { 
                        Write-Message -Level Info "Launching Prerun: $AlgorithmPrerunName"
                        Start-Process $AlgorithmPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                        Start-Sleep -Seconds 2
                    }
                    elseif (Test-Path -LiteralPath $DefaultPrerunName -PathType Leaf) { 
                        Write-Message -Level Info "Launching Prerun: $DefaultPrerunName"
                        Start-Process $DefaultPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                        Start-Sleep -Seconds 2
                    }
                    Remove-Variable AlgorithmPrerunName, DefaultPrerunName, MinerAlgorithmPrerunName -ErrorAction Ignore

                    if ($Miner.Workers.Pool.DAGsizeGiB) { 
                        # Add extra time when CPU mining and miner requires DAG creation
                        if ($Session.MinersBest.Type -contains "CPU") { $Miner.WarmupTimes[0] += 15 <# seconds #> }
                        # Add extra time when notebook runs on battery
                        if ((Get-CimInstance Win32_Battery).BatteryStatus -eq 1) { $Miner.WarmupTimes[0] += 60 <# seconds #> }
                    }

                    $Miner.DataCollectInterval = $DataCollectInterval
                    $Miner.SetStatus([MinerStatus]::Running)
                }
                $Session.Devices.where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })

                # Add watchdog timer
                if ($Session.Config.Watchdog) { 
                    foreach ($Worker in $Miner.WorkersRunning) { 
                        $Session.WatchdogTimers.Add(
                            [PSCustomObject]@{ 
                                Algorithm                    = $Worker.Pool.Algorithm
                                AlgorithmVariant             = $Worker.Pool.AlgorithmVariant
                                CommandLine                  = $Miner.CommandLine
                                DeviceNames                  = $Miner.DeviceNames
                                Kicked                       = [DateTime]::Now.ToUniversalTime()
                                MinerBaseName                = $Miner.BaseName
                                MinerBaseName_Version        = $Miner.BaseName_Version
                                MinerBaseName_Version_Device = $Miner.BaseName_Version_Device
                                MinerName                    = $Miner.Name
                                MinerVersion                 = $Miner.Version
                                PoolKey                      = $Worker.Pool.Key
                                PoolName                     = $Worker.Pool.Name
                                PoolRegion                   = $Worker.Pool.Region
                                PoolVariant                  = $Worker.Pool.Variant
                            }
                        )
                    }
                    Remove-Variable Worker -ErrorAction Ignore
                }
            }
            elseif ($Miner.DataCollectInterval -ne $DataCollectInterval) { 
                $Miner.DataCollectInterval = $DataCollectInterval
                $Miner.RestartDataReader()
            }

            # Do not wait for stable hash rates, for quick and dirty benchmarking
            if ($Session.Config.DryRun -and $Miner.Benchmark) { $Miner.WarmupTimes[1] = 0 }

            if ($Message = "$(if ($Miner.Benchmark) { "Benchmarking" })$(if ($Miner.Benchmark -and $Miner.MeasurePowerConsumption) { " and measuring power consumption" } ElseIf ($Miner.MeasurePowerConsumption) { "Measuring power consumption" })") { 
                Write-Message -Level Verbose "$Message for miner '$($Miner.Info)' in progress [attempt $($Miner.Activated) of $($Session.WatchdogCount + 1); min. $($Miner.MinDataSample) sample$(if ($Miner.MinDataSample -ne 1) { "s" })]..."
            }
        }
        Remove-Variable DataCollectInterval, Message, Miner -ErrorAction Ignore

        $Session.RefreshNeeded = $true

        $Session.MinersBenchmarkingOrMeasuring = $Session.MinersBest.where({ $_.Benchmark -or $_.MeasurePowerConsumption })
        $Session.MinersRunning = $Session.MinersBest
        $Session.MinersFailed = [Miner[]]@()

        if ($Session.MinersNeedingBenchmark) { Write-Message -Level Info "Benchmarking: $($Session.MinersNeedingBenchmark.Count) miner$(if ($Session.MinersNeedingBenchmark.Count -ne 1) { "s" }) left [$((($Session.MinersNeedingBenchmark | Group-Object { $_.BaseName_Version_Device -replace ".+-" }).ForEach({ "$($_.Group[0].BaseName_Version_Device -replace(".+-")): $($_.Count)" }) | Sort-Object) -join ", ")]" }
        if ($Session.MinersNeedingPowerConsumptionMeasurement) { Write-Message -Level Info "Measuring power consumption: $($Session.MinersNeedingPowerConsumptionMeasurement.Count) miner$(if ($Session.MinersNeedingPowerConsumptionMeasurement.Count -ne 1) { "s" }) left [$((($Session.MinersNeedingPowerConsumptionMeasurement | Group-Object { $_.BaseName_Version_Device -replace ".+-" }).ForEach({ "$($_.Group[0].BaseName_Version_Device -replace(".+-")): $($_.Count)" }) | Sort-Object) -join ", ")]" }

        # Core suspended with <Ctrl><Alt>P in MainLoop
        while ($Session.SuspendCycle) { Start-Sleep -Seconds 1 }

        Write-Message -Level Info "Collecting miner data while waiting for end of cycle..."

        # Ensure a cycle on first loop
        if ($Session.CycleStarts.Count -eq 1) { $Session.EndCycleTime = [DateTime]::Now.ToUniversalTime().AddSeconds($Session.Config.Interval) }

        do { 
            $LoopEnd = if ($Session.Config.DryRun -and $Session.Config.BenchmarkAllPoolAlgorithmCombinations) { [DateTime]::Now.AddSeconds(0.5) } else { [DateTime]::Now.AddSeconds(1) }

            # Wait until 1 (0.5) second since loop start has passed
            while ([DateTime]::Now -le $LoopEnd) { Start-Sleep -Milliseconds 50 }

            try { 
                foreach ($Miner in $Session.MinersRunning.where({ $_.Status -ne [MinerStatus]::DryRun })) { 
                    if ($Miner.GetStatus() -ne [MinerStatus]::Running) { 
                        # Miner crashed
                        $Miner.StatusInfo = "$($Miner.Info) ($($Miner.Data.Count) sample$(if ($Miner.Data.Count -ne 1) { "s" })) exited unexpectedly"
                        Write-Message -Level Error "Miner $($Miner.StatusInfo)"
                        $Miner.SetStatus([MinerStatus]::Failed)
                        $Session.MinersFailed += $Miner
                        $Session.EndCycleMessage = " prematurely (miner failed)"
                        break
                    }
                    else { 
                        # Set process priority and window title
                        try { 
                            $Miner.Process.PriorityClass = $Global:PriorityNames.($Miner.ProcessPriority)
                            [Void][Win32]::SetWindowText($Miner.Process.MainWindowHandle, $Miner.StatusInfo)
                        }
                        catch { }

                        if ($Miner.DataReaderJob.HasMoreData) { 
                            # Need hashrates for all algorithms to count as a valid sample
                            if ($Samples = @($Miner.DataReaderJob | Receive-Job).where({ $_.Hashrate.PSObject.Properties.Name -and [Double[]]$_.Hashrate.PSObject.Properties.Value -notcontains 0 })) { 
                                $Sample = $Samples[-1]
                                $Miner.Hashrates_Live = $Sample.Hashrate.PSObject.Properties.Value
                                $Miner.DataSampleTimestamp = $Sample.Date
                                if ($Miner.ReadPowerConsumption) { $Miner.PowerConsumption_Live = $Sample.PowerConsumption }
                                if ($Miner.ValidDataSampleTimestamp -eq [DateTime]0) { $Miner.ValidDataSampleTimestamp = $Sample.Date.AddSeconds($Miner.WarmupTimes[1]) }

                                if (($Miner.ValidDataSampleTimestamp -ne [DateTime]0 -and ($Sample.Date - $Miner.ValidDataSampleTimestamp) -ge 0)) { 
                                    $Samples.where({ $_.Date -ge $Miner.ValidDataSampleTimestamp }).ForEach({ $Miner.Data.Add($_) | Out-Null })
                                    Write-Message -Level Verbose "$($Miner.Name) data sample collected [$(($Sample.Hashrate.PSObject.Properties.Name.ForEach({ "$($_): $(([Double]$Sample.Hashrate.$_ | ConvertTo-Hash) -replace " ")$(if ($Session.Config.ShowShares) { " (Shares: A$($Sample.Shares.$_[0])+R$($Sample.Shares.$_[1])+I$($Sample.Shares.$_[2])=T$($Sample.Shares.$_[3]))" })" })) -join " & ")$(if ($Sample.PowerConsumption) { " | Power: $($Sample.PowerConsumption.ToString("N2"))W" })] ($($Miner.Data.Count) sample$(if ($Miner.Data.Count -ne 1) { "s" }))"
                                    if ($Miner.Activated -gt 0 -and ($Miner.Benchmark -or $Miner.MeasurePowerConsumption)) { 
                                        $Miner.StatusInfo = "$($Miner.Info) is $(if ($Miner.Benchmark) { "benchmarking" })$(if ($Miner.Benchmark -and $Miner.MeasurePowerConsumption) { " and measuring power consumption" } ElseIf ($Miner.MeasurePowerConsumption) { "measuring power consumption" })"
                                        $Miner.SubStatus = "benchmarking"
                                        if ($Miner.Data.Count -ge $Miner.MinDataSample ) { 
                                            # Enough samples collected for this loop, exit loop immediately
                                            $Session.EndCycleMessage = " (a$(if ($Session.MinersBenchmarkingOrMeasuring.where({ $_.Benchmark })) { " benchmarking" })$(if ($Session.MinersBenchmarkingOrMeasuring.where({ $_.Benchmark -and $_.MeasurePowerConsumption })) { " and" })$(if ($Session.MinersBenchmarkingOrMeasuring.where({ $_.MeasurePowerConsumption })) { " power consumption measuring" }) miner has collected enough samples for this cycle)"
                                            break
                                        }
                                    }
                                    else { 
                                        $Miner.StatusInfo = "$($Miner.Info) is mining"
                                        $Miner.SubStatus = "running"
                                    }
                                }
                                elseif (-not $Session.Config.Ignore0HashrateSample -or $Miner.ValidDataSampleTimestamp -ne [DateTime]0) { 
                                    Write-Message -Level Verbose "$($Miner.Name) data sample discarded [$(($Sample.Hashrate.PSObject.Properties.Name.ForEach({ "$($_): $(([Double]$Sample.Hashrate.$_ | ConvertTo-Hash) -replace " ")$(if ($Session.Config.ShowShares) { " (Shares: A$($Sample.Shares.$_[0])+R$($Sample.Shares.$_[1])+I$($Sample.Shares.$_[2])=T$($Sample.Shares.$_[3]))" })" })) -join " & ")$(if ($Sample.PowerConsumption) { " | Power: $($Sample.PowerConsumption.ToString("N2"))W" })]$(if ($Miner.ValidDataSampleTimestamp -ne [DateTime]0) { " (Miner is warming up [$(([DateTime]::Now.ToUniversalTime() - $Miner.ValidDataSampleTimestamp).TotalSeconds.ToString("0") -replace "-0", "0") sec])" })"
                                    $Miner.StatusInfo = "$($Miner.Info) is warming up"
                                    $Miner.SubStatus = "warmingup"
                                }
                            }
                        }

                        # Stop miner, it has not provided hash rate on time
                        if ($Miner.ValidDataSampleTimestamp -eq [DateTime]0 -and [DateTime]::Now.ToUniversalTime() -gt $Miner.BeginTime.AddSeconds($Miner.WarmupTimes[0])) { 
                            $Miner.StatusInfo = "$($Miner.Info) has not provided first valid data sample in $($Miner.WarmupTimes[0]) seconds."
                            Write-Message -Level Error "Miner $($Miner.StatusInfo)"
                            $Miner.SetStatus([MinerStatus]::Failed)
                            $Session.MinersFailed += $Miner
                            $Session.EndCycleMessage = " prematurely (miner failed)"
                            break
                        }
                        # Miner stuck - no sample received in last few data collect intervals
                        else { 
                            $Seconds = (($Miner.DataCollectInterval * 5), 10 | Measure-Object -Maximum).Maximum * $Miner.Algorithms.Count
                            if ($Miner.ValidDataSampleTimestamp -gt [DateTime]0 -and [DateTime]::Now.ToUniversalTime() -gt $Miner.DataSampleTimestamp.AddSeconds($Seconds)) { 
                                $Miner.StatusInfo = "$($Miner.Info) has not updated data for more than $Seconds seconds."
                                Write-Message -Level Error "Miner $($Miner.StatusInfo)"
                                $Miner.SetStatus([MinerStatus]::Failed)
                                $Session.MinersFailed += $Miner
                                $Session.EndCycleMessage = " prematurely (miner failed)"
                                break
                            }
                            Remove-Variable Seconds
                        }
                    }
                    $Session.Devices.where({ $Miner.DeviceNames -contains $_.Name }).ForEach({ $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus })
                }
                Remove-Variable Miner, Sample, Samples -ErrorAction Ignore
            }
            catch { 
                Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting cycle..."
                "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
                $_.Exception | Format-List -Force >> $ErrorLogFile
                $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
            }

            $Session.MinersRunning = $Session.MinersRunning.where({ $_ -notin $Session.MinersFailed })
            $Session.MinersBenchmarkingOrMeasuring = $Session.MinersBenchmarkingOrMeasuring.where({ $_ -notin $Session.MinersFailed })

            # Core suspended with <Ctrl><Alt>P in MainLoop
            while ($Session.SuspendCycle) { Start-Sleep -Seconds 1 }

            # Exit loop when
            # - end cycle message is set
            # - when not benchmarking: Interval time is over
            # - no more running miners
        } while ($Session.NewMiningStatus -eq "Running" -and -not $Session.EndCycleMessage -and ([DateTime]::Now.ToUniversalTime() -le $Session.EndCycleTime -or $Session.MinersBenchmarkingOrMeasuring))
        Remove-Variable LoopEnd

        # Set end cycle time to end brains loop to collect data
        if ($Session.EndCycleMessage) { $Session.EndCycleTime = [DateTime]::Now.ToUniversalTime() }

        $Session.MinersRunning = $Session.MinersRunning.where({ $_ -notin $Session.MinersFailed })
        $Session.MinersBenchmarkingOrMeasuring = $Session.MinersBenchmarkingOrMeasuring.where({ $_ -notin $Session.MinersFailed })

        Get-Job -State "Completed" | Receive-Job -ErrorAction Ignore | Out-Null
        Get-Job -State "Completed" | Remove-Job -Force -ErrorAction Ignore | Out-Null
        Get-Job -State "Failed" | Receive-Job -ErrorAction Ignore | Out-Null
        Get-Job -State "Failed" | Remove-Job -Force -ErrorAction Ignore | Out-Null
        Get-Job -State "Stopped" | Receive-Job -ErrorAction Ignore | Out-Null
        Get-Job -State "Stopped" | Remove-Job -Force -ErrorAction Ignore | Out-Null

        if ($Error) { 
            $Session.CoreCycleError += $Error
            $Error.Clear()
        }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()

        # Core suspended with <Ctrl><Alt>P in MainLoop
        while ($Session.SuspendCycle) { Start-Sleep -Seconds 1 }

        if ($Session.NewMiningStatus -eq "Running" -and $Session.EndCycleTime) { Write-Message -Level Info "Ending cycle$($Session.EndCycleMessage)." }

    } while ($Session.NewMiningStatus -eq "Running")
}
catch { 
    Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected."
    "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> $ErrorLogFile
    $_.Exception | Format-List -Force >> $ErrorLogFile
    $_.InvocationInfo | Format-List -Force >> $ErrorLogFile
    # Reset timers
    $Session.EndCycleTime = [DateTime]::Now.ToUniversalTime()
}