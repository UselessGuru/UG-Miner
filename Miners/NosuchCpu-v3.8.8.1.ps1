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
Version:        6.2.7
Version date:   2024/04/18
#>

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { Return }

$URI = "https://github.com/patrykwnosuch/cpuminer-nosuch/releases/download/3.8.8.1-nosuch-m4/cpu-nosuch-m4-win64.7z"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
If ($AvailableMiner_Devices.CpuFeatures -match 'sha')      { $Path = "$PWD\Bin\$Name\cpuminer-avx2-sha.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match 'avx2') { $Path = "$PWD\Bin\$Name\cpuminer-avx2.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match 'aes')  { $Path = "$PWD\Bin\$Name\cpuminer-aes-sse2.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match 'sse2') { $Path = "$PWD\Bin\$Name\cpuminer-sse2.exe" }
Else { Return }

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "BinariumV1"; MinerSet = 2; WarmupTimes = @(30, 15); ExcludePools = @(); Arguments = " --algo binarium-v1" }
    [PSCustomObject]@{ Algorithm = "m7m";        MinerSet = 0; WarmupTimes = @(30, 15); ExcludePools = @(); Arguments = " --algo m7m" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    $MinerAPIPort = $Config.APIPort + ($AvailableMiner_Devices.Id | Sort-Object -Top 1) + 1
    $Algorithms.ForEach(
        { 
            $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)-$($_.Algorithm)"

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $_.Name -notin $ExcludePools })[-1]) { 

                [PSCustomObject]@{ 
                    API         = "CcMiner"
                    Arguments   = "$($_.Arguments) --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass) --cpu-affinity AAAA --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)"
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = @(0) # Dev fee
                    MinerSet    = $_.MinerSet
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = "CPU"
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                    Workers     = @(@{ Pool = $Pool })
                }
            }
        }
    )
}