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
File:           \Brains\Kryptex.ps1
Version:        6.9.0
Version date:   2026/10/24
#>

using module ..\Includes\Include.psm1

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

$Headers = @{ "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"; "Cache-Control" = "no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

$PoolObjects = @()
$Durations = [TimeSpan[]]@()

while ($Config.PoolsConfig.$Name) { 

    $PoolVariant = [String]$Session.Config.PoolName.Where{ $_ -like "$Name*" }
    $StartTime = [DateTime]::Now

    Write-Message -Level Debug "Brain '$Name': Start loop$(if ($Duration) { " (Previous loop duration: $Duration sec.)" })"

    if ($Session.MyIPaddress) { 
        try { 

            $Session."$($Name)APIrequestTimestamp" = [DateTime]::Now.ToUniversalTime()
            $URL = "https://pool.kryptex.com/api/v1/index"

            Write-Message -Level Debug "Brain '$Name': Querying '$URL'"
            $APIallowedFailureCount = $Config.PoolsConfig.$Name.PoolAPIAllowedFailureCount
            do { 
                try { Remove-Variable APIerror -ErrorAction Ignore; $APIdata = Invoke-WebRequest -Uri $URL -TimeoutSec $Config.PoolsConfig.$Name.PoolAPItimeout -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck -ErrorAction Ignore -ErrorVariable APIerror 2>$null 3>$null 4>$null 5>$null 6>$null } catch { }
                $APIallowedFailureCount --
            } until ($APIdata.StatusCode -in @(200, 404) -or $APIerror.Message -eq "The response ended prematurely. (ResponseEnded)" -or $APIallowedFailureCount -eq 0)

            if ($APIerror) { 
                Write-Message -Level Error "Brain '$Name': Query to '$URL' failed ($($APIerror.Message))"
            }
            elseif ($APIdata.Content -and (Test-Json $APIdata.Content -ErrorAction Ignore)) { 
                if ($PoolsList = $APIdata.Content | ConvertFrom-Json) { 

                    $PoolData = @{ }

                    if (-not $Session.KryptexCurrencies) { 
                        $Session.KryptexCurrencies = @($Session.PoolData.Kryptex.GuaranteedPayoutCurrencies)
                        $Session.KryptexCurrenciesUpdated = [DateTime]::Now.ToUniversalTime()
                    }

                    # Get information for each available pool
                    foreach ($PoolName in ($PoolsList.PSObject.Properties.Name | Sort-Object)) { 

                        $URL = "https://pool.kryptex.com/$($PoolName.ToLower())/api/v1/pool/info"

                        $APIallowedFailureCount = $Config.PoolsConfig.$Name.PoolAPIAllowedFailureCount
                        Write-Message -Level Debug "Brain '$Name': Querying '$URL'"
                        do { 
                            try { Remove-Variable APIerror -ErrorAction Ignore; $APIdata = Invoke-WebRequest -Uri $URL -TimeoutSec $Config.PoolsConfig.$Name.PoolAPItimeout -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck -ErrorAction Ignore -ErrorVariable APIerror 2>$null 3>$null 4>$null 5>$null 6>$null } catch { }
                            $APIallowedFailureCount --
                        } until ($APIdata.StatusCode -in @(200, 404) -or $APIerror.Message -eq "The response ended prematurely. (ResponseEnded)" -or $APIallowedFailureCount -eq 0)

                        if ($APIerror) { 
                            Write-Message -Level Error "Brain '$Name': Query to '$URL' failed ($($APIerror.Message))"
                        }
                        elseif ($APIdata.Content -and (Test-Json $APIdata.Content -ErrorAction Ignore)) { 
                            if ($PoolInfo = $APIdata.Content | ConvertFrom-Json) { 
                                $PoolInfo | Add-Member Currency ($PoolName -replace "-.+").ToUpper()
                                $PoolData | Add-Member $PoolName $PoolInfo -Force
                            }
                            Remove-Variable PoolInfo -ErrorAction Ignore
                        }
                    }
                    Remove-Variable PoolName -ErrorAction Ignore

                    $Timestamp = [DateTime]::Now.ToUniversalTime()

                    foreach ($PoolName in $PoolData.PSObject.Properties.Name) { 

                        $PoolData.$PoolName | Add-Member AlgorithmNorm (Get-Algorithm $PoolData.$PoolName.algo)

                        $Currency = [String]$PoolData.$PoolName.Currency # Without cast value might be $null
                        if ($Currency -notin $Session.KryptexCurrencies) { 
                            $Session.KryptexCurrencies = (@($Session.KryptexCurrencies) + $Currency ) | Sort-Object -Unique
                            $Session.KryptexCurrenciesUpdated = [DateTime]::Now.ToUniversalTime()
                        }

                        # Add algorithm only if there is no other coin with the same algorithm
                        if ($PoolData.PSObject.Properties.Name.Where{ $Currency -eq $PoolData.$_.Currency }.Count -eq 1) { 
                            Add-CurrencyAlgorithm -Algorithm $PoolData.$PoolName.algo -Currency $Currency
                        }

                        $PoolData.$PoolName.PSObject.Properties.Remove("ticker")
                        $PoolData.$PoolName.PSObject.Properties.Remove("symbol")
                        $PoolData.$PoolName.PSObject.Properties.Remove("name")

                        $PoolData.$PoolName | Add-Member CoinName ([String]$Session.CoinNames[$Currency]) -Force
                        $PoolData.$PoolName | Add-Member Updated $Timestamp -Force
                        $PoolData.$PoolName | Add-Member Url "https://pool.kryptex.com/$($PoolName.ToLower())"

                        Remove-Variable Currency
                    }

                    $Session.BrainData.$Name = $PoolData
                    $Session.Brains.$Name | Add-Member "Updated" $Timestamp -Force

                    if ($Config.PoolsConfig.$Name.BrainConfig.UseTransferFile -or $Config.PoolsConfig.$Name.BrainConfig.Debug) { 
                        ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -LiteralPath $BrainDataFile -Force -ErrorAction Ignore
                    }
                }
            }
        }
        catch { 
            Write-Message -Level Error "Error in file '$(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\")' line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting brain..."
            "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
            $_.Exception | Format-List -Force >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
            $_.InvocationInfo | Format-List -Force >> "Logs\Brain_$($Name)_Error_$(Get-Date -Format "yyyy-MM-dd").txt"
        }
        Remove-Variable APIallowedFailureCount, Currency, PoolData, PoolList -ErrorAction Ignore

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

Remove-Variable BrainDataFile, Duration, Durations, DurationsAvg, Handler, Name, PoolConfig, PoolObjects, PoolVariant, StartTime, UserAgent -ErrorAction Ignore