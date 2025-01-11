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
File:           \Brains\ZergPool.ps1
Version:        6.4.0
Version date:   2025/01/11
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
$PoolConfig = $Variables.PoolsConfig.$BrainName

$BrainDataFile = "$PWD\Data\BrainData_$BrainName.json"

While ($PoolConfig = $Config.PoolsConfig.$BrainName) { 

    $PoolVariant = [String]$Config.PoolName.Where({ $_ -like "$BrainName*" })
    $StartTime = [DateTime]::Now

    Try { 

        Write-Message -Level Debug "Brain '$BrainName': Start loop$(If ($Duration) { " (Previous loop duration: $Duration sec.)" })"

        Do { 
            Try { 
                $AlgoData = Invoke-RestMethod -Uri "https://zergpool.com/api/status" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout

                $APICallFails = 0
            }
            Catch { 
                If ($APICallFails -lt $PoolConfig.PoolAPIAllowedFailureCount) { $APICallFails ++ }
                Start-Sleep -Seconds ([Math]::max(60, ($APICallFails * 5 + $PoolConfig.PoolAPIretryInterval)))
            }
        } While (-not $AlgoData -and $APICallFails -lt $Config.PoolAPIallowedFailureCount)

        $Timestamp = [DateTime]::Now.ToUniversalTime()

        If ($AlgoData.PSObject.Properties.Name) { 
            $AlgoData.PSObject.Properties.Name.Where({ $AlgoData.$_.algo -eq "Token" -or $_ -like "*-*" }).ForEach({ $AlgoData.PSObject.Properties.Remove($_) })
            $AlgoData.PSObject.Properties.Name.Where({ $AlgoData.$_.algo }).ForEach(
                { 
                    $AlgoData.$_ | Add-Member Currency [String]$AlgoData.$_.symbol
                    $AlgoData.$_ | Add-Member CoinName [String]$AlgoData.$_.name
                    $AlgoData.$_.PSObject.Properties.Remove("symbol")
                    $AlgoData.$_.PSObject.Properties.Remove("name")
                }
            )
            $AlgoData.PSObject.Properties.Name.Where({ -not $AlgoData.$_.algo }).ForEach(
                { 
                    $AlgoData.$_ | Add-Member @{ algo = $AlgoData.$_.name }
                    $AlgoData.$_.PSObject.Properties.Remove("name")
                }
            )

            # Change numeric string to numbers, some values are null
            $AlgoData = ($AlgoData | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json

            ForEach ($Algo in $AlgoData.PSObject.Properties.Name) { 
                $AlgorithmNorm = Get-Algorithm $AlgoData.$Algo.algo
                $Currency = [String]$AlgoData.$Algo.Currency
                If ($AlgoData.$Algo.actual_last24h_shared) { $AlgoData.$Algo.actual_last24h_shared /= 1000 }
                $BasePrice = If ($AlgoData.$Algo.actual_last24h_shared) { $AlgoData.$Algo.actual_last24h_shared } Else { $AlgoData.$Algo.estimate_last24h }

                # Add currency and coin name to database
                If ($AlgoData.$Algo.CoinName) { 
                    Try { 
                        [Void](Add-CoinName -Algorithm $AlgorithmNorm -Currency $Currency -CoinName $AlgoData.$Algo.CoinName)
                    }
                    Catch { }
                }

                # Keep DAG data up to date
                If ($AlgorithmNorm -match $Variables.RegexAlgoHasDAG -and $AlgoData.$Algo.height -gt $Variables.DAGdata.Currency.$Currency.BlockHeight) { 
                    $DAGdata = (Get-DAGData -BlockHeight $AlgoData.$Algo.height -Currency $Algo -EpochReserve 2)
                    $DAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                    $DAGdata | Add-Member Url $Uri
                    $Variables.DAGdata.Currency | Add-Member $Algo $DAGdata -Force
                    $Variables.DAGdata.Updated | Add-Member $Uri ([DateTime]::Now).ToUniversalTime() -Force
                }

                $AlgoData.$Algo | Add-Member Fees $Config.PoolsConfig.$BrainName.DefaultFee -Force
                $AlgoData.$Algo | Add-Member Updated $Timestamp -Force

                # Reset history when stat file got removed
                If ($PoolVariant -like "*Plus") { 
                    $StatName = If ($Currency) { "$($PoolVariant)_$($AlgorithmNorm)-$($Currency)_Profit" } Else { "$($PoolVariant)_$($AlgorithmNorm)_Profit" }
                    If (-not ($Stat = Get-Stat -Name $StatName) -and $PoolObjects.Where({ $_.Name -eq $PoolName })) { 
                        $PoolObjects = $PoolObjects.Where({ $_.Name -ne $Algo })
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

            # Created here for performance optimization, minimize # of lookups
            $CurrentPoolObjects = $PoolObjects.Where({ $_.Date -eq $Timestamp })
            $SampleSizets = New-TimeSpan -Minutes $PoolConfig.BrainConfig.SampleSizeMinutes
            $SampleSizeHalfts = New-TimeSpan -Minutes ($PoolConfig.BrainConfig.SampleSizeMinutes / 2)
            $GroupAvgSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
            $GroupMedSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
            $GroupAvgSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
            $GroupMedSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
            $GroupMedSampleSizeNoPercent = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDrift } }

            ForEach ($Algo in ($PoolObjects.Name | Select-Object -Unique).Where({ $AlgoData.PSObject.Properties.Name -contains $_ })) { 
                $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf.Where({ $_.Name -eq $Algo + ", Up" })).Count - ($GroupAvgSampleSizeHalf.Where({ $_.Name -eq $Algo + ", Down" })).Count) / (($GroupMedSampleSizeHalf.Where({ $_.Name -eq $Algo })).Count)) * [Math]::abs(($GroupMedSampleSizeHalf.Where({ $_.Name -eq $Algo })).Median)
                $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize.Where({ $_.Name -eq $Algo + ", Up" })).Count - ($GroupAvgSampleSize.Where({ $_.Name -eq $Algo + ", Down" })).Count) / (($GroupMedSampleSize.Where({ $_.Name -eq $Algo })).Count)) * [Math]::abs(($GroupMedSampleSizeNoPercent.Where({ $_.Name -eq $Algo })).Median)
                $Penalty = ($PenaltySampleSizeHalf * $PoolConfig.BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($PoolConfig.BrainConfig.SampleHalfPower + 1)
                $CurPoolObject = $CurrentPoolObjects.Where({ $_.Name -eq $Algo })
                $Currency = $CurPoolObject.currency
                $LastPrice = [Double]$CurPoolObject.estimate_current
                $PlusPrice = [Math]::max(0, [Double]($LastPrice + $Penalty))

                $StatName = If ($Currency) { "$($PoolVariant)_$(Get-Algorithm $Algo)-$($Currency)_Profit" } Else { "$($PoolVariant)_$(Get-Algorithm $Algo)_Profit" }
                # Reset history if current estimate is not within +/- 1000% of 24hr stat price
                If ($Stat = Get-Stat -Name $StatName) { 
                    $Divisor = $PoolConfig.Variant."$PoolVariant".DivisorMultiplier * $AlgoData.$Algo.mbtc_mh_factor
                    If ($Stat.Day -and $LastPrice -gt 0 -and ($AlgoData.$Algo.estimate_current / $Divisor -lt $Stat.Day / 10 -or $AlgoData.$Algo.estimate_current / $Divisor -gt $Stat.Day * 10)) { 
                        Remove-Stat -Name $StatName
                        $PoolObjects = $PoolObjects.Where({ $_.Name -ne $Algo })
                        $PlusPrice = $LastPrice
                        Write-Message -Level Debug "Pool brain '$BrainName': PlusPrice history cleared for $($StatName -replace '_Profit') (stat day price: $($Stat.Day) vs. estimate current price: $($AlgoData.$Algo.estimate_current / $Divisor))"
                    }
                }
                $AlgoData.$Algo | Add-Member PlusPrice $PlusPrice -Force
            }
            Remove-Variable Algo, AlgorithmNorm, BasePrice, CurPoolObject, Currency, CurrentPoolObjects, DAGdata, GroupAvgSampleSize, GroupMedSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, LastPrice, Penalty, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, PlusPrice, SampleSizeHalfts, SampleSizets, Stat, StatName -ErrorAction Ignore

            If ($PoolConfig.BrainConfig.UseTransferFile -or $Config.PoolsConfig.$BrainName.BrainDebug) { 
                ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -LiteralPath $BrainDataFile -Force -ErrorAction Ignore
            }
        }

        $Variables.BrainData.$BrainName = $AlgoData
        $Variables.Brains.$BrainName | Add-Member "Updated" $Timestamp -Force

        # Limit to only sample size + 10 minutes history
        $PoolObjects = @($PoolObjects.Where({ $_.Date -ge $Timestamp.AddMinutes( - ($PoolConfig.BrainConfig.SampleSizeMinutes + 10)) }))
    }
    Catch { 
        Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting core..."
        "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Brain_$($BrainName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
        $_.Exception | Format-List -Force >> "Logs\Brain_$($BrainName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
        $_.InvocationInfo | Format-List -Force >> "Logs\Brain_$($BrainName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
    }
    Remove-Variable AlgoData -ErrorAction Ignore

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