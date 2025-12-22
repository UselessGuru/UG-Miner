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
Version:        6.7.13
Version date:   2025/12/22
#>

# Flex and Xelisv2: Clang and Bionic compatibility by @sig11b in #13
# Add YespowerEQPAY
# Add Evohash
# Add EvohashV2

if (-not ($AvailableMinerDevices = $Session.EnabledDevices.where({ $_.Type -eq "CPU" }))) { return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/Kudaraidee/cpuminer-opt-kudaraidee-1.2.4_windows.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

if ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX512", "SHA", "VAES")   -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = "Bin\$Name\cpuminer-avx512-sha-vaes.exe" }
elseif ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX512")              -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "Bin\$Name\cpuminer-avx512.exe" }
elseif ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX2", "SHA", "VAES") -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = "Bin\$Name\cpuminer-avx2-sha-vaes.exe" }
elseif ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX2", "SHA")         -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = "Bin\$Name\cpuminer-avx2-sha.exe" }
elseif ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AES", "AVX")          -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = "Bin\$Name\cpuminer-aes-avx.exe" }
elseif ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AES", "SSE42")        -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = "Bin\$Name\cpuminer-aes-sse42.exe" }
elseif ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX2")                -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "Bin\$Name\cpuminer-avx2.exe" }
elseif ((Compare-Object $AvailableMinerDevices.CPUfeatures @("AVX")                 -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "Bin\$Name\cpuminer-avx.exe" }
elseif ((Compare-Object $AvailableMinerDevices.CPUfeatures @("SSE2")                -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "Bin\$Name\cpuminer-aes-sse2.exe" }
else { return }

# Algorithm parameter values are case sensitive!
$Algorithms = @( 
    @{ Algorithm = "Argon2d1000";    WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo argon2d1000" }
    @{ Algorithm = "Argon2d16000";   WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo argon2d16000" }
    @{ Algorithm = "Argon2d250";     WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo argon2d250" }
    @{ Algorithm = "Argon2d8192";    WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo argon2d8192" }
    @{ Algorithm = "Argon2d500";     WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo argon2d500" }
    @{ Algorithm = "Argon2d4096";    WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo argon2d4096" }
    @{ Algorithm = "Evohash";        WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo evohash" }
    @{ Algorithm = "EvohashV2";      WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo evohashv2" }
    @{ Algorithm = "Flex";           WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo flex" }
    @{ Algorithm = "Rinhash";        WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo Rinhash" }
    @{ Algorithm = "XelisHashV2";    WarmupTimes = @(60, 45); ExcludePools = @("NiceHash"); Arguments = " --algo xelisv2" }
    @{ Algorithm = "YespowerADVC";   WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo yespoweradvc" }
    @{ Algorithm = "YespowerARWN";   WarmupTimes = @(60, 45); ExcludePools = @();           Arguments = " --algo yespowerarwn" }
#   @{ Algorithm = "YespowerEQPAY";  WarmupTimes = @(45, 60); ExcludePools = @();           Arguments = " --algo yespowereqpay" } # https://github.com/Kudaraidee/cpuminer-opt-kudaraidee/issues/17
    @{ Algorithm = "YespowerIc";     WarmupTimes = @(45, 60); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "IsotopeC"' }
    @{ Algorithm = "YespowerIots";   WarmupTimes = @(45, 45); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-key "Iots is committed to the development of IOT"' }
    @{ Algorithm = "YespowerLitb";   WarmupTimes = @(45, 45); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LITBpower: The number of LITB working or available for proof-of-work mini"' }
    @{ Algorithm = "YespowerLtncg";  WarmupTimes = @(45, 45); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LTNCGYES"' }
    @{ Algorithm = "YespowerMGPC";   WarmupTimes = @(45, 45); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Magpies are birds of the Corvidae family."' } # MagpieCoin
    @{ Algorithm = "YespowerSugar";  WarmupTimes = @(45, 45); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Satoshi Nakamoto 31/Oct/2008 Proof-of-work is essentially one-CPU-one-vote"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
    @{ Algorithm = "YespowerTIDE";   WarmupTimes = @(45, 55); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 8' } # TDC tidecoin
    @{ Algorithm = "YespowerUrx";    WarmupTimes = @(45, 60); ExcludePools = @();           Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "UraniumX"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
)

$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

if ($Algorithms) { 

    $MinerAPIPort = $Session.MinerBaseAPIport + ($AvailableMinerDevices.Id | Sort-Object -Top 1)

    $Algorithms.ForEach(
        { 
            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"

            $ExcludePools = $_.ExcludePools
            foreach ($Pool in $MinerPools[0][$_.Algorithm].where({ $ExcludePools -notcontains $_.Name })) { 

                [PSCustomObject]@{ 
                    API         = "CcMiner"
                    Arguments   = "$($_.Arguments) --url $(if ($Pool.PoolPorts[1]) { "stratum+ssl" } else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --pass $($Pool.Pass) --hash-meter --stratum-keepalive --quiet --threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $Session.Config.CPUMiningReserveCPUcore) --api-bind $($MinerAPIPort)"
                    DeviceNames = $AvailableMinerDevices.Name
                    Fee         = @(0) # Dev fee
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