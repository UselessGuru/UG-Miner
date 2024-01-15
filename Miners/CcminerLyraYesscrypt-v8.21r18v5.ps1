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
Version:        6.1.0
Version date:   2024/01/15
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.1" }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/CcminerYescrypt/ccmineryescryptrV5.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";    MinMemGiB = 3; MinerSet = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo lyra2v3 --intensity 24" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2z330";   MinMemGiB = 3; MinerSet = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo lyra2z330 --intensity 13.2" } # Algorithm is dead
#   [PSCustomObject]@{ Algorithm = "Yescrypt";    MinMemGiB = 2; MinerSet = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo yescrypt" } # bad shares, CcminerLyra2z330-v8.21r9 is fastest
    [PSCustomObject]@{ Algorithm = "YescryptR16"; MinMemGiB = 3; MinerSet = 0; WarmupTimes = @(60, 0); ExcludePools = @(); Arguments = " --algo yescryptr16 --intensity 13.2" }
    [PSCustomObject]@{ Algorithm = "YescryptR32"; MinMemGiB = 3; MinerSet = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo yescryptr32 -i 12" } # Default intensity causes out of memory error, set custom intensity; use -i to keep it for low mem GPUs
    [PSCustomObject]@{ Algorithm = "YescryptR8";  MinMemGiB = 2; MinerSet = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo yescryptr8 --intensity 13.2" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    ($Devices | Select-Object Model -Unique).ForEach(
        { 
            $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
            $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    $ExcludePools = $_.ExcludePools
                    ForEach ($Pool in ($MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $_.Name -notin $ExcludePools }))) { 

                        $MinMemGiB = $_.MinMemGiB
                        If ($AvailableMiner_Devices = $Miner_Devices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                            $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                            $Arguments = $_.Arguments
                            If ($AvailableMiner_Devices.Where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace ' --intensity [0-9\.]+' }

                            [PSCustomObject]@{ 
                                API         = "CcMiner"
                                Arguments   = "$Arguments --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass) --statsavg 5 --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMiner_Devices.Name
                                Fee         = @(0) # Dev fee
                                MinerSet    = $_.MinerSet
                                Name        = $Miner_Name
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = "NVIDIA"
                                URI         = $Uri
                                WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}