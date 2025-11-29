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
Version:        6.7.2
Version date:   2025/11/29
#>

if (-not ($AvailableMinerDevices = $Session.EnabledDevices.where({ $_.Type -eq "CPU" }))) { return }

$URI = "https://github.com/fireworm71/veriumMiner/releases/download/v1.4/cpuminer_1.4_windows_x64_O2_GCC7.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\cpuminer.exe"

$Algorithms = @(
    @{ Algorithm = "ScryptN2"; MinerSet = 0; WarmupTimes = @(90, 30); ExcludePools = @(); Arguments = "" } # Empty command
)

# $Algorithms = $Algorithms.where({ $_.MinerSet -le $Session.Config.MinerSet })
$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

if ($Algorithms) { 

    $MinerAPIPort = $Session.MinerBaseAPIport + ($AvailableMinerDevices.Id | Sort-Object -Top 1)

    $Algorithms.ForEach(
        { 
            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"

            # $ExcludePools = $_.ExcludePools
            # foreach ($Pool in $MinerPools[0][$_.Algorithm].where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 
            foreach ($Pool in $MinerPools[0][$_.Algorithm].where({ $_.PoolPorts[0] })) { 

                [PSCustomObject]@{ 
                    API         = "CcMiner"
                    Arguments   = "$($_.Arguments) --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass) --threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $($Session.Config.CPUMiningReserveCPUcore)) --retry-pause 1 --api-bind $MinerAPIPort"
                    DeviceNames = $AvailableMinerDevices.Name
                    Fee         = @(0) # Dev fee
                    MinerSet    = $_.MinerSet
                    Name        = $MinerName
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = "CPU"
                    URI         = $URI
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                    Workers     = @(@{ Pool = $Pool })
                }
            }
        }
    )
}