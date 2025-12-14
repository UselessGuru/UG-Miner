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
Version:        6.7.8
Version date:   2025/12/14
#>

if (-not ($Devices = $Session.EnabledDevices.where({ $_.OpenCL.ComputeCapability -ge "5.1" }))) { return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/CcminerLyra2Z/ccminerlyra2z330v3.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithm = "Blakecoin";   MinMemGiB = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo blakecoin --intensity 12.3" } # FPGA
#   @{ Algorithm = "Lyra2z330";   MinMemGiB = 3; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo lyra2z330 -intensity 12.5" } # Algorithtm is dead
#   @{ Algorithm = "Yescrypt";    MinMemGiB = 3; WarmupTimes = @(75, 5); ExcludePools = @(); Arguments = " --algo yescrypt" } # Too many bad shares
    @{ Algorithm = "YescryptR16"; MinMemGiB = 3; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo yescryptr16 --intensity 13.3" } # CcminerLyra-v8.21r18v5 is fastest
    @{ Algorithm = "YescryptR32"; MinMemGiB = 3; WarmupTimes = @(60, 0); ExcludePools = @(); Arguments = " --algo yescryptr32 --intensity 12.3" } # CcminerLyra-v8.21r18v5 is fastest
    @{ Algorithm = "YescryptR8";  MinMemGiB = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo yescryptr8" }
)

$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.where({ $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.ForEach(
                { 
                    $MinMemGiB = $_.MinMemGiB
                    if ($AvailableMinerDevices = $MinerDevices.where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($_.Algorithm)"

                        # $ExcludePools = $_.ExcludePools
                        # foreach ($Pool in $MinerPools[0][$_.Algorithm].where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 
                        foreach ($Pool in $MinerPools[0][$_.Algorithm].where({ $_.PoolPorts[0] })) { 

                            $Arguments = $_.Arguments
                            if ($AvailableMinerDevices.where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace " --intensity .+$" }

                            [PSCustomObject]@{ 
                                API         = "CcMiner"
                                Arguments   = "$Arguments --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass) --statsavg 5 --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = @(0) # Dev fee
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = "NVIDIA"
                                URI         = $URI
                                WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}