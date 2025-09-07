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
Version:        6.5.11
Version date:   2025/09/07
#>

If (-not ($Devices = $Session.EnabledDevices.Where({ $_.CUDAversion -ge "12.8" -and $_.Architecture -ne "Other" }))) { Return }

$URI = "https://github.com/Zero-Dynamics/ccminer/releases/download/2.4.1-0dyn/ccminer.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithm = "Argon2d1000"; MinMemGiB = 2; MinerSet = 1; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d1000" }
    @{ Algorithm = "Argon2d250";  MinMemGiB = 2; MinerSet = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d250" }
    @{ Algorithm = "Argon2d500";  MinMemGiB = 2; MinerSet = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d500" }
    @{ Algorithm = "Argon2d4096"; MinMemGiB = 2; MinerSet = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d4096" }

)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Session.ConfigRunning.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model })
            $MinerAPIPort = $Session.ConfigRunning.APIport + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    $MinMemGiB = $_.MinMemGiB
                    If ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($_.Algorithm)"

                        $ExcludePools = $_.ExcludePools
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 

                            $Arguments = $_.Arguments
                            If ($AvailableMinerDevices.Where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace " --intensity .+$" }

                            [PSCustomObject]@{ 
                                API         = "CcMiner"
                                Arguments   = "$Arguments --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass) --timeout 50000 --retry-pause 1 --statsavg 5 --api-bind $MinerAPIPort --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = @(0) # Dev fee
                                MinerSet    = $_.MinerSet
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = "NVIDIA"
                                URI         = $URI
                                WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers      = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}