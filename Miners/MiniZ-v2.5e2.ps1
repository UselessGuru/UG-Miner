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
Version:        6.7.0
Version date:   2025/11/23
#>

# Added support for RTX 50XX GPUs.
# Added new Telemetry page: localhost:20000/tele2 (experimental).
# Fixed failover pools. Now miniZ respects the user-pool priority, and has a much more robust pool handling.
# Fixed some rare issues with ProgPoW causing error 400.
# Fixed password integration on the --url: --url=wallet.worker:pass@server:port

if (-not ($Devices = $Session.EnabledDevices.Where({ $_.Type -eq "AMD" -or $_.OpenCL.ComputeCapability -ge "5.0" }))) { return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/MiniZ/miniZ_v2.5e2_win-x64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\miniZ.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithm = "Equihash1254"; Type = "AMD"; Fee = @(0.02); MinMemGiB = 3.0; MinerSet = 1; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(); AutoCoinPers = ""; Arguments = " --amd --par=125,4 --smart-pers" }
    @{ Algorithm = "Equihash1505"; Type = "AMD"; Fee = @(0.02); MinMemGiB = 4.0; MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = "^ "; ExcludePools = @(); AutoCoinPers = ""; Arguments = " --amd --par=150,5 --smart-pers" }
  
    @{ Algorithm = "Equihash1254"; Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 3.0; MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(); AutoCoinPers = ""; Arguments = " --nvidia --par=125,4 --smart-pers" }
    @{ Algorithm = "Equihash1505"; Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 4.0; MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(); AutoCoinPers = ""; Arguments = " --nvidia --par=150,5 --smart-pers" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Session.Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0].($_.Algorithm) })

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).foreach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.Where({ $_.Type -eq $Type }).foreach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    if ($SupportedMinerDevices = $MinerDevices.Where({ $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        $ExcludePools = $_.ExcludePools
                        foreach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 

                            $MinMemGiB = $_.MinMemGiB + $Pool.DAGsizeGiB
                            if ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                                $Arguments = $_.Arguments
                                $Arguments += " --url=$(If ($Pool.PoolPorts[1]) { "ssl://" })$($Pool.User)@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1)"
                                if ($Pool.WorkerName -and $Pool.User -notmatch "\.$($Pool.WorkerName)$") { $Arguments += " --worker=$($Pool.WorkerName)" }
                                if ($_.AutoCoinPers) { $Arguments += Get-EquihashCoinPers -Command " --pers " -Currency $Pool.Currency -DefaultCommand $_.AutoCoinPers }
                                $Arguments += " --pass=$($Pool.Pass)"

                                # Apply tuning parameters
                                if ($Session.ApplyMinerTweaks) { $_.Arguments += $_.Tuning }

                                [PSCustomObject]@{ 
                                    API         = "MiniZ"
                                    Arguments   = "$Arguments --jobtimeout=900 --retries=99 --retrydelay=1 --stat-int=10 --nohttpheaders --latency --all-shares --extra --tempunits=C --show-pers --fee-time=60 --telemetry $MinerAPIPort -cd $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).foreach({ '{0:d2}' -f $_ }) -join " ")"
                                    DeviceNames = $AvailableMinerDevices.Name
                                    Fee         = $_.Fee # Dev fee
                                    MinerSet    = $_.MinerSet
                                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                    Name        = $MinerName
                                    Path        = $Path
                                    Port        = $MinerAPIPort
                                    Type        = $Type
                                    URI         = $URI
                                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                    Workers     = @(@{ Pool = $Pool })
                                }
                            }
                        }
                    }
                }
            )
        }
    )
}