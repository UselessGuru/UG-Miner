<#
Copyright (c) 2018-2026 UselessGuru

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
Version:        6.9.2
Version date:   2026/10/30
#>

# minor pearlhash improvements to NVIDIA RTX 3000, 4000 and 5000 series gpu's
# improved pearlhash for NVIDIA A100/CMP170HX
# improved pearlhash for AMD RDNA2 and RDNA3

if (-not ($Devices = $Session.EnabledDevices.Where{ ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -match "OpenCL C [1.2|2\.\d+]" -and $_.Architecture -notmatch "^GCN1$") -or $_.Type -eq "INTEL" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge [System.Version]"452.39.00" -and $_.Model -notmatch "^MX\d.+") })) { return }

$URL = "https://github.com/andru-kun/wildrig-multi/releases/download/0.51.8/wildrig-multi-windows-0.51.8.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\wildrig.exe"
$DeviceEnumerator = "Bus_Type_Index"

$Algorithms = @(
    @{ Algorithm = "Anime";            Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo anime" }
#   @{ Algorithm = "Blake2s";          Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo blake2s" } # ASIC
#   @{ Algorithm = "Bmw512";           Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo bmw512" } # ASIC
    @{ Algorithm = "C11";              Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo c11" }
    @{ Algorithm = "CurveHash";        Type = "AMD"; Fee = @(0.01);   MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo curvehash" }
    @{ Algorithm = "EvoHash";          Type = "AMD"; Fee = @(0);      MinMemGiBfree = 1;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo evohash" }
    @{ Algorithm = "EvrProgPow";       Type = "AMD"; Fee = @(0.0075); MinMemGiBfree = 0.62; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo evrprogpow" }
    @{ Algorithm = "FiroPow";          Type = "AMD"; Fee = @(0.0075); MinMemGiBfree = 1.24; WarmupTimes = @(45, 45);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo firopow" }
    @{ Algorithm = "Ghostrider";       Type = "AMD"; Fee = @(0.01);   MinMemGiBfree = 2;    WarmupTimes = @(180, 60); ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo ghostrider" }
    @{ Algorithm = "Hex";              Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo hex" }
    @{ Algorithm = "HMQ1725";          Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo hmq1725" } # CryptoDredge-v0.27.0 is fastest
    @{ Algorithm = "KawPow";           Type = "AMD"; Fee = @(0.0075); MinMemGiBfree = 0.62; WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " ";       ExcludePools = @("NiceHash"); Arguments = " --algo kawpow" } # TeamRedMiner-v0.10.21 is fastest on Navi
#   @{ Algorithm = "Lyra2RE2";         Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo lyra2v2" } # ASIC
    @{ Algorithm = "MegaBtx";          Type = "AMD"; Fee = @(0);      MinMemGiBfree = 1;    WarmupTimes = @(90, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo megabtx" }
    @{ Algorithm = "MemeHash";         Type = "AMD"; Fee = @(0);      MinMemGiBfree = 1;    WarmupTimes = @(45, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo memehash" }
    @{ Algorithm = "MeowPow";          Type = "AMD"; Fee = @(0.0075); MinMemGiBfree = 1.24; WarmupTimes = @(75, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo meowpow" }
    @{ Algorithm = "Mike";             Type = "AMD"; Fee = @(0.01);   MinMemGiBfree = 1;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo mike" } # https://github.com/andru-kun/wildrig-multi/issues/329
    @{ Algorithm = "NexaPow";          Type = "AMD"; Fee = @(0.0075); MinMemGiBfree = 3;    WarmupTimes = @(45, 15);  ExcludeGPUarchitectures = "^GCN\d$"; ExcludePools = @("NiceHash"); Arguments = " --algo nexapow" } # https://github.com/andru-kun/wildrig-multi/issues/277
#   @{ Algorithm = "Nist5";            Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo nist5" } # ASIC
#   @{ Algorithm = "PearlHash";        Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(45, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo pearlhash" } # https://github.com/andru-kun/wildrig-multi/issues/383, only supports pool pearlhash.xyz
#   @{ Algorithm = "Phi";              Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo phi" } # ASIC
    @{ Algorithm = "ProgPowSero";      Type = "AMD"; Fee = @(0.0075); MinMemGiBfree = 0.62; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo progpow-sero" }
    @{ Algorithm = "ProgPowTelestai";  Type = "AMD"; Fee = @(0.0075); MinMemGiBfree = 0.62; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo progpow-telestai" }
    @{ Algorithm = "ProgPowZ";         Type = "AMD"; Fee = @(0.0075); MinMemGiBfree = 0.62; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo progpowz" }
#   @{ Algorithm = "Pufferfish2BMB";   Type = "AMD"; Fee = @(0);      MinMemGiBfree = 8;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo pufferfish2" } # waiting for coin to resurrect
    @{ Algorithm = "QHash";            Type = "AMD"; Fee = @(0.02);   MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo qhash" }
#   @{ Algorithm = "Quark";            Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo quark" } # ASIC
#   @{ Algorithm = "Quibit";           Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo qui" } # ASIC
#   @{ Algorithm = "SHA256";           Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo sha256" } # ASIC
#   @{ Algorithm = "SHA256d";          Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo sha256d" } # ASIC
    @{ Algorithm = "SHA256csm";        Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo sha256csm" }
    @{ Algorithm = "SHA256t";          Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo sha256t" } # Takes too long until it starts mining
    @{ Algorithm = "SHA256q";          Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo sha256q" }
    @{ Algorithm = "SHA512256d";       Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo sha512256d" }
    @{ Algorithm = "Skein2";           Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo skein2" }
#   @{ Algorithm = "SkunkHash";        Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo skunkhash" } # Algorithm is dead
    @{ Algorithm = "SkydogeHash";      Type = "AMD"; Fee = @(0.02);   MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo skydoge" }
    @{ Algorithm = "Timetravel";       Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo timetravel" }
    @{ Algorithm = "Timetravel10";     Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo timetravel10" }
    @{ Algorithm = "Tribus";           Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo tribus" }
#   @{ Algorithm = "X11";              Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x11" } # ASIC
#   @{ Algorithm = "X11ghost";         Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x11ghost" } # ASIC
    @{ Algorithm = "X11k";             Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x11k" }
#   @{ Algorithm = "X12";              Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x12" } # ASIC
#   @{ Algorithm = "X13";              Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x13" } # ASIC
#   @{ Algorithm = "X14";              Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x14" } # ASIC
#   @{ Algorithm = "X15";              Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x15" } # ASIC
#   @{ Algorithm = "X16r";             Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 60);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x16r" } # ASIC
    @{ Algorithm = "X16rt";            Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(45, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x16rt" } # FPGA
    @{ Algorithm = "X16rv2";           Type = "AMD"; Fee = @(0);      MinMemGiBfree = 3;    WarmupTimes = @(150, 15); ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x16rv2" }
    @{ Algorithm = "X16s";             Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x16s" } # FPGA
    @{ Algorithm = "X17";              Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x17" }
    @{ Algorithm = "X18";              Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x18" }
    @{ Algorithm = "X21s";             Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(120, 45); ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x21s" }
    @{ Algorithm = "X22";              Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x22" }
    @{ Algorithm = "X22i";             Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x22i" }
    @{ Algorithm = "X25x";             Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x25x" }
    @{ Algorithm = "X33";              Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x33" }
    @{ Algorithm = "X7";               Type = "AMD"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo x7" } # ASIC

    @{ Algorithm = "Anime";            Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo anime" }
#   @{ Algorithm = "Blake2s";          Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo blake2s" } # ASIC
#   @{ Algorithm = "Bmw512";           Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo bmw512" } # ASIC
    @{ Algorithm = "C11";              Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo c11" }
    @{ Algorithm = "CurveHash";        Type = "INTEL"; Fee = @(0.01);   MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo curvehash" }
    @{ Algorithm = "EvoHash";          Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 1;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo evohash" }
    @{ Algorithm = "EvrProgPow";       Type = "INTEL"; Fee = @(0.0075); MinMemGiBfree = 0.62; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo evrprogpow" }
    @{ Algorithm = "FiroPow";          Type = "INTEL"; Fee = @(0.0075); MinMemGiBfree = 1.24; WarmupTimes = @(45, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo firopow" }
    @{ Algorithm = "Ghostrider";       Type = "INTEL"; Fee = @(0.01);   MinMemGiBfree = 2;    WarmupTimes = @(180, 60); ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo ghostrider" }
    @{ Algorithm = "Hex";              Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo hex" }
    @{ Algorithm = "HMQ1725";          Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo hmq1725" } # CryptoDredge-v0.27.0 is fastest
    @{ Algorithm = "KawPow";           Type = "INTEL"; Fee = @(0.0075); MinMemGiBfree = 0.90; WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " "; ExcludePools = @("NiceHash"); Arguments = " --algo kawpow" }
#   @{ Algorithm = "Lyra2RE2";         Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo lyra2v2" } # ASIC
    @{ Algorithm = "MegaBtx";          Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 1;    WarmupTimes = @(90, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo megabtx" }
    @{ Algorithm = "MemeHash";         Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 1;    WarmupTimes = @(45, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo memehash" }
    @{ Algorithm = "MeowPow";          Type = "INTEL"; Fee = @(0.0075); MinMemGiBfree = 1.24; WarmupTimes = @(75, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo meowpow" }
    @{ Algorithm = "Mike";             Type = "INTEL"; Fee = @(0.01);   MinMemGiBfree = 1;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo mike" }
    @{ Algorithm = "NexaPow";          Type = "INTEL"; Fee = @(0.0075); MinMemGiBfree = 3;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @("NiceHash"); Arguments = " --algo nexapow" } # https://github.com/andru-kun/wildrig-multi/issues/277
#   @{ Algorithm = "Nist5";            Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo nist5" }
#   @{ Algorithm = "Phi";              Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo phi" } # ASIC
    @{ Algorithm = "ProgPowSero";      Type = "INTEL"; Fee = @(0.0075); MinMemGiBfree = 0.62; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo progpow-sero" }
    @{ Algorithm = "ProgPowTelestai";  Type = "INTEL"; Fee = @(0.0075); MinMemGiBfree = 0.62; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo progpow-telestai" }
    @{ Algorithm = "ProgPowZ";         Type = "INTEL"; Fee = @(0.0075); MinMemGiBfree = 0.62; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo progpowz" }
#   @{ Algorithm = "Pufferfish2BMB";   Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 8;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo pufferfish2" } # waiting for coin to resurrect
    @{ Algorithm = "QHash";            Type = "INTEL"; Fee = @(0.02);   MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo qhash" }
#   @{ Algorithm = "Quark";            Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo quark" } # ASIC
#   @{ Algorithm = "Quibit";           Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo qui" } # ASIC
#   @{ Algorithm = "SHA256";           Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo sha256" } # ASIC
#   @{ Algorithm = "SHA256d";          Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo sha256d" } # ASIC
    @{ Algorithm = "SHA256csm";        Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo sha256csm" }
    @{ Algorithm = "SHA256t";          Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo sha256t" }
    @{ Algorithm = "SHA256q";          Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo sha256q" }
    @{ Algorithm = "SHA512256d";       Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo sha512256d" }
    @{ Algorithm = "Skein2";           Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(90, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo skein2" } # CcminerAlexis78-v1.5.2 is fastest
    @{ Algorithm = "SkunkHash";        Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(90, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo skunkhash" } # Algorithm is dead
    @{ Algorithm = "SkydogeHash";      Type = "INTEL"; Fee = @(0.02);   MinMemGiBfree = 2;    WarmupTimes = @(45, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo skydoge" }
    @{ Algorithm = "Timetravel";       Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo timetravel" }
    @{ Algorithm = "Timetravel10";     Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo timetravel10" }
#   @{ Algorithm = "Tribus";           Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo tribus" } # ASIC
#   @{ Algorithm = "X11";              Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x11" } # ASIC
#   @{ Algorithm = "X11ghost";         Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x11ghost" } # ASIC
    @{ Algorithm = "X11k";             Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x11k" }
#   @{ Algorithm = "X12";              Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x12" } # ASIC
#   @{ Algorithm = "X13";              Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x13" } # ASIC
#   @{ Algorithm = "X14";              Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x14" } # ASIC
#   @{ Algorithm = "X15";              Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x15" } # ASIC
#   @{ Algorithm = "X16r";             Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x16r" } # ASIC
    @{ Algorithm = "X16rt";            Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x16rt" } # FPGA
    @{ Algorithm = "X16rv2";           Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 3;    WarmupTimes = @(150, 15); ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x16rv2" }
    @{ Algorithm = "X16s";             Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x16s" } # FPGA
    @{ Algorithm = "X17";              Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x17" }
    @{ Algorithm = "X18";              Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x18" }
    @{ Algorithm = "X21s";             Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(120, 45); ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x21s" }
    @{ Algorithm = "X22";              Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x22" }
    @{ Algorithm = "X22i";             Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x22i" }
    @{ Algorithm = "X25x";             Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x25x" }
    @{ Algorithm = "X33";              Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x33" }
    @{ Algorithm = "X7";               Type = "INTEL"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo x7" } # ASIC

    @{ Algorithm = "Anime";            Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo anime" }
#   @{ Algorithm = "Blake2s";          Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo blake2s" } # ASIC
#   @{ Algorithm = "Bmw512";           Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo bmw512" } # ASIC
    @{ Algorithm = "C11";              Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo c11" }
    @{ Algorithm = "CurveHash";        Type = "NVIDIA"; Fee = @(0.01);   MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo curvehash" }
    @{ Algorithm = "EvoHash";          Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 1;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = "^Blackwell$";      ExcludePools = @();           Arguments = " --algo evohash" } # Bad shares on Blackwell
    @{ Algorithm = "EvrProgPow";       Type = "NVIDIA"; Fee = @(0.0075); MinMemGiBfree = 0.62; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo evrprogpow" }
    @{ Algorithm = "FiroPow";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGiBfree = 1.24; WarmupTimes = @(45, 30);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo firopow" }
    @{ Algorithm = "Ghostrider";       Type = "NVIDIA"; Fee = @(0.01);   MinMemGiBfree = 2;    WarmupTimes = @(180, 60); ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo ghostrider" }
    @{ Algorithm = "Hex";              Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo hex" }
    @{ Algorithm = "HMQ1725";          Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo hmq1725" } # CryptoDredge-v0.27.0 is fastest
    @{ Algorithm = "KawPow";           Type = "NVIDIA"; Fee = @(0.0075); MinMemGiBfree = 1.24; WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " ";                ExcludePools = @("NiceHash"); Arguments = " --algo kawpow" }
#   @{ Algorithm = "Lyra2RE2";         Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo lyra2v2" } # ASIC
    @{ Algorithm = "MegaBtx";          Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 1;    WarmupTimes = @(90, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo megabtx" }
    @{ Algorithm = "MemeHash";         Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 1;    WarmupTimes = @(45, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo memehash" }
    @{ Algorithm = "MeowPow";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGiBfree = 1.24; WarmupTimes = @(75, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo meowpow" }
    @{ Algorithm = "Mike";             Type = "NVIDIA"; Fee = @(0.01);   MinMemGiBfree = 1;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo mike" }
    @{ Algorithm = "NexaPow";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGiBfree = 3;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @("NiceHash"); Arguments = " --algo nexapow" } # https://github.com/andru-kun/wildrig-multi/issues/277
#   @{ Algorithm = "Nist5";            Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 3;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo nist5" } # ASIC
#   @{ Algorithm = "PearlHash";        Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(45, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo pearlhash" } # https://github.com/andru-kun/wildrig-multi/issues/383, only supports pool pearlhash.xyz
#   @{ Algorithm = "Phi";              Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo phi" } # ASIC
    @{ Algorithm = "ProgPowSero";      Type = "NVIDIA"; Fee = @(0.0075); MinMemGiBfree = 0.62; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo progpow-sero" }
    @{ Algorithm = "ProgPowTelestai";  Type = "NVIDIA"; Fee = @(0.0075); MinMemGiBfree = 0.62; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @();           Arguments = " --algo progpow-telestai" }
    @{ Algorithm = "ProgPowZ";         Type = "NVIDIA"; Fee = @(0.0075); MinMemGiBfree = 0.62; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo progpowz" }
#   @{ Algorithm = "Pufferfish2BMB";   Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 8;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo pufferfish2" } # waiting for coin to resurrect
    @{ Algorithm = "QHash";            Type = "NVIDIA"; Fee = @(0.02);   MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo qhash" }
#   @{ Algorithm = "Quark";            Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo quark" } # ASIC
#   @{ Algorithm = "Quibit";           Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo qui" } # ASIC
#   @{ Algorithm = "SHA256";           Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo sha256" } # ASIC
#   @{ Algorithm = "SHA256d";          Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo sha256d" } # ASIC
    @{ Algorithm = "SHA256csm";        Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo sha256csm" }
    @{ Algorithm = "SHA256t";          Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo sha256t" }
    @{ Algorithm = "SHA256q";          Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo sha256q" }
    @{ Algorithm = "SHA512256d";       Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo sha512256d" }
    @{ Algorithm = "Skein2";           Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(90, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo skein2" } # CcminerAlexis78-v1.5.2 is fastest
    @{ Algorithm = "SkunkHash";        Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(90, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo skunkhash" } # Algorithm is dead
    @{ Algorithm = "SkydogeHash";      Type = "NVIDIA"; Fee = @(0.02);   MinMemGiBfree = 2;    WarmupTimes = @(45, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo skydoge" }
    @{ Algorithm = "Timetravel";       Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo timetravel" }
    @{ Algorithm = "Timetravel10";     Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo timetravel10" }
#   @{ Algorithm = "Tribus";           Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo tribus" } # ASIC
#   @{ Algorithm = "X11";              Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x11" } # ASIC
#   @{ Algorithm = "X11ghost";         Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x11ghost" } # ASIC
    @{ Algorithm = "X11k";             Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x11k" }
#   @{ Algorithm = "X12";              Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x12" } # ASIC
#   @{ Algorithm = "X13";              Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x13" } # ASIC
#   @{ Algorithm = "X14";              Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x14" } # ASIC
#   @{ Algorithm = "X15";              Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x15" } # ASIC
#   @{ Algorithm = "X16r";             Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(45, 60);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x16r" } # ASIC
    @{ Algorithm = "X16rt";            Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x16rt" } # FPGA
    @{ Algorithm = "X16rv2";           Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 3;    WarmupTimes = @(150, 15); ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x16rv2" }
    @{ Algorithm = "X16s";             Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x16s" } # FPGA
    @{ Algorithm = "X17";              Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x17" }
#   @{ Algorithm = "X18";              Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x18" } # ASIC
#   @{ Algorithm = "X20r";             Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @();           Arguments = " --algo x20r" } # ASIC
    @{ Algorithm = "X21s";             Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(120, 45); ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x21s" }
    @{ Algorithm = "X22";              Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x22" }
    @{ Algorithm = "X22i";             Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x22i" }
    @{ Algorithm = "X25x";             Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x25x" }
    @{ Algorithm = "X33";              Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x33" }
#   @{ Algorithm = "X7";               Type = "NVIDIA"; Fee = @(0);      MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo x7" } # ASIC
)

$Algorithms = $Algorithms.Where{ $MinerPools[0][$_.Algorithm] }

if ($Algorithms) { 

    ($Devices | Group-Object -Property Type, Model).ForEach{ 
        $MinerDevices = $_.Group
        $Model = $MinerDevices[0].Model
        $Type = $MinerDevices[0].Type

        $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Bottom 1)

        $Algorithms.Where{ $_.Type -eq $Type }.ForEach{ 
            $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
            if ($SupportedMinerDevices = $MinerDevices.Where{ $_.Architecture -notmatch $ExcludeGPUarchitectures }) { 

                $ExcludePools = $_.ExcludePools
                foreach ($Pool in $MinerPools[0][$_.Algorithm].Where{ $ExcludePools -notcontains $_.Name }) { 

                    $MinMemGiBfree = $_.MinMemGiBfree + $Pool.DAGsizeGiB
                    if ($AvailableMinerDevices = $SupportedMinerDevices.Where{ $_.MemoryGiBfree -ge $MinMemGiBfree }) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                        # Allow more time to build larger DAGs, must use type cast to keep values in $_
                        $WarmupTimes = [UInt16[]]$_.WarmupTimes
                        $WarmupTimes[0] += [UInt16]($Pool.DAGsizeGiB * 2)

                        @{ 
                            API         = "XmRig"
                            Arguments   = "$($_.Arguments) --api-port $MinerAPIPort --url $(if ($Pool.PoolPorts[1]) { "stratum+tcps://$($Pool.Host):$($Pool.PoolPorts[1])" } else { "stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0])" }) --user $($Pool.User) --pass $($Pool.Pass) --multiple-instance --gpu-list $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach{ '{0:x}' -f $_ } -join ',')"
                            DeviceNames = $AvailableMinerDevices.Name
                            DownloadURL = $URL
                            Fee         = $_.Fee # Dev fee
                            MinerURL    = "http://127.0.0.1:$($MinerAPIPort)"
                            Name        = $MinerName
                            Path        = $Path
                            Port        = $MinerAPIPort
                            Type        = $Type
                            WarmupTimes = $WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                            Workers     = @(@{ Pool = $Pool })
                        }
                    }
                }
            }
        }
    }
}