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
Version:        6.7.17
Version date:   2026/01/04
#>

if (-not ($AvailableMinerDevices = $Session.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/RplantCpu/cpuminer-opt-win-5.0.42c.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName

if ($AvailableMinerDevices.CPUfeatures -match "avx512")   { $Path = "Bin\$Name\cpuminer-Avx512.exe" }
elseif ($AvailableMinerDevices.CPUfeatures -match "avx2") { $Path = "Bin\$Name\cpuminer-Avx2.exe" }
elseif ($AvailableMinerDevices.CPUfeatures -match "avx")  { $Path = "Bin\$Name\cpuminer-Avx.exe" }
elseif ($AvailableMinerDevices.CPUfeatures -match "aes")  { $Path = "Bin\$Name\cpuminer-Aes-Sse42.exe" }
elseif ($AvailableMinerDevices.CPUfeatures -match "sse2") { $Path = "Bin\$Name\cpuminer-Sse2.exe" }
else                                                      { return }

$Algorithms = @(
    @{ Algorithm = "Avian";         WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo avian" }
    @{ Algorithm = "Allium";        WarmupTimes = @(30, 0);   ExcludePools = @();           Arguments = " --algo allium" } # FPGA
    @{ Algorithm = "Anime";         WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo anime" }
#   @{ Algorithm = "Argon2ad";      WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo argon2ad" } # ASIC
    @{ Algorithm = "Argon2d250";    WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo argon2d250" }
    @{ Algorithm = "Argon2d500";    WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo argon2d500" }
    @{ Algorithm = "Argon2d4096";   WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo argon2d4096" }
    @{ Algorithm = "Axiom";         WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo axiom" }
    @{ Algorithm = "Balloon";       WarmupTimes = @(30, 15);  ExcludePools = @("Zpool");    Arguments = " --algo balloon" }
    @{ Algorithm = "Blake2b";       WarmupTimes = @(30, 30);  ExcludePools = @();           Arguments = " --algo blake2b" } # FPGA
    @{ Algorithm = "Bmw";           WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo bmw" }
#   @{ Algorithm = "Bmw512";        WarmupTimes = @(30, 0);   ExcludePools = @();           Arguments = " --algo bmw512" } # ASIC
    @{ Algorithm = "C11";           WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo c11" } # GPU
    @{ Algorithm = "Circcash";      WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo circcash" }
#   @{ Algorithm = "CpuPower";      WarmupTimes = @(60, 60);  ExcludePools = @();           Arguments = " --algo cpupower" } # ASIC
    @{ Algorithm = "CryptoVantaA";  WarmupTimes = @(60, 60);  ExcludePools = @();           Arguments = " --algo cryptovantaa" }
#   @{ Algorithm = "CurveHash";     WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo curvehash" } # Not profitable with CPU
#   @{ Algorithm = "Decred";        WarmupTimes = @(60, 60);  ExcludePools = @();           Arguments = " --algo Decred" } # ASIC, No hashrate in time, algo is now using Blake3d
#   @{ Algorithm = "DMDGr";         WarmupTimes = @(60, 60);  ExcludePools = @();           Arguments = " --algo dmd-gr" } # ASIC
    @{ Algorithm = "DPowHash";      WarmupTimes = @(60, 60);  ExcludePools = @();           Arguments = " --algo dpowhash" } # ASIC
    @{ Algorithm = "Ghostrider";    WarmupTimes = @(180, 60); ExcludePools = @();           Arguments = " --algo gr" }
#   @{ Algorithm = "Groestl";       WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo groestl" } # ASIC
    @{ Algorithm = "HeavyHash";     WarmupTimes = @(30, 5);   ExcludePools = @();           Arguments = " --algo heavyhash" } # FPGA
    @{ Algorithm = "Hex";           WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo hex" } # GPU
    @{ Algorithm = "HMQ1725";       WarmupTimes = @(30, 0);   ExcludePools = @();           Arguments = " --algo hmq1725" } # GPU
    @{ Algorithm = "Hodl";          WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo hodl" }
    @{ Algorithm = "Jha";           WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo jha" } # GPU
#   @{ Algorithm = "Keccak";        WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo keccak" } # ASIC
#   @{ Algorithm = "KeccakC";       WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo keccakc" } # ASIC
#   @{ Algorithm = "Lbry";          WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo lbry" } # ASIC
    @{ Algorithm = "Lyra2h";        WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo lyra2h" }
    @{ Algorithm = "Lyra2a40";      WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo lyra2a40" }
#   @{ Algorithm = "Lyra2RE";       WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo lyra2re" } # ASIC
#   @{ Algorithm = "Lyra2RE2";      WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo lyra2rev2" } # ASIC
#   @{ Algorithm = "Lyra2RE3";      WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo lyra2rev3" } # ASIC
#   @{ Algorithm = "Lyra2Z";        WarmupTimes = @(90, 0);   ExcludePools = @();           Arguments = " --algo lyra2z" } # ASIC
#   @{ Algorithm = "Lyra2z330";     WarmupTimes = @(90, 25);  ExcludePools = @();           Arguments = " --algo lyra2z330" } # Algorithm is dead
    @{ Algorithm = "MemeHash";      WarmupTimes = @(90, 35);  ExcludePools = @();           Arguments = " --algo memehashv2" }
    @{ Algorithm = "Mike";          WarmupTimes = @(90, 20);  ExcludePools = @();           Arguments = " --algo mike" } # GPU
    @{ Algorithm = "Minotaur";      WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo minotaur" }
    @{ Algorithm = "MinotaurX";     WarmupTimes = @(90, 0);   ExcludePools = @("ZPool");    Arguments = " --algo minotaurx" } # https://discord.com/channels/376790817811202050/1371515289824530434
#   @{ Algorithm = "MyriadGroestl"; WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo myr-gr" } # ASIC
    @{ Algorithm = "Neoscrypt";     WarmupTimes = @(90, 25);  ExcludePools = @("NiceHash"); Arguments = " --algo neoscrypt" } # FPGA
#   @{ Algorithm = "Nist5";         WarmupTimes = @(90, 15);  ExcludePools = @();           Arguments = " --algo nist5" } # ASIC
    @{ Algorithm = "Pentablake";    WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo pentablake" } # GPU
    @{ Algorithm = "Phi2";          WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo phi2" } # GPU
    @{ Algorithm = "Phi5";          WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo phi5" } # GPU
    @{ Algorithm = "Phi1612";       WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo phi1612" }
    @{ Algorithm = "Phichox";       WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo phichox" } # GPU
    @{ Algorithm = "Polytimos";     WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo polytimos" } # GPU
    @{ Algorithm = "Pulsar";        WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo pulsar" }
    @{ Algorithm = "QogeCoin";      WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo qogecoin" }
#   @{ Algorithm = "Quark";         WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo quark" } # ASIC
#   @{ Algorithm = "Qubit";         WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo qubit" } # ASIC
#   @{ Algorithm = "Qureno";        WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo qureno" } # GPU
#   @{ Algorithm = "Rinhash";       WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo Rinhash" } # Miner just closes
#   @{ Algorithm = "X11";           WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo x11" } # ASIC, algorithm not supported
    @{ Algorithm = "X22";           WarmupTimes = @(30, 15);  ExcludePools = @();           Arguments = " --algo x22" }
    @{ Algorithm = "Yescrypt";      WarmupTimes = @(45, 5);   ExcludePools = @();           Arguments = " --algo yescrypt" }
    @{ Algorithm = "YescryptR16";   WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yescryptr16" } # CcminerLyra-v8.21r18v5 is faster
    @{ Algorithm = "YescryptR8";    WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yescryptr8" } # CcminerLyra-v8.21r18v5 is faster
    @{ Algorithm = "YescryptR8g";   WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yescryptr8g" }
    @{ Algorithm = "YescryptR32";   WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yescryptr32" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    @{ Algorithm = "Yespower";      WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespower" }
    @{ Algorithm = "Yespower2b";    WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo power2b" }
    @{ Algorithm = "YespowerARWN";  WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerarwn" }
    @{ Algorithm = "YespowerIc";    WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerIC" }
    @{ Algorithm = "YespowerIots";  WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerIOTS" }
    @{ Algorithm = "YespowerItc";   WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerITC" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    @{ Algorithm = "YespowerLitb";  WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerLITB" }
    @{ Algorithm = "YespowerLtncg"; WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerLTNCG" }
    @{ Algorithm = "YespowerR16";   WarmupTimes = @(60, 0);   ExcludePools = @();           Arguments = " --algo yespowerr16" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    @{ Algorithm = "YespowerRes";   WarmupTimes = @(45, 0);   ExcludePools = @();           Arguments = " --algo yespowerRes" }
    @{ Algorithm = "YespowerSugar"; WarmupTimes = @(45, 15);  ExcludePools = @();           Arguments = " --algo yespowerSugar" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    @{ Algorithm = "YespowerTIDE";  WarmupTimes = @(45, 5);   ExcludePools = @("ZPool");    Arguments = " --algo yespowerTIDE" } # https://discord.com/channels/376790817811202050/1371515289824530434
    @{ Algorithm = "YespowerUrx";   WarmupTimes = @(45, 5);   ExcludePools = @();           Arguments = " --algo YespowerUrx" } # JayddeeCPU-v25.7 is faster, SRBMminerMulti is fastest, but has 0.85% miner fee
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

if ($Algorithms) { 

    $MinerAPIPort = $Session.MinerBaseAPIport + ($AvailableMinerDevices.Id | Sort-Object -Top 1)

    $Algorithms.ForEach(
        { 
            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($_.Algorithm)"

            $ExcludePools = $_.ExcludePools
            foreach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 

                [PSCustomObject]@{ 
                    API         = "CcMiner"
                    Arguments   = "$($_.Arguments) --url $(if ($Pool.PoolPorts[1]) { "stratum+tcps" } else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --pass $($Pool.Pass)$(if ($Pool.WorkerName) { " --rig-id $($Pool.WorkerName)" }) --hash-meter --threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $Session.Config.CPUMiningReserveCPUcore) --api-bind $($MinerAPIPort)"
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