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
Version:        6.3.1
Version date:   2024/09/06
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

    $PoolVariantOld = $PoolVariant
    $PoolVariant = [String]$Config.PoolName.Where({ $_ -like "$BrainName*" })
    $StartTime = [DateTime]::Now

    Try { 

        Write-Message -Level Debug "Brain '$BrainName': Start loop$(If ($Duration) { " (Previous loop duration: $Duration sec.)" })"

        Do { 
            Try { 
                $APIdata = Invoke-RestMethod -Uri $PoolConfig.PoolStatusUri -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPItimeout

                $APICallFails = 0
            }
            Catch { 
                If ($APICallFails -lt $PoolConfig.PoolAPIAllowedFailureCount) { $APICallFails ++ }
                Start-Sleep -Seconds ([Math]::max(60, ($APICallFails * 5 + $PoolConfig.PoolAPIretryInterval)))
            }
        } While (-not $APIdata -and $APICallFails -lt $Config.PoolAPIallowedFailureCount)

        $Timestamp = [DateTime]::Now.ToUniversalTime()

        If ($APIdata.PSObject.Properties.Name) { 
            $APIdata.PSObject.Properties.Name.Where({ $APIdata.$_.algo -eq "Token" -or $_ -like "*-*" }).ForEach({ $APIdata.PSObject.Properties.Remove($_) })
            $APIdata.PSObject.Properties.Name.Where({ $APIdata.$_.algo }).ForEach(
                { 
                    $APIdata.$_ | Add-Member Currency $(If ($APIdata.$_.symbol) { $APIdata.$_.symbol })
                    $APIdata.$_ | Add-Member CoinName $(If ($APIdata.$_.name) { $APIdata.$_.name })
                    $APIdata.$_.PSObject.Properties.Remove("symbol")
                    $APIdata.$_.PSObject.Properties.Remove("name")
                }
            )
            $APIdata.PSObject.Properties.Name.Where({ -not $APIdata.$_.algo }).ForEach(
                { 
                    $APIdata.$_ | Add-Member @{ algo = $APIdata.$_.name }
                    $APIdata.$_.PSObject.Properties.Remove("name")
                }
            )

            # Change numeric string to numbers, some values are null
            $APIdata = ($APIdata | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json

            ForEach ($PoolName in $APIdata.PSObject.Properties.Name) { 
                $AlgorithmNorm = Get-Algorithm $APIdata.$PoolName.algo
                $Currency = [String]$APIdata.$PoolName.Currency
                If ($APIdata.$PoolName.actual_last24h_shared) { $APIdata.$PoolName.actual_last24h_shared /= 1000 }
                $BasePrice = If ($APIdata.$PoolName.actual_last24h_shared) { $APIdata.$PoolName.actual_last24h_shared } Else { $APIdata.$PoolName.estimate_last24h }

                # Add currency and coin name to database
                If ($APIdata.$PoolName.CoinName) { 
                    Try { 
                        [Void](Add-CoinName -Algorithm $AlgorithmNorm -Currency $Currency -CoinName $APIdata.$PoolName.CoinName)
                    }
                    Catch { }
                }

                # Keep DAG data up to date
                If ($AlgorithmNorm -match $Variables.RegexAlgoHasDAG -and $APIdata.$PoolName.height -gt $Variables.DAGdata.Currency.$Currency.BlockHeight) { 
                    $DAGdata = (Get-DAGData -BlockHeight $APIdata.$PoolName.height -Currency $PoolName -EpochReserve 2)
                    $DAGdata | Add-Member Date ([DateTime]::Now.ToUniversalTime()) -Force
                    $DAGdata | Add-Member Url $Uri
                    $Variables.DAGdata.Currency | Add-Member $PoolName $DAGdata -Force
                    $Variables.DAGdata.Updated | Add-Member $Uri ([DateTime]::Now).ToUniversalTime() -Force
                }

                $APIdata.$PoolName | Add-Member Fees $Config.PoolsConfig.$BrainName.DefaultFee -Force
                $APIdata.$PoolName | Add-Member Updated $Timestamp -Force

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
                    estimate_current    = $APIdata.$PoolName.estimate_current
                    estimate_last24h    = $APIdata.$PoolName.estimate_last24h
                    Last24hDrift        = $APIdata.$PoolName.estimate_current - $BasePrice
                    Last24hDriftPercent = If ($BasePrice -gt 0) { ($APIdata.$PoolName.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
                    Last24hDriftSign    = If ($APIdata.$PoolName.estimate_current -ge $BasePrice) { "Up" } Else { "Down" }
                    Name                = $PoolName
                }
            }
            Remove-Variable AlgorithmNorm, BasePrice, Currency, DAGdata, PoolName, StatName -ErrorAction Ignore

            # Created here for performance optimization, minimize # of lookups
            $CurrentPoolObjects = $PoolObjects.Where({ $_.Date -eq $Timestamp })
            $SampleSizets = New-TimeSpan -Minutes $PoolConfig.BrainConfig.SampleSizeMinutes
            $SampleSizeHalfts = New-TimeSpan -Minutes ($PoolConfig.BrainConfig.SampleSizeMinutes / 2)
            $GroupAvgSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
            $GroupMedSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
            $GroupAvgSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
            $GroupMedSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
            $GroupMedSampleSizeNoPercent = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name | Select-Object Name, Count, @{ Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDrift } }

            ForEach ($PoolName in ($PoolObjects.Name | Select-Object -Unique).Where({ $APIdata.PSObject.Properties.Name -contains $_ })) { 
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
                $APIdata.$PoolName | Add-Member PlusPrice $PlusPrice -Force
            }
            Remove-Variable CurPoolObject, CurrentPoolObjects, GroupAvgSampleSize, GroupMedSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, LastPrice, Penalty, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, PlusPrice, PoolName, SampleSizets, SampleSizeHalfts, StatName -ErrorAction Ignore

            If ($PoolConfig.BrainConfig.UseTransferFile -or $Config.PoolsConfig.$BrainName.BrainDebug) { 
                ($APIdata | ConvertTo-Json).replace("NaN", 0) | Out-File -LiteralPath $BrainDataFile -Force -ErrorAction Ignore
            }
        }

        $Variables.BrainData.$BrainName = $APIdata
        $Variables.Brains.$BrainName | Add-member "Updated" $Timestamp -Force

        # Limit to only sample size + 10 minutes history
        $PoolObjects = @($PoolObjects.Where({ $_.Date -ge $Timestamp.AddMinutes( - ($PoolConfig.BrainConfig.SampleSizeMinutes + 10)) }))
    }
    Catch { 
        Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting core..."
        "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Brain_$($BrainName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
        $_.Exception | Format-List -Force >> "Logs\Brain_$($BrainName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
        $_.InvocationInfo | Format-List -Force >> "Logs\Brain_$($BrainName)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
    }
    Remove-Variable APIdata -ErrorAction Ignore

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