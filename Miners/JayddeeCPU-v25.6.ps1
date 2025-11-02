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
Version:        6.6.1
Version date:   2025/11/02
#>

# Added argon2d1000, argon2d16000 algos.
# Target specific AES optimizations improve shavite for ARM64 & x86_64.

If (-not ($AvailableMinerDevices = $Session.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { Return }

$URI = "https://github.com/JayDDee/cpuminer-opt/releases/download/v25.6/cpuminer-opt-25.6-windows.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

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
    @{ Algorithm = "Allium";               MinerSet = 3; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo allium" }
    @{ Algorithm = "Anime";                MinerSet = 3; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo anime" }
    @{ Algorithm = "Argon2d1000";          MinerSet = 3; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo argon2d1000" }
    @{ Algorithm = "Argon2d1600";          MinerSet = 3; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo argon2d1600" }
    @{ Algorithm = "Argon2d250";           MinerSet = 3; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo argon2d250" }
    @{ Algorithm = "Argon2d500";           MinerSet = 3; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo argon2d500" }
    @{ Algorithm = "Argon2d5096";          MinerSet = 3; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo argon2d5096" }
#   @{ Algorithm = "Blake2b";              MinerSet = 3; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --algo blake2b" } # FPGA
#   @{ Algorithm = "Blake2s";              MinerSet = 3; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --algo blake2s" } # ASIC
    @{ Algorithm = "Bastiom";              MinerSet = 3; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --algo bastion" }
    @{ Algorithm = "BMW";                  MinerSet = 3; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --algo bmw" }
#   @{ Algorithm = "HMQ1725";              MinerSet = 3; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo hmq1725" } # GPU
    @{ Algorithm = "Jha";                  MinerSet = 3; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = " --algo jha" }
    @{ Algorithm = "Lyra2z330";            MinerSet = 3; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = " --algo lyra2z330" }
    @{ Algorithm = "Lyra2RE3";             MinerSet = 3; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = " --algo lyra2rev3" }
    @{ Algorithm = "m7m";                  MinerSet = 1; WarmupTimes = @(45, 80); ExcludePools = @(); Arguments = " --algo m7m" } # NosuchCpu-v3.8.8.1 is fastest
    @{ Algorithm = "Minotaur";             MinerSet = 1; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo minotaur" }
    @{ Algorithm = "Minotaurx";            MinerSet = 1; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo minotaurx" }
#   @{ Algorithm = "SHA3d";                MinerSet = 3; WarmupTimes = @(45, 20); ExcludePools = @(); Arguments = " --algo SHA3d" } # FPGA
#   @{ Algorithm = "ScryptN11";            MinerSet = 3; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo scrypt(N,1,1)" } # GPU
#   @{ Algorithm = "ScryptN2";             MinerSet = 1; WarmupTimes = @(90, 60); ExcludePools = @(); Arguments = " --algo scrypt --param-n 1048576" } # Drops back to commandline, tested @ zpool
    @{ Algorithm = "VertHash";             MinerSet = 0; WarmupTimes = @(45, 50); ExcludePools = @(); Arguments = " --algo verthash --data-file ..\.$($Session.VertHashDatPath)" }
    @{ Algorithm = "Yescrypt";             MinerSet = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo yescrypt" }
    @{ Algorithm = "YescryptR16";          MinerSet = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo yescryptr16" }
    @{ Algorithm = "YescryptR32";          MinerSet = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo yescryptr32" }
    @{ Algorithm = "YescryptR8";           MinerSet = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo yescryptr8" }
    @{ Algorithm = "Yespower2b";           MinerSet = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = ' --algo yespower-b2b --param-n 2048 --param-r 32 --param-key "Now I am become Death, the destroyer of worlds"' } # MicroBitcoin
    @{ Algorithm = "YespowerAdvc";         MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Let the quest begin"' } # AdventureCoin
    @{ Algorithm = "YespowerARWN";         MinerSet = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "ARWN"' } # Arrowana
    @{ Algorithm = "YespowerIc";           MinerSet = 2; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "IsotopeC"' }
    @{ Algorithm = "YespowerInterchained"; MinerSet = 2; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = ' --algo yespower --param-n 1024 --param-r 8' }
    @{ Algorithm = "YespowerIots";         MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-key "Iots is committed to the development of IOT"' }
    @{ Algorithm = "YespowerLitb";         MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LITBpower: The number of LITB working or available for proof-of-work mini"' }
    @{ Algorithm = "YespowerLtncg";        MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LTNCGYES"' }
    @{ Algorithm = "YespowerMGPC";         MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Magpies are birds of the Corvidae family."' } # MagpieCoin
    @{ Algorithm = "YespowerSugar";        MinerSet = 1; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Satoshi Nakamoto 31/Oct/2008 Proof-of-work is essentially one-CPU-one-vote"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
    @{ Algorithm = "YespowerTIDE";         MinerSet = 1; WarmupTimes = @(45, 55); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 8' } # TDC tidecoin
    @{ Algorithm = "YespowerUrx";          MinerSet = 0; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "UraniumX"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
    @{ Algorithm = "ZR5";                  MinerSet = 0; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo zr5" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Session.Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    $MinerAPIPort = $Session.MinerBaseAPIport + ($AvailableMinerDevices.Id | Sort-Object -Top 1)

    $Algorithms.ForEach(
        { 
            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"

            If ($_.Algorithm -eq "VertHash" -and (Get-Item -Path $Session.VertHashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                $PrerequisitePath = $Session.VertHashDatPath
                $PrerequisiteURI = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
            }
            Else { 
                $PrerequisitePath = ""
                $PrerequisiteURI = ""
            }

            # $ExcludePools = $_.ExcludePools
            # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 
            ForEach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                [PSCustomObject]@{ 
                    API              = "CcMiner"
                    Arguments        = "$($_.Arguments) --url $(If ($Pool.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --pass $($Pool.Pass) --hash-meter --stratum-keepalive --quiet --threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $Session.Config.CPUMiningReserveCPUcore) --api-bind $($MinerAPIPort)"
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
                    WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                    Workers           = @(@{ Pool = $Pool })
                }
            }
        }
    )
}