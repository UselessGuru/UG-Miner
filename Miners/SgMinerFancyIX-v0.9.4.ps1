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
Version:        6.4.13
Version date:   2025/02/23
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" }))) { Return }

$URI = "https://github.com/fancyIX/sgminer-phi2-branch/releases/download/0.9.4/sgminer-fancyIX-win64-0.9.4.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\sgminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithm = "0x10";          MinMemGiB = 2; MinerSet = 2; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = @();        ExcludePools = @(); Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 17 --kernel chainox" }
    @{ Algorithm = "HeavyHash";     MinMemGiB = 2; MinerSet = 1; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = @();        ExcludePools = @(); Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 23 --kernel heavyhash" } # FPGA
    @{ Algorithm = "Neoscrypt";     MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = @("GCN1");  ExcludePools = @(); Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 17 --kernel neoscrypt" } # FPGA
    @{ Algorithm = "NeoscryptXaya"; MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = @();        ExcludePools = @(); Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 17 --kernel neoscrypt-xaya" }
    @{ Algorithm = "YescryptR16";   MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUarchitectures = @();        ExcludePools = @(); Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 20 --pool-nfactor 100 --kernel yescryptr16" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    $MinMemGiB = $_.MinMemGiB
                    If ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB -and $ExcludeGPUarchitectures -notcontains $_.Architecture })) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($_.Algorithm)"

                        $ExcludePools = $_.ExcludePools
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 

                            [PSCustomObject]@{ 
                                API         = "Xgminer"
                                Arguments   = "$($_.Arguments) --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass) --api-listen --api-port $MinerAPIPort --gpu-platform $($AvailableMinerDevices.PlatformId | Sort-Object -Unique) --device $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMinerDevices.Name
                                EnvVars     = @("GPU_MAX_ALLOC_PERCENT=100")
                                Fee         = @(0) # Dev fee
                                MinerSet    = $_.MinerSet
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = "AMD"
                                URI         = $URI
                                WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}