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
Version:        6.5.2
Version date:   2025/07/27
#>

If (-not ($Devices = $Session.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.1" }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/CcminerAlexis/ccmineralexis78.7z"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithm = "Blakecoin";  MinMemGiB = 2; MinerSet = 3; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo blakecoin --intensity 22" } # FPGA
    @{ Algorithm = "C11";        MinMemGiB = 3; MinerSet = 1; WarmupTimes = @(60, 0); ExcludePools = @(); Arguments = " --algo c11 --intensity 22" }
#   @{ Algorithm = "Keccak";     MinMemGiB = 3; MinerSet = 3; WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo keccak --diff-multiplier 2 --intensity 29" } # ASIC
#   @{ Algorithm = "Lyra2RE2";   MinMemGiB = 3; MinerSet = 3; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo lyra2v2" } # ASIC
    @{ Algorithm = "Neoscrypt";  MinMemGiB = 3; MinerSet = 1; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo neoscrypt --intensity 15.5" } # FPGA
#   @{ Algorithm = "Skein";      MinMemGiB = 3; MinerSet = 0; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo skein" } # ASIC
    @{ Algorithm = "Skein2";     MinMemGiB = 3; MinerSet = 0; WarmupTimes = @(60, 0); ExcludePools = @(); Arguments = " --algo skein2 --intensity 31.9" }
    @{ Algorithm = "Veltor";     MinMemGiB = 2; MinerSet = 2; WarmupTimes = @(40, 0); ExcludePools = @(); Arguments = " --algo veltor --intensity 23" }
    @{ Algorithm = "Whirlcoin";  MinMemGiB = 2; MinerSet = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo whirlcoin" }
    @{ Algorithm = "Whirlpool";  MinMemGiB = 2; MinerSet = 2; WarmupTimes = @(40, 0); ExcludePools = @(); Arguments = " --algo whirlpool" }
    @{ Algorithm = "X11evo";     MinMemGiB = 2; MinerSet = 2; WarmupTimes = @(40, 0); ExcludePools = @(); Arguments = " --algo x11evo --intensity 21" }
    @{ Algorithm = "X17";        MinMemGiB = 3; MinerSet = 1; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo x17 --intensity 22" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIport + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    $MinMemGiB = $_.MinMemGiB
                    If ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($_.Algorithm)"

                        # $ExcludePools = $_.ExcludePools
                        # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] })) { 

                            $Arguments = $_.Arguments
                            If ($AvailableMinerDevices.Where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace " --intensity .+$" }

                            [PSCustomObject]@{ 
                                API         = "CcMiner"
                                Arguments   = "$Arguments --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass) --retry-pause 1 --api-bind $MinerAPIPort --cuda-schedule 2 --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
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