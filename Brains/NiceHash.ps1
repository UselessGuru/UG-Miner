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
Version:        6.9.2
Version date:   2026/10/30
#>

using module ..\Includes\Include.psm1

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

$Durations = [TimeSpan[]]@()

$Headers = @{ "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"; "Cache-Control" = "no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

while ($Config.PoolsConfig.$Name) { 

    $APIcallFails = 0
    $StartTime = [DateTime]::Now

    Write-Message -Level Debug "Brain '$Name': Start loop$(if ($Duration) { " (Previous loop duration: $Duration sec.)" })"

    if ($Session.MyIPaddress) { 
        try { 
            $AlgoData = [PSCustomObject]@{ }

            $URL = "https://api2.nicehash.com/main/api/v2/mining/algorithms/"

            $APIallowedFailureCount = $Config.PoolsConfig.$Name.PoolAPIAllowedFailureCount
            Write-Message -Level Debug "Brain '$Name': Querying '$URL'"
            do { 
                try { 
                    Remove-Variable APIerror -ErrorAction Ignore; $APIdata = Invoke-WebRequest -Uri $URL -TimeoutSec $Config.PoolsConfig.$Name.PoolAPItimeout -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck -ErrorAction Ignore -ErrorVariable APIerror 2>$null 3>$null 4>$null 5>$null 6>$null
                } catch { 
                    Write-Message -Level Error "Brain '$Name': Query to '$URL' failed ($($Error[0] | ConvertTo-Json -Compress))"
                }
                $APIallowedFailureCount --
                if (-not $APIdata -and $APIallowedFailureCount -gt 0) { Start-Sleep -Seconds $Config.PoolsConfig.$Name.PoolAPItimeout }
            } until ($APIdata.StatusCode -in @(200, 404) -or $APIerror.Message -eq "The response ended prematurely. (ResponseEnded)" -or $APIallowedFailureCount -eq 0)

            if ($APIerror) { 
                Write-Message -Level Error "Brain '$Name': Query to '$URL' failed ($($APIerror.Message))"
            }
            elseif ($APIdata.Content -and (Test-Json $APIdata.Content -ErrorAction Ignore)) { 
                if ($AlgorithmsData = ($APIdata.Content | ConvertFrom-Json).miningAlgorithms) { 

                    $URL = "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/"
                    Write-Message -Level Debug "Brain '$Name': Querying '$URL'"
                    do { 
                        try { 
                            Remove-Variable APIerror -ErrorAction Ignore; $APIdata = Invoke-WebRequest -Uri $URL -TimeoutSec $Config.PoolsConfig.$Name.PoolAPItimeout -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck -ErrorAction Ignore -ErrorVariable APIerror 2>$null 3>$null 4>$null 5>$null 6>$null
                        } catch { 
                            Write-Message -Level Error "Brain '$Name': Query to '$URL' failed ($($Error[0] | ConvertTo-Json -Compress))"
                        }
                        $APIallowedFailureCount --
                        if (-not $APIdata -and $APIallowedFailureCount -gt 0) { Start-Sleep -Seconds $Config.PoolsConfig.$Name.PoolAPItimeout }
                    } until ($APIdata.StatusCode -in @(200, 404) -or $APIerror.Message -eq "The response ended prematurely. (ResponseEnded)" -or $APIallowedFailureCount -eq 0)

                    if ($APIerror) { 
                        Write-Message -Level Error "Brain '$Name': Query to '$URL' failed ($($APIerror.Message))"
                    }
                    elseif ($APIdata.Content -and (Test-Json $APIdata.Content -ErrorAction Ignore)) { 
                        if ($PricesData = ($APIdata.Content | ConvertFrom-Json).miningAlgorithms) { 

                            $Timestamp = [DateTime]::Now.ToUniversalTime()
                            $AlgorithmsData.ForEach{ 
                                $Algorithm = $_.algorithm
                                $AlgorithmNorm = Get-Algorithm $Algorithm
                                $_ | Add-Member AlgorithmNorm $AlgorithmNorm -Force

                                if ($PriceData = $PricesData.Where{ $_.algorithm -eq $Algorithm }) { 
                                    $_ | Add-Member Paying $PriceData.paying -Force
                                }
                                else { 
                                    $_ | Add-Member Paying ([Double]::NaN) -Force
                                }

                                $Currencies = Get-CurrencyFromAlgorithm $AlgorithmNorm
                                $Currency = if ($Currencies.Count -eq 1) { [String]$Currencies } else { "" }
                                $_ | Add-Member Currency $Currency -Force

                                $_ | Add-Member URL "https://www.nicehash.com/algorithm/$($Algorithm.ToLower())" -Force
                                $_ | Add-Member Updated $Timestamp -Force

                            }

                            Remove-Variable Algorithm, AlgorithmNorm, Currencies, Currency, PriceData -ErrorAction Ignore
                        }
                    }
                }
            }

            $Session.BrainData.$Name = $AlgorithmsData
            $Session.Brains.$Name | Add-Member "Updated" $Timestamp -Force

            if ($Config.PoolsConfig.$Name.BrainConfig.UseTransferFile -or $Config.PoolsConfig.$Name.BrainConfig.Debug) { 
                ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -LiteralPath $BrainDataFile -Force -ErrorAction Ignore
            }
        }
        catch { 
            Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting brain..."
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

    while (-not $Session.MyIPaddress -or ($Session.NewMiningStatus -eq "Paused" -and $Timestamp.AddSeconds($Session.Config.Interval) -gt [DateTime]::Now.ToUniversalTime()) -or ($Session.NewMiningStatus -eq "Running" -and ($Session.PoolDataCollectedTimeStamp -and $Timestamp -ge $Session.PoolDataCollectedTimeStamp -or ($Session.EndCycleTime -and [DateTime]::Now.ToUniversalTime().AddSeconds($DurationsAvg + 4) -le $Session.EndCycleTime)))) { 
        Start-Sleep -Milliseconds 250
    }
}

Remove-Variable APIcallFails, BrainDataFile, Duration, Durations, DurationsAvg, Header, Name, PoolConfig, PoolObjects, PoolVariant, StartTime, TimeStamp, UserAgent -ErrorAction Ignore