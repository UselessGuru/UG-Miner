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
Version:        6.6.7
Version date:   2025/11/21
#>

If (-not ($AvailableMinerDevices = $Session.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { Return }

$URI = "https://github.com/patrykwnosuch/cpuminer-nosuch/releases/download/3.8.8.1-nosuch-m4/cpu-nosuch-m4-win64.7z"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
If ($AvailableMinerDevices.CPUfeatures -match 'sha')      { $Path = "Bin\$Name\cpuminer-avx2-sha.exe" }
ElseIf ($AvailableMinerDevices.CPUfeatures -match 'avx2') { $Path = "Bin\$Name\cpuminer-avx2.exe" }
ElseIf ($AvailableMinerDevices.CPUfeatures -match 'aes')  { $Path = "Bin\$Name\cpuminer-aes-sse2.exe" }
ElseIf ($AvailableMinerDevices.CPUfeatures -match 'sse2') { $Path = "Bin\$Name\cpuminer-sse2.exe" }
Else { Return }

$Algorithms = @(
    @{ Algorithm = "BinariumV1"; MinerSet = 2; WarmupTimes = @(30, 15); ExcludePools = @(); Arguments = " --algo binarium-v1" }
    @{ Algorithm = "m7m";        MinerSet = 0; WarmupTimes = @(30, 15); ExcludePools = @(); Arguments = " --algo m7m" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Session.Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    $MinerAPIPort = $Session.MinerBaseAPIport + ($AvailableMinerDevices.Id | Sort-Object -Top 1)
    $Algorithms.ForEach(
        { 
            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"

            # $ExcludePools = $_.ExcludePools
            # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 
            ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] })) { 

                [PSCustomObject]@{ 
                    API         = "CcMiner"
                    Arguments   = "$($_.Arguments) --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass) --quiet --threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $Session.Config.CPUMiningReserveCPUcore) --api-bind $($MinerAPIPort)"
                    DeviceNames = $AvailableMinerDevices.Name
                    Fee         = @(0) # Dev fee
                    MinerSet    = $_.MinerSet
                    Name        = $MinerName
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = "CPU"
                    URI         = $URI
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                    Workers      = @(@{ Pool = $Pool })
                }
            }
        }
    )
}