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
File:           \Brains\ZPool.ps1
Version:        6.3.8
Version date:   2024/10/13
#>

using module ..\Includes\Include.psm1

# Start transcript log
If ($Config.Transcript) { Start-Transcript -Path ".\Debug\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$BrainName = (Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolObjects = @()
$APICallFails = 0
$Durations = [TimeSpan[]]@()
$BrainDataFile = "$PWD\Data\BrainData_$BrainName.json"

While ($PoolConfig = $Config.PoolsConfig.$BrainName) { 

    $PoolVariant = $Config.PoolName.Where({ $_ -like "$BrainName*" })
    $StartTime = [DateTime]::Now

    Try { 

        Write-Message -Level Debug "Brain '$BrainName': Start loop$(If ($Duration) { " (Previous loop duration: $Duration sec.)" })"

        Do { 
            Try { 
                If (-not $AlgoData) { 
                    $AlgoData = Invoke-RestMethod -Uri $PoolConfig.PoolStatusUri -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout
                }
                If (-not $CurrenciesData) { 
                    $CurrenciesData = Invoke-RestMethod -Uri $PoolConfig.PoolCurrenciesUri -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout
                }
                $APICallFails = 0
            }
            Catch { 
                If ($APICallFails -lt $PoolConfig.PoolAPIAllowedFailureCount) { $APICallFails ++ }
                Start-Sleep -Seconds ([Math]::max(60, ($APICallFails * 5 + $PoolConfig.PoolAPIretryInterval)))
            }
        } While (-not ($AlgoData -and $CurrenciesData) -and $APICallFails -lt $Config.PoolAPIallowedFailureCount)

        $Timestamp = [DateTime]::Now.ToUniversalTime()

        If ($AlgoData -and $CurrenciesData) { 
            # Change numeric string to numbers, some values are null
            $AlgoData = ($AlgoData | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json
            $CurrenciesData = ($CurrenciesData | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json

            # Add currency and convert to array for easy sorting
            $CurrenciesArray = [PSCustomObject[]]@()
            $CurrenciesData.PSObject.Properties.Name.Where({ $CurrenciesData.$_.algo -and $CurrenciesData.$_.name -notcontains "Hashtap" }).ForEach(
                { 
                    $CurrenciesData.$_ | Add-Member Currency $(If ($CurrenciesData.$_.symbol) { $CurrenciesData.$_.symbol -replace '-.+$' } Else { $_ -replace '-.+$' })
                    $CurrenciesData.$_ | Add-Member CoinName $(If ($CurrenciesData.$_.name) { $CurrenciesData.$_.name } Else { $_ })
                    $CurrenciesData.$_ | Add-Member conversion_supported ([Boolean]($PoolConfig.Wallets.($CurrenciesData.$_.Currency) -or -not $CurrenciesData.$_.conversion_disabled))

                    $CurrenciesData.$_.PSObject.Properties.Remove("symbol")
                    $CurrenciesData.$_.PSObject.Properties.Remove("name")
                    $CurrenciesArray += $CurrenciesData.$_
                    $AlgorithmNorm = $CurrenciesData.$_.algo

                    If ($CurrenciesData.$_.CoinName -and $CurrenciesData.$_.Currency -and -not $Variables.CurrencyAlgorithm[$AlgorithmNorm]) { 
                        Try { 
                            # Add coin name
                            [Void](Add-CoinName -Algorithm $AlgorithmNorm -Currency $CurrenciesData.$_.Currency -CoinName $CurrenciesData.$_.CoinName)
                        }
                        Catch { 
                        }
                    }
                }
            )

            # Get best currency, prefer currencies that can be converted
            ($CurrenciesArray | Group-Object algo).ForEach(
                { 
                    If ($AlgoData.($_.name)) { 
                        $BestCurrency = ($_.Group | Sort-Object conversion_supported, estimate -Descending | Select-Object -First 1)
                        $AlgoData.($_.name) | Add-Member Currency $BestCurrency.currency -Force
                        $AlgoData.($_.name) | Add-Member CoinName $BestCurrency.coinname -Force
                        $AlgoData.($_.name) | Add-Member conversion_supported $BestCurrency.conversion_supported -Force
                    }
                }
            )

            ForEach ($Algo in $AlgoData.PSObject.Properties.Name) { 
                $AlgorithmNorm = Get-Algorithm $Algo
                If ($AlgoData.$Algo.actual_last24h) { $AlgoData.$Algo.actual_last24h /= 1000 }
                $BasePrice = If ($AlgoData.$Algo.actual_last24h) { $AlgoData.$Algo.actual_last24h } Else { $AlgoData.$Algo.estimate_last24h }

                If ($Currency = $AlgoData.$Algo.Currency -replace '\s.*') { 
                    If ($AlgorithmNorm -match $Variables.RegexAlgoHasDAG -and $AlgoData.$Algo.height -gt ($Variables.DAGdata.Currency.$Currency.BlockHeight)) { 
                        # Keep DAG data data up to date
                        $DAGdata = (Get-DAGData -BlockHeight $AlgoData.$Algo.height -Currency $Currency -EpochReserve 2)
                        $DAGdata | Add-Member Date ([DateTime]::Now).ToUniversalTime() -Force
                        $DAGdata | Add-Member Url $PoolConfig.PoolCurrenciesUri
                        $Variables.DAGdata.Currency | Add-Member $Pool $DAGdata -Force
                        $Variables.DAGdata.Updated[$PoolConfig.PoolCurrenciesUri] = [DateTime]::Now.ToUniversalTime()
                    }
                    $AlgoData.$Algo | Add-Member conversion_disabled $CurrenciesData.$Currency.conversion_disabled -Force
                    If ($CurrenciesData.$Currency.error) { 
                        $AlgoData.$Algo | Add-Member error "Pool error msg: $($CurrenciesData.$Currency.error)" -Force
                    }
                    Else { 
                        $AlgoData.$Algo | Add-Member error "" -Force
                    }
                }
                Else { 
                    $AlgoData.$Algo | Add-Member error "" -Force
                    $AlgoData.$Algo | Add-Member conversion_disabled 0 -Force

                }
                $AlgoData.$Algo | Add-Member Updated $Timestamp -Force

                If ($PoolVariant) { 
                    # Reset history when stat file got removed
                    $StatName = If ($Currency) { "$($PoolVariant)_$AlgorithmNorm-$($Currency)_Profit" } Else { "$($PoolVariant)_$($AlgorithmNorm)_Profit" }
                    If (-not (Get-Stat -Name $StatName)) { 
                        $PoolObjects = $PoolObjects.Where({ $_.Name -ne $PoolName })
                        Write-Message -Level Debug "Pool brain '$BrainName': PlusPrice history cleared for $($StatName -replace '_Profit')"
                    }
                }

                $PoolObjects += [PSCustomObject]@{ 
                    actual_last24h      = $BasePrice
                    currency            = $Currency
                    Date                = $Timestamp
                    estimate_current    = $AlgoData.$Algo.estimate_current
                    estimate_last24h    = $AlgoData.$Algo.estimate_last24h
                    Last24hDrift        = $AlgoData.$Algo.estimate_current - $BasePrice
                    Last24hDriftPercent = If ($BasePrice -gt 0) { ($AlgoData.$Algo.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
                    Last24hDriftSign    = If ($AlgoData.$Algo.estimate_current -ge $BasePrice) { "Up" } Else { "Down" }
                    Name                = $Algo
                }
            }
            Remove-Variable Algo, AlgorithmNorm, BasePrice, BestCurrency, CurrenciesArray, CurrenciesData, Currency, DAGdata -ErrorAction Ignore

            # Created here for performance optimization, minimize # of lookups
            $CurrentPoolObjects = $PoolObjects.Where({ $_.Date -eq $Timestamp })
            $SampleSizets = New-TimeSpan -Minutes $PoolConfig.BrainConfig.SampleSizeMinutes
            $SampleSizeHalfts = New-TimeSpan -Minutes ($PoolConfig.BrainConfig.SampleSizeMinutes / 2)
            $GroupAvgSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
            $GroupMedSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
            $GroupAvgSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
            $GroupMedSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
            $GroupMedSampleSizeNoPercent = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDrift } }

            ForEach ($PoolName in ($PoolObjects.Name | Select-Object -Unique).Where({ $AlgoData.PSObject.Properties.Name -contains $_ })) { 
                $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf.Where({ $_.Name -eq $PoolName + ", Up" })).Count - ($GroupAvgSampleSizeHalf.Where({ $_.Name -eq $Name + ", Down" })).Count) / (($GroupMedSampleSizeHalf.Where({ $_.Name -eq $PoolName })).Count)) * [Math]::abs(($GroupMedSampleSizeHalf.Where({ $_.Name -eq $PoolName })).Median)
                $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize.Where({ $_.Name -eq $PoolName + ", Up" })).Count - ($GroupAvgSampleSize.Where({ $_.Name -eq $Name + ", Down" })).Count) / (($GroupMedSampleSize.Where({ $_.Name -eq $PoolName })).Count)) * [Math]::abs(($GroupMedSampleSizeNoPercent.Where({ $_.Name -eq $PoolName })).Median)
                $Penalty = ($PenaltySampleSizeHalf * $PoolConfig.BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($PoolConfig.BrainConfig.SampleHalfPower + 1)
                $CurPoolObject = $CurrentPoolObjects.Where({ $_.Name -eq $PoolName })
                $Currency = $CurPoolObject.currency
                $LastPrice = [Double]$CurPoolObject.actual_last24h
                $PlusPrice = [Math]::max(0, [Double]($LastPrice + $Penalty))

                # Reset history if PlusPrice is not within +/- 1000% of LastPrice
                If ($LastPrice -gt 0 -and ($PlusPrice -lt $LastPrice * 0.1 -or $PlustPrice -gt $LastPrice * 10)) { 
                    $StatName = If ($Currency) { "$($PoolVariant)_$AlgorithmNorm-$($Currency)_Profit" } Else { "$($PoolVariant)_$($AlgorithmNorm)_Profit" }
                    Remove-Stat -Name $StatName
                    $PoolObjects = $PoolObjects.Where({ $_.Name -ne $PoolName })
                    $PlusPrice = $LastPrice
                    Write-Message -Level Debug "Pool brain '$BrainName': PlusPrice history cleared for '$Poolname' (LastPrice: $LastPrice vs. PlusPrice: $PlusPrice)"
                }
                $AlgoData.$PoolName | Add-Member PlusPrice $PlusPrice -Force
            }
            Remove-Variable CurrentPoolObjects, GroupAvgSampleSize, GroupMedSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, LastPrice, Penalty, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, PlusPrice, PoolName, SampleSizets, SampleSizeHalfts, StatName -ErrorAction Ignore

            If ($PoolConfig.BrainConfig.UseTransferFile -or $Config.PoolsConfig.$BrainName.BrainDebug) { 
                ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -LiteralPath $BrainDataFile -Force -ErrorAction Ignore
            }
        }

        $Variables.BrainData.$BrainName = $AlgoData
        $Variables.Brains.$BrainName | Add-member "Updated" $Timestamp -Force

        # Limit to only sample size + 10 minutes history
        $PoolObjects = @($PoolObjects.Where({ $_.Date -ge $Timestamp.AddMinutes( - ($PoolConfig.BrainConfig.SampleSizeMinutes + 10)) }))
    }
    Catch { 
        Write-Message -Level Error "Error in file 'Brains\$BrainName.ps1' line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting brain..."
        "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Brain_$($BrainName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
        $_.Exception | Format-List -Force >> "Logs\Brain_$($BrainName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
        $_.InvocationInfo | Format-List -Force >> "Logs\Brain_$($BrainName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
    }
    Remove-Variable AlgoData, CurrenciesData -ErrorAction Ignore

    $Duration = ([DateTime]::Now - $StartTime).TotalSeconds
    $Durations += ($Duration, $Variables.Interval | Measure-Object -Minimum).Minimum
    $Durations = @($Durations | Select-Object -Last 20)
    $DurationsAvg = ($Durations | Measure-Object -Average).Average

    Write-Message -Level Debug "Brain '$BrainName': End loop (Duration $Duration sec. / Avg. loop duration: $DurationsAvg sec.); Price history $($PoolObjects.Count) objects; found $($Variables.BrainData.$BrainName.PSObject.Properties.Name.Count) valid pools."

    [System.GC]::Collect()

    While (-not $Variables.MyIP -or $Timestamp -ge $Variables.PoolDataCollectedTimeStamp -or ($Variables.EndCycleTime -and [DateTime]::Now.ToUniversalTime().AddSeconds($DurationsAvg + 3) -le $Variables.EndCycleTime -and [DateTime]::Now.ToUniversalTime() -lt $Variables.EndCycleTime)) { 
        Start-Sleep -Seconds 1
    }
}

$Variables.Brains.Remove($BrainName)
$Variables.BrainData.Remove($BrainName)