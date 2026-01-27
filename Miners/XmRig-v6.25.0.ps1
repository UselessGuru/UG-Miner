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
Version:        6.7.25
Version date:   2026/01/27
#>

if (-not ($Devices = $Session.EnabledDevices.Where({ "AMD", "CPU", "INTEL" -contains $_.Type -or ($_.OpenCL.ComputeCapability -gt "5.0" -and $Session.DriverVersion.CUDA -ge [Version]"10.2") }))) { return }

# Fixed detection of L2 cache size for some complex NUMA topologies.
# Fixed ARMv7 build.
# Fixed auto-config for AMD CPUs with less than 2 MB L3 cache per thread.
# Improved IPv6 support: the new default settings use IPv6 equally with IPv4.

$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\xmrig.exe"
$DeviceEnumerator = "Type_Vendor_Index"

# There is no toolkit for CUDA 12.7
$URI = switch ($Session.DriverVersion.CUDA) { 
    { $_ -ge [System.Version]"12.9" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda12_9-win64.7z"; break }
    { $_ -ge [System.Version]"12.8" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda12_8-win64.7z"; break }
    { $_ -ge [System.Version]"12.6" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda12_6-win64.7z"; break }
    { $_ -ge [System.Version]"12.5" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda12_5-win64.7z"; break }
    { $_ -ge [System.Version]"12.4" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda12_4-win64.7z"; break }
    { $_ -ge [System.Version]"12.3" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda12_3-win64.7z"; break }
    { $_ -ge [System.Version]"12.2" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda12_2-win64.7z"; break }
    { $_ -ge [System.Version]"12.1" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda12_1-win64.7z"; break }
    { $_ -ge [System.Version]"12.0" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda12_0-win64.7z"; break }
    { $_ -ge [System.Version]"11.8" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda11_8-win64.7z"; break }
    { $_ -ge [System.Version]"11.7" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda11_7-win64.7z"; break }
    { $_ -ge [System.Version]"11.6" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda11_6-win64.7z"; break }
    { $_ -ge [System.Version]"11.5" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda11_5-win64.7z"; break }
    { $_ -ge [System.Version]"11.4" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda11_4-win64.7z"; break }
    { $_ -ge [System.Version]"11.3" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda11_3-win64.7z"; break }
    { $_ -ge [System.Version]"11.2" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda11_2-win64.7z"; break }
    { $_ -ge [System.Version]"11.1" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda11_1-win64.7z"; break }
    { $_ -ge [System.Version]"11.0" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda11_0-win64.7z"; break }
    { $_ -ge [System.Version]"10.2" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-cuda10_2-win64.7z"; break }
    default { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.25.0-msvc-win64.7z" }
}

$Algorithms = @(
    @{ Algorithm = "Cryptonight";          Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn/0" }
    @{ Algorithm = "CryptonightCcx";       Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn/ccx" }
    @{ Algorithm = "CryptonightDouble";    Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn/double" }
    @{ Algorithm = "CryptonightFast";      Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn/fast" }
    @{ Algorithm = "CryptonightLite";      Type = "AMD"; MinMemGiB = 1;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn-lite/0" }
    @{ Algorithm = "CryptonightLiteV1";    Type = "AMD"; MinMemGiB = 1;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn-lite/1" }
    @{ Algorithm = "CryptonightHalf";      Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn/half" }
    @{ Algorithm = "CryptonightHeavy";     Type = "AMD"; MinMemGiB = 4;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn-heavy/0" }
    @{ Algorithm = "CryptonightHeavyTube"; Type = "AMD"; MinMemGiB = 4;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn-heavy/tube" }
    @{ Algorithm = "CryptonightPico";      Type = "AMD"; MinMemGiB = 0.25; WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn-pico" }
    @{ Algorithm = "CryptonightPicoTlo";   Type = "AMD"; MinMemGiB = 0.25; WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn-pico/tlo" }
#   @{ Algorithm = "CryptonightR";         Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn/r" } # ASIC
    @{ Algorithm = "CryptonightRto";       Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn/rto" }
    @{ Algorithm = "CryptonightRwz";       Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn/rwz" }
    @{ Algorithm = "CryptonightV1";        Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn/1" }
    @{ Algorithm = "CryptonightV2";        Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn/2" }
    @{ Algorithm = "CryptonightXao";       Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn/xao" }
    @{ Algorithm = "CryptonightHeavyXhv";  Type = "AMD"; MinMemGiB = 4;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn-heavy/xhv" }
    @{ Algorithm = "CryptonightZls";       Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo cn/zls" }
    @{ Algorithm = "KawPow";               Type = "AMD"; MinMemGiB = 0.97; WarmupTimes = @(60, 0); ExcludePools = @(); Arguments = " --algo kawpow" }
#   @{ Algorithm = "Randomx";              Type = "AMD"; MinMemGiB = 3;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo rx/0" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxArq";           Type = "AMD"; MinMemGiB = 4;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo rx/arq" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxKeva";          Type = "AMD"; MinMemGiB = 1;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo rx/keva" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxLoki";          Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo rx/loki" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxSfx";           Type = "AMD"; MinMemGiB = 2;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo rx/sfx" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxWow";           Type = "AMD"; MinMemGiB = 3;    WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo rx/wow" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "Uplexa";               Type = "AMD"; MinMemGiB = 0.25; WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo rx/upx2" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway

    @{ Algorithm = "Argon2Chukwa";         Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo argon2/chukwa" }
    @{ Algorithm = "Argon2ChukwaV2";       Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo argon2/chukwav2" }
    @{ Algorithm = "Argon2Ninja";          Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo argon2/ninja" }
    @{ Algorithm = "Argon2WRKZ";           Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo argon2/wrkz" }
#   @{ Algorithm = "Cryptonight";          Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/0" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightCcx";       Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/ccx" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightDouble";    Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/double" }  # Not profitable with CPU
#   @{ Algorithm = "CryptonightFast";      Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/fast" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightLite";      Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/0" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightLiteV1";    Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/1" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightHalf";      Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/half" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightHeavy";     Type = "CPU"; WarmupTimes = @(45, 20); ExcludePools = @(); Arguments = " --algo cn-heavy/0" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightHeavyTube"; Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/tube" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightPico";      Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightPicoTlo";   Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico/tlo" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightR";         Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/r" } # ASIC
#   @{ Algorithm = "CryptonightRto";       Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rto" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightRwz";       Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rwz" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightUpx";       Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/upx2" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightV1";        Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/1" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightV2";        Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/2" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightXao";       Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/xao" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightHeavyXhv";  Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/xhv" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightZls";       Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/zls" } # Not profitable with CPU
#   @{ Algorithm = "Randomx";              Type = "CPU"; WarmupTimes = @(45, 20); ExcludePools = @(); Arguments = " --algo rx/0" } # ASIC
    @{ Algorithm = "Flex";                 Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo flex" }
    @{ Algorithm = "Ghostrider";           Type = "CPU"; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo gr" }
    @{ Algorithm = "Panthera";             Type = "CPU"; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo panthera" }
    @{ Algorithm = "RandomxArq";           Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/arq" } # FPGA
    @{ Algorithm = "RandomXeq";            Type = "CPU"; WarmupTimes = @(60, 0);  ExcludePools = @(); Arguments = " --algo rx/xeq" }
    @{ Algorithm = "RandomxKeva";          Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/keva" }
    @{ Algorithm = "RandomxLoki";          Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/loki" }
    @{ Algorithm = "RandomxSfx";           Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/sfx" }
    @{ Algorithm = "RandomxWow";           Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/wow" }
    @{ Algorithm = "Uplexa";               Type = "CPU"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/upx2" }

    @{ Algorithm = "Cryptonight";          Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/0" }
    @{ Algorithm = "CryptonightCcx";       Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/ccx" }
    @{ Algorithm = "CryptonightDouble";    Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/double" }
    @{ Algorithm = "CryptonightFast";      Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/fast" }
    @{ Algorithm = "CryptonightLite";      Type = "INTEL"; MinMemGiB = 1;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/0" }
    @{ Algorithm = "CryptonightLiteV1";    Type = "INTEL"; MinMemGiB = 1;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/1" }
    @{ Algorithm = "CryptonightHalf";      Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/half" }
    @{ Algorithm = "CryptonightHeavy";     Type = "INTEL"; MinMemGiB = 4;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/0" }
    @{ Algorithm = "CryptonightHeavyTube"; Type = "INTEL"; MinMemGiB = 4;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/tube" }
    @{ Algorithm = "CryptonightPico";      Type = "INTEL"; MinMemGiB = 0.25; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico" }
    @{ Algorithm = "CryptonightPicoTlo";   Type = "INTEL"; MinMemGiB = 0.25; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico/tlo" }
#   @{ Algorithm = "CryptonightR";         Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/r" } # ASIC
    @{ Algorithm = "CryptonightRto";       Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rto" }
    @{ Algorithm = "CryptonightRwz";       Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rwz" }
    @{ Algorithm = "CryptonightV1";        Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/1" }
    @{ Algorithm = "CryptonightV2";        Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/2" }
    @{ Algorithm = "CryptonightXao";       Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/xao" }
    @{ Algorithm = "CryptonightHeavyXhv";  Type = "INTEL"; MinMemGiB = 4;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/xhv" }
    @{ Algorithm = "CryptonightZls";       Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/zls" }
    @{ Algorithm = "KawPow";               Type = "INTEL"; MinMemGiB = 0.97; WarmupTimes = @(60, 15); ExcludePools = @(); Arguments = " --algo kawpow" }
#   @{ Algorithm = "Randomx";              Type = "INTEL"; MinMemGiB = 3;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/0" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxArq";           Type = "INTEL"; MinMemGiB = 4;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/arq" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxKeva";          Type = "INTEL"; MinMemGiB = 1;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/keva" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxLoki";          Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/loki" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxSfx";           Type = "INTEL"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/sfx" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxWow";           Type = "INTEL"; MinMemGiB = 3;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/wow" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "Uplexa";               Type = "INTEL"; MinMemGiB = 0.25; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/upx2" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway

    @{ Algorithm = "Cryptonight";          Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/0" }
    @{ Algorithm = "CryptonightCcx";       Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/ccx" } # CryptoDredge-v0.27.0 is fastest, but has 1% miner fee
    @{ Algorithm = "CryptonightDouble";    Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/double" }
    @{ Algorithm = "CryptonightFast";      Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/fast" }
    @{ Algorithm = "CryptonightLite";      Type = "NVIDIA"; MinMemGiB = 1;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/0" }
    @{ Algorithm = "CryptonightLiteV1";    Type = "NVIDIA"; MinMemGiB = 1;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/1" }
    @{ Algorithm = "CryptonightHalf";      Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/half" } # CryptoDredge-v0.27.0 is fastest, but has 1% miner fee
    @{ Algorithm = "CryptonightHeavy";     Type = "NVIDIA"; MinMemGiB = 4;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/0" }
    @{ Algorithm = "CryptonightHeavyTube"; Type = "NVIDIA"; MinMemGiB = 1;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/tube" }
    @{ Algorithm = "CryptonightPico";      Type = "NVIDIA"; MinMemGiB = 0.25; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico" }
    @{ Algorithm = "CryptonightPicoTlo";   Type = "NVIDIA"; MinMemGiB = 0.25; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico/tlo" }
#   @{ Algorithm = "CryptonightR";         Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/r" } # ASIC
    @{ Algorithm = "CryptonightRto";       Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rto" }
    @{ Algorithm = "CryptonightRwz";       Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rwz" }
    @{ Algorithm = "CryptonightV1";        Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/1" }
    @{ Algorithm = "CryptonightV2";        Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/2" }
    @{ Algorithm = "CryptonightXao";       Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/xao" }
    @{ Algorithm = "CryptonightHeavyXhv";  Type = "NVIDIA"; MinMemGiB = 4;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/xhv" }
    @{ Algorithm = "CryptonightZls";       Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/zls" }
    @{ Algorithm = "KawPow";               Type = "NVIDIA"; MinMemGiB = 0.77; WarmupTimes = @(60, 15); ExcludePools = @(); Arguments = " --algo kawpow" } # Trex-v0.26.8 is fastest, but has 1% miner fee (Broken: https://github.com/RainbowMiner/RainbowMiner/issues/2224)
#   @{ Algorithm = "Randomx";              Type = "NVIDIA"; MinMemGiB = 3;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/0" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxArq";           Type = "NVIDIA"; MinMemGiB = 4;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/arq" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxKeva";          Type = "NVIDIA"; MinMemGiB = 1;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/keva" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxLoki";          Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/loki" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxSfx";           Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/sfx" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxWow";           Type = "NVIDIA"; MinMemGiB = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/wow" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "Uplexa";               Type = "NVIDIA"; MinMemGiB = 0.5;  WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/upx2" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            # Optionally disable dev fee mining, requires change in source code
            # $Fee = If ($Session.Config.DisableMinerFee) { 0 } else { 1 }
            $Fee = 0

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    # $ExcludePools = $_.ExcludePools
                    # foreach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 
                    foreach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                        $MinMemGiB = $_.MinMemGiB + $Pool.DAGsizeGiB
                        if ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -gt $MinMemGiB })) { 

                            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                            $Arguments = $_.Arguments
                            if ($_.Type -eq "CPU") { $Arguments += " --threads=$($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $Session.Config.CPUMiningReserveCPUcore)" }
                            elseif ("AMD", "INTEL" -contains $_.Type) { $Arguments += " --no-cpu --opencl --opencl-platform $($AvailableMinerDevices.PlatformId) --opencl-devices=$(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')" }
                            else { $Arguments += " --no-cpu --cuda --cuda-devices=$(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')" }
                            if (-not $Session.IsLocalAdmin) { $Arguments += " --randomx-wrmsr=-1" } #  disable MSR mod

                            $MinerPath = if ($_.Algorithm -in "Ghostrider", "Flex", "Panthera", "RandomXeq", "RandomxKeva") { $Path -replace "\\xmrig.exe$", "\xmrig-mo.exe" } else { $Path } # https://github.com/RainbowMiner/RainbowMiner/issues/2800
                            $RigID = if ($Pool.WorkerName) { $Pool.WorkerName } elseif ($Pool.User -like "*.*") { $Pool.User -replace ".+\." } else { $Session.Config.WorkerName }

                            [PSCustomObject]@{ 
                                API         = "XmRig"
                                Arguments   = "$Arguments$(if ($Pool.Name -eq "NiceHash") { " --nicehash" })$(if ($Pool.PoolPorts[1]) { " --tls" }) --url=$($Pool.Host):$($Pool.PoolPorts.Where({ $null -ne $_ })[-1]) --user=$($Pool.User) --pass=$($Pool.Pass) --rig-id $RigID --donate-level $Fee --keepalive --http-enabled --http-host=127.0.0.1 --http-port=$($MinerAPIPort) --api-worker-id=$RigID --api-id=$($MinerName) --retries=90 --retry-pause=1"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = @($Fee) # Dev fee
                                MinerUri    = "http://127.0.0.1:$($MinerAPIPort)/api.json"
                                Name        = $MinerName
                                Path        = $MinerPath
                                Port        = $MinerAPIPort
                                Type        = $Type
                                URI         = $URI
                                WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}