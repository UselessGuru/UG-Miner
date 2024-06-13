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
Version:        6.2.9
Version date:   2024/06/13
#>

If (-not ($AvailableMinerDevices = $Variables.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { Return }

$URI = "https://github.com/JayDDee/cpuminer-opt/releases/download/v24.3/cpuminer-opt-24.3-windows.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\cpuminer-aes-sse42.exe" # Intel

If     ((Compare-Object $AvailableMinerDevices.CpuFeatures @("avx512", "sha", "vaes") -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = "$PWD\Bin\$Name\cpuminer-avx512-sha-vaes.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CpuFeatures @("avx512")                -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "$PWD\Bin\$Name\cpuminer-avx512.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CpuFeatures @("avx2", "sha", "vaes")   -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = "$PWD\Bin\$Name\cpuminer-avx2-sha-vaes.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CpuFeatures @("avx2", "sha")           -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = "$PWD\Bin\$Name\cpuminer-avx2-sha.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CpuFeatures @("aes", "sse42")          -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = "$PWD\Bin\$Name\cpuminer-aes-sse42.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CpuFeatures @("avx2")                  -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "$PWD\Bin\$Name\cpuminer-avx2.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CpuFeatures @("avx")                   -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "$PWD\Bin\$Name\cpuminer-avx.exe" }
ElseIf ((Compare-Object $AvailableMinerDevices.CpuFeatures @("sse2")                  -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = "$PWD\Bin\$Name\cpuminer-aes-sse2.exe" }
Else { Return }

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "Allium";        MinerSet = 3; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo allium" }
    [PSCustomObject]@{ Algorithm = "Anime";         MinerSet = 3; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo anime" }
    [PSCustomObject]@{ Algorithm = "Argon2d250";    MinerSet = 3; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo argon2d250" }
    [PSCustomObject]@{ Algorithm = "Argon2d500";    MinerSet = 3; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo argon2d500" }
    [PSCustomObject]@{ Algorithm = "Argon2d5096";   MinerSet = 3; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo argon2d5096" }
    [PSCustomObject]@{ Algorithm = "Blake2b";       MinerSet = 3; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --algo blake2b" } # FPGA
    [PSCustomObject]@{ Algorithm = "Blake256R8";    MinerSet = 3; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --algo blake256r8" } # FPGA
    [PSCustomObject]@{ Algorithm = "Bastiom";       MinerSet = 3; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --algo bastion" }
    [PSCustomObject]@{ Algorithm = "BMW";           MinerSet = 3; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --algo bmw" }
    [PSCustomObject]@{ Algorithm = "HMQ1725";       MinerSet = 3; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo hmq1725" } # GPU
    [PSCustomObject]@{ Algorithm = "Jha";           MinerSet = 3; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = " --algo jha" }
    [PSCustomObject]@{ Algorithm = "Lyra2z330";     MinerSet = 3; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = " --algo lyra2z330" }
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";      MinerSet = 3; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = " --algo lyra2rev3" }
    [PSCustomObject]@{ Algorithm = "m7m";           MinerSet = 1; WarmupTimes = @(45, 80); ExcludePools = @(); Arguments = " --algo m7m" } # NosuchCpu-v3.8.8.1 is fastest
    [PSCustomObject]@{ Algorithm = "Minotaur";      MinerSet = 1; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo minotaur" }
    [PSCustomObject]@{ Algorithm = "Minotaurx";     MinerSet = 1; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo minotaurx" }
    [PSCustomObject]@{ Algorithm = "power2b";       MinerSet = 3; WarmupTimes = @(45, 20); ExcludePools = @(); Arguments = ' --algo power2b --param-n 2048 --param-r 32 --param-key "Now I am become Death, the destroyer of worlds"' } # FPGA
    [PSCustomObject]@{ Algorithm = "SHA3d";         MinerSet = 3; WarmupTimes = @(45, 20); ExcludePools = @(); Arguments = " --algo SHA3d" } # FPGA
    [PSCustomObject]@{ Algorithm = "ScryptN11";     MinerSet = 3; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo scrypt(N,1,1)" } # GPU
    [PSCustomObject]@{ Algorithm = "ScryptN2";      MinerSet = 1; WarmupTimes = @(90, 60); ExcludePools = @(); Arguments = " --algo scrypt --param-n 1048576" }
    [PSCustomObject]@{ Algorithm = "VertHash";      MinerSet = 0; WarmupTimes = @(45, 50); ExcludePools = @(); Arguments = " --algo verthash --data-file ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";      MinerSet = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo yescrypt" }
    [PSCustomObject]@{ Algorithm = "YescryptR16";   MinerSet = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo yescryptr16" }
    [PSCustomObject]@{ Algorithm = "YescryptR32";   MinerSet = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo yescryptr32" }
    [PSCustomObject]@{ Algorithm = "YescryptR8";    MinerSet = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo yescryptr8" }
    [PSCustomObject]@{ Algorithm = "YespowerARWN";  MinerSet = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "ARWN"' } # Arrowana
    [PSCustomObject]@{ Algorithm = "YespowerIc";    MinerSet = 2; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "IsotopeC"' }
    [PSCustomObject]@{ Algorithm = "YespowerIots";  MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-key "Iots is committed to the development of IOT"' }
    [PSCustomObject]@{ Algorithm = "YespowerLitb";  MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LITBpower: The number of LITB working or available for proof-of-work mini"' }
    [PSCustomObject]@{ Algorithm = "YespowerLtncg"; MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LTNCGYES"' }
    [PSCustomObject]@{ Algorithm = "YespowerMGPC";  MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Magpies are birds of the Corvidae family."' } # Magpiecoin
    [PSCustomObject]@{ Algorithm = "YespowerSugar"; MinerSet = 1; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Satoshi Nakamoto 31/Oct/2008 Proof-of-work is essentially one-CPU-one-vote"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "YespowerTIDE";  MinerSet = 1; WarmupTimes = @(45, 55); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 8' } # TDC tidecoin
    [PSCustomObject]@{ Algorithm = "YespowerUrx";   MinerSet = 0; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "UraniumX"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "ZR5";           MinerSet = 0; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = ' --algo zr5' }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
# $Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })

If ($Algorithms) { 

    $MinerAPIPort = $Config.APIPort + ($AvailableMinerDevices.Id | Sort-Object -Top 1) + 1

    $Algorithms.ForEach(
        { 
            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"
            
            If ($_.Algorithm -eq "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                $PrerequisitePath = $Variables.VerthashDatPath
                $PrerequisiteURI = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
            }
            Else { 
                $PrerequisitePath = ""
                $PrerequisiteURI = ""
            }

            # $ExcludePools = $_.ExcludePools
            # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.Name -notin $ExcludePools })) { 
            ForEach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                [PSCustomObject]@{ 
                    API              = "CcMiner"
                    Arguments        = "$($_.Arguments) --url $(If ($Pool.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --pass $($Pool.Pass) --hash-meter --stratum-keepalive --quiet --threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)"
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