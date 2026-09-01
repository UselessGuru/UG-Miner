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
File:           \Brains\ZPool.ps1
Version:        6.8.24
Version date:   2026/09/01
#>

using module ..\Includes\Include.psm1

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

$PoolObjects = @()
$Durations = [TimeSpan[]]@()

$Handler = [System.Net.Http.HttpClientHandler]::new()
$Handler.ServerCertificateCustomValidationCallback = [System.Net.Http.HttpClientHandler]::DangerousAcceptAnyServerCertificateValidator
$HttpClient = [System.Net.Http.HttpClient]::new($Handler)
$HttpClient.DefaultRequestHeaders.CacheControl = [System.Net.Http.Headers.CacheControlHeaderValue]::Parse("no-cache")

while ($Config.PoolsConfig.$Name) { 

    $APIcallFails = 0
    $PoolVariant = [String]$Session.Config.PoolName.Where{ $_ -like "$Name*" }
    $StartTime = [DateTime]::Now

    if ($Session.MyIPaddress) { 
        try { 

            Write-Message -Level Debug "Brain '$Name': Start loop$(if ($Duration) { " (Previous loop duration: $Duration sec.)" })"

            do { 
                try { 
                    if (-not $AlgoData) { 
                        $Request = "https://www.zpool.ca/api/status"
                        Write-Message -Level Debug "Brain '$Name': Querying '$Request'"
                        $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($Config.PoolsConfig.$Name.PoolAPItimeout))
                        $Response = $HttpClient.GetAsync($Request, $CancellationTokenSource.Token).GetAwaiter().GetResult()
                        # Read response as raw string
                        $JSONstring = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                        Write-Message -Level Debug "Brain '$Name': Response from '$Request' received"
                        if ($JSONstring -and (Test-Json $JSONstring -ErrorAction Ignore)) { 
                            # Change numeric string to numbers, some values are null
                            $AlgoData = ($JSONstring -replace ":`"(\d+\.?\d*)`"", ":`$1" -replace "`":null", "`":0") | ConvertFrom-Json
                        }
                    }
                    if (-not $CurrenciesData) { 
                        $Request = "https://www.zpool.ca/api/currencies"
                        Write-Message -Level Debug "Brain '$Name': Querying '$Request'"
                        $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($Config.PoolsConfig.$Name.PoolAPItimeout))
                        $Response = $HttpClient.GetAsync($Request, $CancellationTokenSource.Token).GetAwaiter().GetResult()
                        # Read response as raw string
                        $JSONstring = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                        Write-Message -Level Debug "Brain '$Name': Response from '$Request' received"
                        if ($JSONstring -and (Test-Json $JSONstring -ErrorAction Ignore)) { 
                            # Change numeric string to numbers, some values are null
                            $CurrenciesData = ($JSONstring -replace ":`"(\d+\.?\d*)`"", ":`$1" -replace "`":null", "`":0") | ConvertFrom-Json
                        } 
                    }
                }
                catch { 
                    $APIcallFails ++
                    $APIerror = $_.Exception #.Message
                    Write-Message -Level Debug "Brain '$Name': Query to '$Request' failed ($($APIerror | ConvertTo-Json -Compress))"
                    if ($APIcallFails -lt $Config.PoolsConfig.$Name.PoolAPIallowedFailureCount) { Start-Sleep -Seconds ([Math]::max(15, $Config.PoolsConfig.$Name.PoolAPIretryInterval)) }
                }
                $CancellationTokenSource.Dispose()
                Remove-Variable CancellationTokenSource, JSONstring, RequestMessage, Response -ErrorAction Ignore
            } while (-not ($AlgoData -and $CurrenciesData) -and $APIcallFails -le $Session.Config.PoolAPIallowedFailureCount)

            $Timestamp = [DateTime]::Now.ToUniversalTime()

            if ($APIcallFails -gt $Session.Config.PoolAPIallowedFailureCount) { 
                Write-Message -Level Warn "Brain $($Name): Problem when trying to access 'https://www.zpool.ca/api/*' ($($APIerror | ConvertTo-Json -Compress))"
            }
            elseif ($AlgoData -and $CurrenciesData) { 

                # Add currency and convert to array for easy sorting
                $CurrenciesArray = [PSCustomObject[]]@()
                $CurrenciesData.PSObject.Properties.Name.Where{ $_ -notmatch "Hashtap|SCC-firo" }.ForEach{ 
                    $CoinName = $CurrenciesData.$_.Name
                    $Currency = $($_ -replace '-.+$')
                    try { 
                        Add-CoinName -Currency $Currency -CoinName $CoinName
                        # Add algorithm only if there is no other coin with the same algorithm
                        if ($CurrenciesData.PSObject.Properties.Name.Where{ $($_ -replace '-.+$') -eq $Currency }.Count -eq 1) { 
                            Add-CurrencyAlgorithm -Algorithm $CurrenciesData.$_.algo -Currency $Currency
                        }
                    }
                    catch { }

                    $CurrenciesData.$_ | Add-Member Currency $Currency -Force
                    $CurrenciesData.$_ | Add-Member CoinName ([String]$Session.CoinNames[$Currency]) -Force
                    $CurrenciesData.$_ | Add-Member conversion_supported ([Boolean]($Config.PoolsConfig.$Name.Wallets.$Currency -or -not $CurrenciesData.$_.only_direct))

                    $CurrenciesData.$_.PSObject.Properties.Remove("symbol")
                    $CurrenciesData.$_.PSObject.Properties.Remove("name")
                    $CurrenciesArray += $CurrenciesData.$_

                    Remove-Variable CoinName, Currency
                }

                # Get best currency
                ($CurrenciesArray | Group-Object -Property Algo).ForEach{ 
                    if ($AlgoData.($_.name)) { 
                        $BestCurrency = ($_.Group | Sort-Object -Property conversion_supported, estimate -Descending -Top 1)
                        $AlgoData.($_.name) | Add-Member Currency $BestCurrency.currency -Force
                        $AlgoData.($_.name) | Add-Member CoinName $BestCurrency.coinname -Force
                        $AlgoData.($_.name) | Add-Member conversion_supported $BestCurrency.conversion_supported -Force
                    }
                }

                foreach ($Algorithm in $AlgoData.PSObject.Properties.Name) { 
                    $AlgorithmNorm = Get-Algorithm $Algorithm
                    if ($AlgoData.$Algorithm.actual_last24h) { $AlgoData.$Algorithm.actual_last24h /= 1000 }
                    $BasePrice = if ($AlgoData.$Algorithm.actual_last24h) { $AlgoData.$Algorithm.actual_last24h } else { $AlgoData.$Algorithm.estimate_last24h }

                    if ($Currency = $AlgoData.$Algorithm.Currency -replace "\s.*") { 
                        if ($AlgorithmNorm -match $Session.RegexAlgoHasDAG -and $CurrenciesData.$Currency.height -gt $Session.DAGdata.Currency.$Currency.BlockHeight) { 
                            # Keep DAG data data up to date
                            $DAGdata = (Get-DAGData -BlockHeight $CurrenciesData.$Currency.height -Algorithm $AlgorithmNorm -Currency $Currency -EpochReserve 2)
                            if ($DAGdata.Epoch -ge 0) { 
                                $DAGdata.Updated = ([DateTime]::Now).ToUniversalTime()
                                $DAGdata.Url     = "https://www.zpool.ca/api/currencies"

                                $Session.DAGdata.Currency.$Currency = $DAGdata
                                $Session.DAGdata.Updated."https://www.zpool.ca/api/currencies" = [DateTime]::Now.ToUniversalTime()
                            }
                        }
                        $AlgoData.$Algorithm | Add-Member conversion_supported $CurrenciesData.$Currency.conversion_supported -Force
                        if ($CurrenciesData.$Currency.error) { 
                            $AlgoData.$Algorithm | Add-Member error "Pool error msg: $($CurrenciesData.$Currency.error)" -Force
                        }
                        else { 
                            $AlgoData.$Algorithm | Add-Member error "" -Force
                        }
                    }
                    else { 
                        $AlgoData.$Algorithm | Add-Member error "" -Force
                        $AlgoData.$Algorithm | Add-Member conversion_supported 0 -Force
                    }
                    $AlgoData.$Algorithm | Add-Member Updated $Timestamp -Force

                    # Reset history when stat file got removed
                    if ($PoolVariant -like "*Plus") { 
                        $StatName = if ($Currency) { "$($PoolVariant)_$($AlgorithmNorm)-$($Currency)_Profit" } else { "$($PoolVariant)_$($AlgorithmNorm)_Profit" }
                        if (-not ($Stat = Get-Stat -Name $StatName) -and $PoolObjects.Where{ $_.Name -eq $Algorithm }) { 
                            $PoolObjects = $PoolObjects.Where{ $_.Name -ne $Algorithm }
                            Write-Message -Level Debug "Pool brain '$Name': PlusPrice history cleared for $($StatName -replace "_Profit")"
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
                    $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf.Where{ $_.Name -eq $Algorithm + ", Up" }).Count - ($GroupAvgSampleSizeHalf.Where{ $_.Name -eq $Algorithm + ", Down" }).Count) / (($GroupMedSampleSizeHalf.Where{ $_.Name -eq $Algorithm }).Count)) * [Math]::abs(($GroupMedSampleSizeHalf.Where{ $_.Name -eq $Algorithm }).Median)
                    $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize.Where{ $_.Name -eq $Algorithm + ", Up" }).Count - ($GroupAvgSampleSize.Where{ $_.Name -eq $Algorithm + ", Down" }).Count) / (($GroupMedSampleSize.Where{ $_.Name -eq $Algorithm }).Count)) * [Math]::abs(($GroupMedSampleSizeNoPercent.Where{ $_.Name -eq $Algorithm }).Median)
                    $Penalty = ($PenaltySampleSizeHalf * $Config.PoolsConfig.$Name.BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($Config.PoolsConfig.$Name.BrainConfig.SampleHalfPower + 1)
                    $CurrentPoolObject = $CurrentPoolObjects.Where{ $_.Name -eq $Algorithm }
                    $Currency = $CurrentPoolObject.currency
                    $LastPrice = [Double]$CurrentPoolObject.estimate_current
                    $PlusPrice = [Math]::max(0, [Double]($LastPrice + $Penalty))

                    $StatName = if ($Currency) { "$($PoolVariant)_$(Get-Algorithm $Algorithm)-$($Currency)_Profit" } else { "$($PoolVariant)_$(Get-Algorithm $Algorithm)_Profit" }
                    # Reset history if current estimate is not within +/- 1000% of 24hr stat price
                    if ($Stat = Get-Stat -Name $StatName) { 
                        $Divisor = $Config.PoolsConfig.$Name.Variant."$PoolVariant".DivisorMultiplier * $AlgoData.$Algorithm.mbtc_mh_factor
                        if ($Stat.Day -and $LastPrice -gt 0 -and ($AlgoData.$Algorithm.estimate_current / $Divisor -lt $Stat.Day / 10 -or $AlgoData.$Algorithm.estimate_current / $Divisor -gt $Stat.Day * 10)) { 
                            Remove-Stat -Name $StatName
                            $PoolObjects = $PoolObjects.Where{ $_.Name -ne $Algorithm }
                            $PlusPrice = $LastPrice
                            Write-Message -Level Debug "Pool brain '$Name': PlusPrice history cleared for $($StatName -replace "_Profit") (stat day price: $($Stat.Day) vs. estimate current price: $($AlgoData.$Algorithm.estimate_current / $Divisor))"
                        }
                    }
                    $AlgoData.$Algorithm | Add-Member PlusPrice $PlusPrice -Force
                }
                Remove-Variable Algorithm, AlgorithmNorm, BasePrice, BestCurrency, CurrenciesArray, Currency, CurrentPoolObject, CurrentPoolObjects, DAGdata, GroupAvgSampleSize, GroupMedSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, LastPrice, Penalty, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, PlusPrice, Stat, StatName -ErrorAction Ignore

                if ($Config.PoolsConfig.$Name.BrainConfig.UseTransferFile -or $Config.PoolsConfig.$Name.BrainConfig.Debug) { 
                    ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -LiteralPath $BrainDataFile -Force -ErrorAction Ignore
                }
            }
            else { 
                $AlgoData = [PSCustomObject]@{ }
            }

            $Session.BrainData.$Name = $AlgoData
            $Session.Brains.$Name | Add-Member "Updated" $Timestamp -Force

            # Limit to only sample size + 10 minutes history
            $PoolObjects = @($PoolObjects.Where{ $_.Date -ge $Timestamp.AddMinutes( - ($Config.PoolsConfig.$Name.BrainConfig.SampleSizeMinutes + 10)) })
        }
        catch { 
            Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting core..."
            "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
            $_.Exception | Format-List -Force >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
            $_.InvocationInfo | Format-List -Force >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
        }
        Remove-Variable AlgoData, CurrenciesData -ErrorAction Ignore

        $Duration = ([DateTime]::Now - $StartTime).TotalSeconds
        $Durations += ($Duration, $Session.Interval | Measure-Object -Minimum).Minimum
        $Durations = @($Durations | Select-Object -Last 20)
        $DurationsAvg = ($Durations | Measure-Object -Average).Average

        Write-Message -Level Debug "Brain '$Name': End loop (Duration $Duration sec. / Avg. loop duration: $DurationsAvg sec.); Price history $($PoolObjects.Count) objects; found $($Session.BrainData.$Name.PSObject.Properties.Name.Count) valid pools."
    }

    while (-not $Session.MyIPaddress -or ($Session.NewMiningStatus -eq "Paused" -and $Timestamp.AddSeconds($Session.Config.Interval) -gt [DateTime]::Now.ToUniversalTime()) -or ($Session.NewMiningStatus -eq "Running" -and ($Timestamp -ge $Session.PoolDataCollectedTimeStamp -or ($Session.EndCycleTime -and [DateTime]::Now.ToUniversalTime().AddSeconds($DurationsAvg + 2) -le $Session.EndCycleTime)))) { 
        Start-Sleep -Milliseconds 250
    }
}

Remove-Variable APIcallFails, BrainDataFile, Duration, Durations, DurationsAvg, Handler, HttpClient, Headers, Name, PoolConfig, PoolObjects, PoolVariant, StartTime, UserAgent -ErrorAction Ignore