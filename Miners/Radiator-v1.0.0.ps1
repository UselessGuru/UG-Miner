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
Version:        6.6.6
Version date:   2025/11/20
#>

If (-not ($Devices = $Session.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = Switch ($Session.DriverVersion.CUDA) { 
    { $_ -ge [System.Version]"11.6" } { "https://github.com/xiaolin1579/radiator/releases/download/v1.0.0/Radiator1.0.0_cuda11.6_Win64.zip"; Break }
    { $_ -ge [System.Version]"11.2" } { "https://github.com/xiaolin1579/radiator/releases/download/v1.0.0/Radiator1.0.0_cuda11.2_Win64.zip"; Break }
    Default                           { Return }
}
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithm = "SHA512256d"; MinMemGiB = 2; MinerSet = 1; WarmupTimes = @(90, 0); ExcludeGPUarchitectures = "^Other$"; ExcludePools = @(); Arguments = " --algo=rad" }
    @{ Algorithm = "SHA256dt";   MinMemGiB = 2; MinerSet = 1; WarmupTimes = @(90, 0); ExcludeGPUarchitectures = " ";       ExcludePools = @(); Arguments = " --algo=novo" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Session.Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    $MinMemGiB = $_.MinMemGiB
                    If ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB -and $_.Architecture -notmatch $ExcludeGPUarchitectures})) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($_.Algorithm)"

                        # $ExcludePools = $_.ExcludePools
                        # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] })) { 

                            $Arguments = $_.Arguments
                            If ($_.Algorithm -eq "SHA512256d" -and $AvailableMinerDevices.Where({ $_.MemoryGiB -le 2 })) { $Arguments += " --intensity 27.1" } # Default intensity is too high for 2GB cards

                            [PSCustomObject]@{ 
                                API         = "CcMiner"
                                Arguments   = "$Arguments --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass) --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
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