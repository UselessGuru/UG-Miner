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
Version:        6.2.4
Version date:   2024/04/03
#>

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { Return }

$URI = "https://github.com/bitnet-io/cpuminer-opt-aurum/releases/download/aurum/cpuminer-opt-aurum-win64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\cpuminer-aes-sse42.exe" # Intel

If     ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx512", "sha", "vaes") -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = "$PWD\Bin\$Name\cpuminer-avx512-sha-vaes.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx512")                -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "$PWD\Bin\$Name\cpuminer-avx512.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx2", "sha", "vaes")   -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = "$PWD\Bin\$Name\cpuminer-avx2-sha-vaes.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx2", "sha")           -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = "$PWD\Bin\$Name\cpuminer-avx2-sha.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("aes", "sse42")          -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = "$PWD\Bin\$Name\cpuminer-aes-sse42.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx2")                  -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "$PWD\Bin\$Name\cpuminer-avx2.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx")                   -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "$PWD\Bin\$Name\cpuminer-avx.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("sse2")                  -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "$PWD\Bin\$Name\cpuminer-aes-sse2.exe" }
Else { Return }

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "Aurum"; MinerSet = 0; WarmupTimes = @(45, 15); ExcludePools = @(); Arguments = " -a aurum" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })

If ($Algorithms) { 

    $MinerAPIPort = $Config.APIPort + ($AvailableMiner_Devices.Id | Sort-Object -Top 1) + 1

    $Algorithms.ForEach(
        { 
            $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)-$($_.Algorithm)"

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.Name -notin $ExcludePools })[-1]) { 

                [PSCustomObject]@{ 
                    API              = "CcMiner"
                    Arguments        = "$($_.Arguments) --url $(If ($Pool.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --pass $($Pool.Pass) --hash-meter --stratum-keepalive --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)"
                    DeviceNames      = $AvailableMiner_Devices.Name
                    Fee              = @(0) # Dev fee
                    MinerSet         = $_.MinerSet
                    Name             = $Miner_Name
                    Path             = $Path
                    Port             = $MinerAPIPort
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                    Type             = "CPU"
                    URI              = $Uri
                    WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                    Workers          = @(@{ Pool = $Pool })
                }
            }
        }
    )
}