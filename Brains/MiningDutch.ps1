<#
Copyright (c) 2018-2026 UselessGuru


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
File:           \Brains\MiningDutch.ps1
Version:        6.8.25
Version date:   2026/09/04
#>

using module ..\Includes\Include.psm1

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

$Durations = [TimeSpan[]]@()
$PoolObjects = @()


$Handler = [System.Net.Http.HttpClientHandler]::new()
$Handler.ServerCertificateCustomValidationCallback = [System.Net.Http.HttpClientHandler]::DangerousAcceptAnyServerCertificateValidator # Equivalent to -SkipCertificateCheck
$HttpClient = [System.Net.Http.HttpClient]::new($Handler)
$HttpClient.DefaultRequestHeaders.CacheControl = [System.Net.Http.Headers.CacheControlHeaderValue]::Parse("no-cache")
$HttpClient.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36")

while ($Config.PoolsConfig.$Name) { 

    Write-Message -Level $DebugLevel "Brain '$Name': In Loop"

    $APIcallFails = 0
    $PoolVariant = $Session.Config.PoolName.Where{ $_ -like "$Name*" }
    $StartTime = [DateTime]::Now

    if ($Session.MyIPaddress) { 
        try { 

            Write-Message -Level $DebugLevel "Brain '$Name': Start loop$(if ($Duration) { " (Previous loop duration: $Duration sec.)" })"

            do { 
                try { 
                    if (-not $TotalStatsResult) { 
                        $Request = "https://www.mining-dutch.nl/api/v1/public/pooldata/?method=totalstats"
                        Write-Message -Level $DebugLevel "BalancesTracker '$Name': Querying '$Request'"
                        $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($Config.PoolsConfig.$Name.PoolAPItimeout))
                        $Response = $HttpClient.GetAsync($Request, $CancellationTokenSource.Token).GetAwaiter().GetResult()
                        # Read response as raw string
                        $JSONstring = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()

                        $Session."$($Name)APIrequestTimestamp" = [DateTime]::Now.ToUniversalTime()
                        Write-Message -Level $DebugLevel "Brain '$Name': Response from '$Request' received"

                        if ($JSONstring -match "Only \d request every ") { 
                            $WaitSeconds = [UInt16]($JSONstring -replace ".+Only \d request every " -replace " seconds allowed.+")
                            Write-Message -Level $DebugLevel "Brain '$Name': Response '$JSONstring' from '$Request' received -> waiting $WaitSeconds seconds"
                            Start-Sleep -Seconds ($WaitSeconds + 1) # Pool does not like immediate requests
                            Remove-Variable WaitSeconds
                        }
                        elseif ($JSONstring -and (Test-Json $JSONstring -ErrorAction Ignore)) { 
                            # Change numeric string to numbers, some values are null
                            $TotalStatsResult = (($JSONstring -replace ":`"(\d+\.?\d*)`"", ":`$1" -replace "`":null", "`":0") | ConvertFrom-Json).result
                        }
                    }

                    if (-not $AlgoData) { 
                        $Request = "https://www.mining-dutch.nl/api/status"
                        Write-Message -Level $DebugLevel "BalancesTracker '$Name': Querying '$Request'"
                        $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($Config.PoolsConfig.$Name.PoolAPItimeout))
                        $Response = $HttpClient.GetAsync($Request, $CancellationTokenSource.Token).GetAwaiter().GetResult()
                        # Read response as raw string
                        $JSONstring = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()

                        $Session."$($Name)APIrequestTimestamp" = [DateTime]::Now.ToUniversalTime()
                        Write-Message -Level $DebugLevel "Brain '$Name': Response from '$Request' received"

                        if ($JSONstring -match "Only \d request every ") { 
                            $WaitSeconds = [UInt16]($JSONstring -replace ".+Only \d request every " -replace " seconds allowed.+")
                            Write-Message -Level $DebugLevel "Brain '$Name': Response '$JSONstring' from '$Request' received -> waiting $WaitSeconds seconds"
                            Start-Sleep -Seconds ($WaitSeconds + 1) # Pool does not like immediate requests
                            Remove-Variable WaitSeconds
                        }
                        elseif ($JSONstring -and (Test-Json $JSONstring -ErrorAction Ignore)) { 
                            # Change numeric string to numbers, some values are null
                            $AlgoData = ($JSONstring -replace ":`"(\d+\.?\d*)`"", ":`$1" -replace "`":null", "`":0") | ConvertFrom-Json
                        }
                    }
                }
                catch { 
                    $APIcallFails ++
                    $APIerror = $_.Exception.Message
                    Write-Message -Level $DebugLevel "Brain '$Name': Query to $URI failed ($($APIerror | ConvertTo-Json -Compress))"
                    if ($APIcallFails -lt $Config.PoolsConfig.$Name.PoolAPIallowedFailureCount) { Start-Sleep -Seconds ([Math]::max(15, $Config.PoolsConfig.$Name.PoolAPIretryInterval)) }
                }
                $CancellationTokenSource.Dispose()
                Remove-Variable CancellationTokenSource, JSONstring, RequestMessage, Response -ErrorAction Ignore
            } while (-not ($AlgoData -and $TotalStatsResult) -and $APIcallFails -le $Session.Config.PoolAPIallowedFailureCount)

            $Timestamp = [DateTime]::Now.ToUniversalTime()

            if ($APIcallFails -gt $Session.Config.PoolAPIallowedFailureCount) { 
                Write-Message -Level Warn "Brain $($Name): Problem when trying to access https://www.mining-dutch.nl/api ($($APIerror | ConvertTo-Json -Compress))"
            }
            elseif ($TotalStatsResult) { 

                ($AlgoData.PSObject.Properties.Name).Where{ $TotalStatsResult.algorithm -notcontains $_ }.ForEach{ $AlgoData.PSObject.Properties.Remove($_) }

                if ($AlgoData.PSObject.Properties.Name) { 
                    foreach ($Algorithm in $AlgoData.PSObject.Properties.Name) { 
                        $AlgorithmNorm = Get-Algorithm $Algorithm
                        $BasePrice = if ($AlgoData.$Algorithm.actual_last24h) { $AlgoData.$Algorithm.actual_last24h } else { $AlgoData.$Algorithm.estimate_last24h }
                        $Currency = ""
                        if ($AlgoData.$Algorithm.coins -eq 1) { 
                            $Currencies = Get-CurrencyFromAlgorithm $AlgorithmNorm
                            if ($Currencies.Count -eq 1) { $Currency = [String]$Currencies }
                        }
                        $AlgoData.$Algorithm | Add-Member Currency $Currency -Force
                        $AlgoData.$Algorithm | Add-Member Updated $Timestamp -Force

                        # Temp fix, incorrect data in API
                        if ($AlgorithmNorm -eq "Neoscrypt" -and $AlgoData.$Algorithm.mbtc_mh_factor -eq 1) { $AlgoData.$Algorithm.mbtc_mh_factor = 1000 }

                        if ($AlgoStats = $TotalStatsResult.Where{ $_.Algorithm -eq $Algorithm }) { 
                            $AlgoData.$Algorithm | Add-Member hashrate_shared $AlgoStats.hashrate -Force
                            $AlgoData.$Algorithm | Add-Member hashrate_solo $AlgoStats.hashrate_solo -Force
                            $AlgoData.$Algorithm | Add-Member workers_shared $AlgoStats.workers -Force
                            $AlgoData.$Algorithm | Add-Member workers_solo $AlgoStats.workers_solo -Force
                        }
                        Remove-Variable AlgoStats, Currencies -ErrorAction Ignore

                        # Reset history when stat file got removed
                        if ($PoolVariant -like "*Plus") { 
                            $StatName = if ($Currency) { "$($PoolVariant)_$(Get-Algorithm $Algorithm)-$($Currency)_Profit" } else { "$($PoolVariant)_$(Get-Algorithm $Algorithm)_Profit" }
                            if (-not ($Stat = Get-Stat -Name $StatName) -and $PoolObjects.Where{ $_.Name -eq $Algorithm }) { 
                                $PoolObjects = $PoolObjects.Where{ $_.Name -ne $Algorithm }
                                Write-Message -Level $DebugLevel "Pool brain '$Name': PlusPrice history cleared for $($StatName -replace "_Profit")"
                            }
                        }

                        $PoolObjects += [PSCustomObject]@{ 
                            actual_last24h      = $BasePrice
                            currency            = $Currency
                            Date                = $Timestamp
                            estimate_current    = $AlgoData.$Algorithm.estimate_current
                            estimate_last24h    = $AlgoData.$Algorithm.estimate_last24h
                            Last24hDrift        = $AlgoData.$Algorithm.estimate_current - $BasePrice
                            Last24hDriftPercent = if ($BasePrice -gt 0) { ($AlgoData.$Algorithm.estimate_current - $BasePrice) / $BasePrice } else { 0 }
                            Last24hDriftSign    = if ($AlgoData.$Algorithm.estimate_current -ge $BasePrice) { "Up" } else { "Down" }
                            Name                = $Algorithm
                        }
                    }

                    # Created here for performance optimization, minimize # of lookups
                    $SampleSizets = New-TimeSpan -Minutes $Config.PoolsConfig.$Name.BrainConfig.SampleSizeMinutes
                    $SampleSizeHalfts = New-TimeSpan -Minutes ($Config.PoolsConfig.$Name.BrainConfig.SampleSizeMinutes / 2)
                    $PoolObjectsSampleSizets = $PoolObjects.Where{ $_.Date -ge ($Timestamp - $SampleSizets) }
                    $PoolObjectsSampleSizeHalfts = $PoolObjects.Where{ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }
                    $GroupAvgSampleSize = $PoolObjectsSampleSizets | Group-Object -Property Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                    $GroupMedSampleSize = $PoolObjectsSampleSizets | Group-Object -Property Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                    $GroupAvgSampleSizeHalf = $PoolObjectsSampleSizeHalfts | Group-Object -Property Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                    $GroupMedSampleSizeHalf = $PoolObjectsSampleSizeHalfts | Group-Object -Property Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
                    $GroupMedSampleSizeNoPercent = $PoolObjectsSampleSizets | Group-Object -Property Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDrift } }
                    Remove-Variable PoolObjectsSampleSizets, PoolObjectsSampleSizeHalfts, SampleSizeHalfts, SampleSizets

                    $CurrentPoolObjects = $PoolObjects.Where{ $_.Date -eq $Timestamp }
                    foreach ($Algorithm in ($PoolObjects.Name | Select-Object -Unique).Where{ $AlgoData.PSObject.Properties.Name -contains $_ }) { 
                        if ($Algogroup = $GroupMedSampleSizeHalf.Where{ $_.Name -eq $Algorithm }) { 
                            $PenaltySampleSizeHalf = (($GroupAvgSampleSizeHalf.Where{ $_.Name -eq $Algorithm + ", Up" }).Count - ($GroupAvgSampleSizeHalf.Where{ $_.Name -eq $Algorithm + ", Down" }).Count) / ($Algogroup.Count * [Math]::abs($Algogroup.Median))
                            $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize.Where{ $_.Name -eq $Algorithm + ", Up" }).Count - ($GroupAvgSampleSize.Where{ $_.Name -eq $Algorithm + ", Down" }).Count) / (($GroupMedSampleSize.Where{ $_.Name -eq $Algorithm }).Count)) * [Math]::abs(($GroupMedSampleSizeNoPercent.Where{ $_.Name -eq $Algorithm }).Median)
                            $Penalty = ($PenaltySampleSizeHalf * $Config.PoolsConfig.$Name.BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($Config.PoolsConfig.$Name.BrainConfig.SampleHalfPower + 1)
                            $LastPrice = [Double]$CurrentPoolObjects.Where{ $_.Name -eq $Algorithm }.estimate_current
                            $PlusPrice = [Math]::max(0, [Double]($LastPrice + $Penalty))

                            $StatName = if ($Currency) { "$($PoolVariant)_$(Get-Algorithm $Algorithm)-$($Currency)_Profit" } else { "$($PoolVariant)_$(Get-Algorithm $Algorithm)_Profit" }
                            # Reset history if current estimate is not within +/- 1000% of 24hr stat price
                            if ($Stat = Get-Stat -Name $StatName) { 
                                $Divisor = $Config.PoolsConfig.$Name.Variant."$PoolVariant".DivisorMultiplier * $AlgoData.$Algorithm.mbtc_mh_factor
                                if ($Stat.Day -and $LastPrice -gt 0 -and ($AlgoData.$Algorithm.estimate_current / $Divisor -lt $Stat.Day / 10 -or $AlgoData.$Algorithm.estimate_current / $Divisor -gt $Stat.Day * 10)) { 
                                    Remove-Stat -Name $StatName
                                    $PoolObjects = $PoolObjects.Where{ $_.Name -ne $Algorithm }
                                    $PlusPrice = $LastPrice
                                    Write-Message -Level $DebugLevel "Pool brain '$Name': PlusPrice history cleared for $($StatName -replace "_Profit") (stat day price: $($Stat.Day) vs. estimate current price: $($AlgoData.$Algorithm.estimate_current / $Divisor))"
                                }
                            }
                            $AlgoData.$Algorithm | Add-Member PlusPrice $PlusPrice -Force
                        }
                    }
                    Remove-Variable AlgoGroup, Algorithm, AlgorithmNorm, Baseprice, Currency, CurrentPoolObjects, GroupAvgSampleSize, GroupMedSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, LastPrice, Penalty, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, PlusPrice, Stat, StatName -ErrorAction Ignore

                    if ($Config.PoolsConfig.$Name.BrainConfig.UseTransferFile -or $Config.PoolsConfig.$Name.BrainConfig.Debug) { 
                        ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -LiteralPath $BrainDataFile -Force -ErrorAction Ignore
                    }
                }
            }
            else { 
                $AlgoData = [PSCustomObject]@{ }
            }

            $Session.BrainData.$Name = $AlgoData
            $Session.Brains.$Name | Add-Member "Updated" $Timestamp -Force

            Remove-Variable AlgoData, TotalStatsResult -ErrorAction Ignore

            # Limit to only sample size + 10 minutes history
            $PoolObjects = @($PoolObjects.Where{ $_.Date -ge $Timestamp.AddMinutes( - ($Config.PoolsConfig.$Name.BrainConfig.SampleSizeMinutes + 10)) })
        }
        catch { 
            Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting brain..."
            "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
            $_.Exception | Format-List -Force >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
            $_.InvocationInfo | Format-List -Force >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
        }

        $Duration = ([DateTime]::Now - $StartTime).TotalSeconds
        $Durations += ($Duration, $Session.Interval | Measure-Object -Minimum).Minimum
        $Durations = @($Durations | Select-Object -Last 20)
        $DurationsAvg = ($Durations | Measure-Object -Average).Average

        Write-Message -Level $DebugLevel "Brain '$Name': End loop (Duration $Duration sec. / Avg. loop duration: $DurationsAvg sec.); Price history $($PoolObjects.Count) objects; found $($Session.BrainData.$Name.PSObject.Properties.Name.Count) valid pools."
    }

    while (-not $Session.MyIPaddress -or ($Session.NewMiningStatus -eq "Paused" -and $Timestamp.AddSeconds($Session.Config.Interval) -gt [DateTime]::Now.ToUniversalTime()) -or ($Session.NewMiningStatus -eq "Running" -and ($Timestamp -ge $Session.PoolDataCollectedTimeStamp -or ($Session.EndCycleTime -and [DateTime]::Now.ToUniversalTime().AddSeconds($DurationsAvg + 5) -le $Session.EndCycleTime)))) { 
        Start-Sleep -Milliseconds 250
    }
}

Remove-Variable APIcallFails, BrainDataFile, Duration, Durations, DurationsAvg, Handler, HttpClient, Headers, Name, PoolConfig, PoolObjects, PoolVariant, StartTime, UserAgent -ErrorAction Ignore