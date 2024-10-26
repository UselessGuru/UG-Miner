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
Version:        6.3.11
Version date:   2024/10/26
#>

If (-not ($AvailableMinerDevices = $Variables.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { Return }

$URI = "https://github.com/bitnet-io/cpuminer-opt-aurum/releases/download/aurum/cpuminer-opt-aurum-win64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\cpuminer-aes-sse42.exe" # Intel

If     ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX512", "SHA", "VAES") -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = "Bin\$Name\cpuminer-avx512-sha-vaes.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX512")                -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "Bin\$Name\cpuminer-avx512.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX2", "SHA", "VAES")   -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = "Bin\$Name\cpuminer-avx2-sha-vaes.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX2", "SHA")           -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = "Bin\$Name\cpuminer-avx2-sha.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AES", "SSE42")          -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = "Bin\$Name\cpuminer-aes-sse42.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX2")                  -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "Bin\$Name\cpuminer-avx2.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX")                   -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "Bin\$Name\cpuminer-avx.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("SSE2")                  -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "Bin\$Name\cpuminer-aes-sse2.exe" }
Else { Return }

$Algorithms = @(
    @{ Algorithm = "Aurum"; MinerSet = 0; WarmupTimes = @(45, 15); ExcludePools = @(); Arguments = " -a aurum" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    $MinerAPIPort = $Config.APIPort + ($AvailableMinerDevices.Id | Sort-Object -Top 1) + 1

    $Algorithms.ForEach(
        { 
            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"

            # $ExcludePools = $_.ExcludePools
            # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 
            ForEach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                [PSCustomObject]@{ 
                    API              = "CcMiner"
                    Arguments        = "$($_.Arguments) --url $(If ($Pool.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --pass $($Pool.Pass) --hash-meter --stratum-keepalive --quiet --threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors -$($Config.CPUMiningReserveCPUcore)) --api-bind=$($MinerAPIPort)"
                    DeviceNames      = $AvailableMinerDevices.Name
                    Fee              = @(0) # Dev fee
                    MinerSet         = $_.MinerSet
                    Name             = $MinerName
                    Path             = $Path
                    Port             = $MinerAPIPort
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                    Type             = "CPU"
                    URI              = $URI
                    WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                    Workers          = @(@{ Pool = $Pool })
                }
            }
        }
    )
}