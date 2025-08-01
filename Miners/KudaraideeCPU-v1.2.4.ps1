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

# Flex and Xelisv2: Clang and Bionic compatibility by @sig11b in #13
# Add YespowerEQPAY
# Add Evohash
# Add EvohashV2

If (-not ($AvailableMinerDevices = $Session.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/Kudaraidee/cpuminer-opt-kudaraidee-1.2.4_windows.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

If     ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX512", "SHA", "VAES") -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = "Bin\$Name\cpuminer-avx512-sha-vaes.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX512")                -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "Bin\$Name\cpuminer-avx512.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX2", "SHA", "VAES")   -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = "Bin\$Name\cpuminer-avx2-sha-vaes.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX2", "SHA")           -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = "Bin\$Name\cpuminer-avx2-sha.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AES", "AVX")            -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = "Bin\$Name\cpuminer-aes-avx.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AES", "SSE42")          -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = "Bin\$Name\cpuminer-aes-sse42.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX2")                  -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "Bin\$Name\cpuminer-avx2.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX")                   -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "Bin\$Name\cpuminer-avx.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CPUfeatures @("SSE2")                  -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "Bin\$Name\cpuminer-aes-sse2.exe" }
Else { Return }

# Algorithm parameter values are case sensitive!
$Algorithms = @( 
    @{ Algorithm = "Argon2d1000";    MinerSet = 2; WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo argon2d1000" }
    @{ Algorithm = "Argon2d16000";   MinerSet = 1; WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo argon2d16000" }
    @{ Algorithm = "Argon2d250";     MinerSet = 2; WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo argon2d250" }
    @{ Algorithm = "Argon2d8192";    MinerSet = 2; WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo argon2d8192" }
    @{ Algorithm = "Argon2d500";     MinerSet = 2; WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo argon2d500" }
    @{ Algorithm = "Argon2d4096";    MinerSet = 2; WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo argon2d4096" }
    @{ Algorithm = "Evohash";        MinerSet = 1; WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo evohash" }
    @{ Algorithm = "EvohashV2";      MinerSet = 1; WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo evohashv2" }
    @{ Algorithm = "Flex";           MinerSet = 1; WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo flex" }
    @{ Algorithm = "RinHash";        MinerSet = 1; WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo rinhash" }
    @{ Algorithm = "XelisHashV2";    MinerSet = 1; WarmupTimes = @(60, 45); ExcludePools = @("NiceHash"); Arguments = " --algo xelisv2" }
    @{ Algorithm = "YespowerADVC";   MinerSet = 1; WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo yespoweradvc" }
    @{ Algorithm = "YespowerARWN";   MinerSet = 1; WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo yespowerarwn" }
    @{ Algorithm = "YespowerEQPAY";  MinerSet = 2; WarmupTimes = @(45, 60); ExcludePools = @("zergPool"); Arguments = " --algo yespowereqpay" } # https://github.com/RainbowMiner/RainbowMiner/issues/3076#issue-3230754391
    @{ Algorithm = "YespowerIc";     MinerSet = 2; WarmupTimes = @(45, 60); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "IsotopeC"' }
    @{ Algorithm = "YespowerIots";   MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-key "Iots is committed to the development of IOT"' }
    @{ Algorithm = "YespowerLitb";   MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LITBpower: The number of LITB working or available for proof-of-work mini"' }
    @{ Algorithm = "YespowerLtncg";  MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LTNCGYES"' }
    @{ Algorithm = "YespowerMGPC";   MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Magpies are birds of the Corvidae family."' } # MagpieCoin
    @{ Algorithm = "YespowerSugar";  MinerSet = 1; WarmupTimes = @(45, 45); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Satoshi Nakamoto 31/Oct/2008 Proof-of-work is essentially one-CPU-one-vote"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
    @{ Algorithm = "YespowerTIDE";   MinerSet = 1; WarmupTimes = @(45, 55); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 8' } # TDC tidecoin
    @{ Algorithm = "YespowerURX";    MinerSet = 0; WarmupTimes = @(45, 60); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "UraniumX"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    $MinerAPIPort = $Config.APIport + ($AvailableMinerDevices.Id | Sort-Object -Top 1) + 1

    $Algorithms.ForEach(
        { 
            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 

                [PSCustomObject]@{ 
                    API              = "CcMiner"
                    Arguments        = "$($_.Arguments) --url $(If ($Pool.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --pass $($Pool.Pass) --hash-meter --stratum-keepalive --quiet --threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $Config.CPUMiningReserveCPUcore) --api-bind $($MinerAPIPort)"
                    DeviceNames      = $AvailableMinerDevices.Name
                    Fee              = @(0) # Dev fee
                    MinerSet         = $_.MinerSet
                    Name             = $MinerName
                    Path             = $Path
                    Port             = $MinerAPIPort
                    Type             = "CPU"
                    URI              = $URI
                    WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                    Workers           = @(@{ Pool = $Pool })
                }
            }
        }
    )
}