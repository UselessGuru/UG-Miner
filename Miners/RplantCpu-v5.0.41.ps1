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
Version:        6.4.10
Version date:   2025/02/13
#>

If (-not ($AvailableMinerDevices = $Variables.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { Return }

$URI = "https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.41/cpuminer-opt-win-5.0.41.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

If ($AvailableMinerDevices.CPUfeatures -match "avx512")   { $Path = "Bin\$Name\cpuminer-Avx512.exe" }
ElseIf ($AvailableMinerDevices.CPUfeatures -match "avx2") { $Path = "Bin\$Name\cpuminer-Avx2.exe" }
ElseIf ($AvailableMinerDevices.CPUfeatures -match "avx")  { $Path = "Bin\$Name\cpuminer-Avx.exe" }
ElseIf ($AvailableMinerDevices.CPUfeatures -match "aes")  { $Path = "Bin\$Name\cpuminer-Aes-Sse42.exe" }
ElseIf ($AvailableMinerDevices.CPUfeatures -match "sse2") { $Path = "Bin\$Name\cpuminer-Sse2.exe" }
Else { Return }

$Algorithms = @(
    @{ Algorithm = "Avian";         MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo avian" }
    @{ Algorithm = "Allium";        MinerSet = 3; WarmupTimes = @(30, 0);   ExcludePools = @();           Arguments = " --algo allium" } # FPGA
    @{ Algorithm = "Anime";         MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo anime" }
#   @{ Algorithm = "Argon2ad";      MinerSet = 3; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo argon2ad" } # ASIC
    @{ Algorithm = "Argon2d250";    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo argon2d250" }
    @{ Algorithm = "Argon2d500";    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo argon2d500" }
    @{ Algorithm = "Argon2d4096";   MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo argon2d4096" }
    @{ Algorithm = "Axiom";         MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo axiom" }
    @{ Algorithm = "Balloon";       MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @("Zpool");    Arguments = " --algo balloon" }
    @{ Algorithm = "Blake2b";       MinerSet = 3; WarmupTimes = @(30, 30);  ExcludePools = @();           Arguments = " --algo blake2b" } # FPGA
    @{ Algorithm = "Bmw";           MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo bmw" }
#   @{ Algorithm = "Bmw512";        MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @();           Arguments = " --algo bmw512" } # ASIC
    @{ Algorithm = "C11";           MinerSet = 3; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo c11" } # GPU
    @{ Algorithm = "Circcash";      MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo circcash" }
#   @{ Algorithm = "CpuPower";      MinerSet = 3; WarmupTimes = @(60, 60);  ExcludePools = @();           Arguments = " --algo cpupower" } # ASIC
    @{ Algorithm = "CryptoVantaA";  MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @();           Arguments = " --algo cryptovantaa" }
#   @{ Algorithm = "CurveHash";     MinerSet = 2; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo curvehash" } # Not profitable with CPU
#   @{ Algorithm = "Decred";        MinerSet = 3; WarmupTimes = @(60, 60);  ExcludePools = @();           Arguments = " --algo Decred" } # ASIC, No hashrate in time, algo is now using Blake3d
#   @{ Algorithm = "DMDGr";         MinerSet = 3; WarmupTimes = @(60, 60);  ExcludePools = @();           Arguments = " --algo dmd-gr" } # ASIC
    @{ Algorithm = "DPowHash";      MinerSet = 3; WarmupTimes = @(60, 60);  ExcludePools = @();           Arguments = " --algo dpowhash" } # ASIC
    @{ Algorithm = "Ghostrider";    MinerSet = 0; WarmupTimes = @(180, 60); ExcludePools = @();           Arguments = " --algo gr" }
#   @{ Algorithm = "Groestl";       MinerSet = 3; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo groestl" } # ASIC
    @{ Algorithm = "HeavyHash";     MinerSet = 0; WarmupTimes = @(30, 5);   ExcludePools = @();           Arguments = " --algo heavyhash" } # FPGA
    @{ Algorithm = "Hex";           MinerSet = 3; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo hex" } # GPU
    @{ Algorithm = "HMQ1725";       MinerSet = 3; WarmupTimes = @(30, 0);   ExcludePools = @();           Arguments = " --algo hmq1725" } # GPU
    @{ Algorithm = "Hodl";          MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo hodl" }
    @{ Algorithm = "Jha";           MinerSet = 3; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo jha" } # GPU
#   @{ Algorithm = "Keccak";        MinerSet = 3; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo keccak" } # ASIC
#   @{ Algorithm = "KeccakC";       MinerSet = 3; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo keccakc" } # ASIC
#   @{ Algorithm = "Lbry";          MinerSet = 3; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo lbry" } # ASIC
    @{ Algorithm = "Lyra2h";        MinerSet = 2; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo lyra2h" }
    @{ Algorithm = "Lyra2a40";      MinerSet = 0; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo lyra2a40" }
#   @{ Algorithm = "Lyra2RE";       MinerSet = 3; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo lyra2re" } # ASIC
#   @{ Algorithm = "Lyra2RE2";      MinerSet = 3; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo lyra2rev2" } # ASIC
#   @{ Algorithm = "Lyra2RE3";      MinerSet = 3; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo lyra2rev3" } # ASIC
#   @{ Algorithm = "Lyra2Z";        MinerSet = 0; WarmupTimes = @(90, 0);   ExcludePools = @();           Arguments = " --algo lyra2z" } # ASIC
#   @{ Algorithm = "Lyra2z330";     MinerSet = 3; WarmupTimes = @(90, 25);  ExcludePools = @();           Arguments = " --algo lyra2z330" } # Algorithm is dead
    @{ Algorithm = "MemeHash";      MinerSet = 0; WarmupTimes = @(90, 35);  ExcludePools = @();           Arguments = " --algo memehashv2" }
    @{ Algorithm = "Mike";          MinerSet = 3; WarmupTimes = @(90, 20);  ExcludePools = @();           Arguments = " --algo mike" } # GPU
    @{ Algorithm = "Minotaur";      MinerSet = 2; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo minotaur" }
    @{ Algorithm = "MinotaurX";     MinerSet = 0; WarmupTimes = @(90, 0);   ExcludePools = @();           Arguments = " --algo minotaurx" }
#   @{ Algorithm = "MyriadGroestl"; MinerSet = 3; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo myr-gr" } # ASIC
    @{ Algorithm = "Neoscrypt";     MinerSet = 3; WarmupTimes = @(90, 25);  ExcludePools = @("NiceHash"); Arguments = " --algo neoscrypt" } # FPGA
#   @{ Algorithm = "Nist5";         MinerSet = 3; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo nist5" } # ASIC
    @{ Algorithm = "Pentablake";    MinerSet = 3; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo pentablake" } # GPU
    @{ Algorithm = "Phi2";          MinerSet = 3; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo phi2" } # GPU
    @{ Algorithm = "Phi5";          MinerSet = 3; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo phi5" } # GPU
    @{ Algorithm = "Phi1612";       MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo phi1612" }
    @{ Algorithm = "Phichox";       MinerSet = 3; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo phichox" } # GPU
    @{ Algorithm = "Polytimos";     MinerSet = 3; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo polytimos" } # GPU
    @{ Algorithm = "Pulsar";        MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo pulsar" }
    @{ Algorithm = "QogeCoin";      MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo qogecoin" }
#   @{ Algorithm = "Quark";         MinerSet = 3; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo quark" } # ASIC
#   @{ Algorithm = "Qubit";         MinerSet = 3; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo qubit" } # ASIC
    @{ Algorithm = "Qureno";        MinerSet = 3; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo qureno" } # GPU
#   @{ Algorithm = "X11";           MinerSet = 3; WarmupTimes = @(30, 15);  ExcludePools = @();           Srguments = " --algo x11" } # ASIC, algorithm not supported
    @{ Algorithm = "X22";           MinerSet = 2; WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo x22" }
    @{ Algorithm = "Yescrypt";      MinerSet = 0; WarmupTimes = @(45, 5);   ExcludePools = @();           Arguments = " --algo yescrypt" }
    @{ Algorithm = "YescryptR16";   MinerSet = 0; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yescryptr16" } # CcminerLyraYesscrypt-v8.21r18v5 is faster
    @{ Algorithm = "YescryptR8";    MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yescryptr8" } # CcminerLyraYesscrypt-v8.21r18v5 is faster
    @{ Algorithm = "YescryptR8g";   MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yescryptr8g" }
    @{ Algorithm = "YescryptR32";   MinerSet = 0; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yescryptr32" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    @{ Algorithm = "Yespower";      MinerSet = 0; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespower" }
    @{ Algorithm = "Yespower2b";    MinerSet = 0; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo power2b" }
    @{ Algorithm = "YespowerARWN";  MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerarwn" }
    @{ Algorithm = "YespowerIc";    MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerIC" }
    @{ Algorithm = "YespowerIots";  MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerIOTS" }
    @{ Algorithm = "YespowerItc";   MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerITC" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    @{ Algorithm = "YespowerLitb";  MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerLITB" }
    @{ Algorithm = "YespowerLtncg"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerLTNCG" }
    @{ Algorithm = "YespowerR16";   MinerSet = 2; WarmupTimes = @(60, 0);   ExcludePools = @();           Arguments = " --algo yespowerr16" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    @{ Algorithm = "YespowerRes";   MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerRes" }
    @{ Algorithm = "YespowerSugar"; MinerSet = 1; WarmupTimes = @(45, 15);  ExcludePools = @();           Arguments = " --algo yespowerSugar" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    @{ Algorithm = "YespowerTIDE";  MinerSet = 0; WarmupTimes = @(45, 5);   ExcludePools = @();           Arguments = " --algo yespowerTIDE" }
    @{ Algorithm = "YespowerUrx";   MinerSet = 2; WarmupTimes = @(45, 5);   ExcludePools = @();           Arguments = " --algo yespowerURX" } # JayddeeCpu-v25.3 is faster, SRBMminerMulti is fastest, but has 0.85% miner fee
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    $MinerAPIPort = $Config.APIPort + ($AvailableMinerDevices.Id | Sort-Object -Top 1) + 1

    $Algorithms.ForEach(
        { 
            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 

                [PSCustomObject]@{ 
                    API         = "CcMiner"
                    Arguments   = "$($_.Arguments) --url $(If ($Pool.PoolPorts[1]) { "stratum+tcps" } Else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --pass $($Pool.Pass)$(If ($Pool.WorkerName) { " --rig-id $($Pool.WorkerName)" }) --cpu-affinity AAAA --quiet --threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors -$($Config.CPUMiningReserveCPUcore)) --api-bind=$($MinerAPIPort)"
                    DeviceNames = $AvailableMinerDevices.Name
                    Fee         = @(0) # Dev fee
                    MinerSet    = $_.MinerSet
                    Name        = $MinerName
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = "CPU"
                    URI         = $URI
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                    Workers     = @(@{ Pool = $Pool })
                }
            }
        }
    )
}