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
Version:        6.2.24
Version date:   2024/08/10
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ "AMD", "CPU", "INTEL" -contains $_.Type -or $_.OpenCL.ComputeCapability -gt "5.0" }))) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "12.4" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda12_4-win64.zip"; Break }
    { $_ -ge "12.3" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda12_3-win64.zip"; Break }
    { $_ -ge "12.2" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda12_2-win64.zip"; Break }
    { $_ -ge "12.1" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda12_1-win64.zip"; Break }
    { $_ -ge "12.0" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda12_0-win64.zip"; Break }
    { $_ -ge "11.8" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda11_8-win64.zip"; Break }
    { $_ -ge "11.7" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda11_7-win64.zip"; Break }
    { $_ -ge "11.6" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda11_6-win64.zip"; Break }
    { $_ -ge "11.5" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda11_5-win64.zip"; Break }
    { $_ -ge "11.4" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda11_4-win64.zip"; Break }
    { $_ -ge "11.3" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda11_3-win64.zip"; Break }
    { $_ -ge "11.2" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda11_2-win64.zip"; Break }
    { $_ -ge "11.1" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda11_1-win64.zip"; Break }
    { $_ -ge "11.0" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda11_0-win64.zip"; Break }
    { $_ -ge "10.2" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda10_2-win64.zip"; Break }
    { $_ -ge "10.1" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda10_1-win64.zip"; Break }
    { $_ -ge "10.0" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda10_0-win64.zip"; Break }
    { $_ -ge "9.2" }  { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda9_2-win64.zip"; Break }
    { $_ -ge "9.1" }  { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda9_1-win64.zip"; Break }
    { $_ -ge "9.0" }  { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda9_0-win64.zip"; Break }
    Default           { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/XMrig/xmrig-6.21.3.14-cuda8_0-win64.zip"; Break }
}
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\xmrig.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithm = "Cryptonight";          Type = "AMD"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/0" }
    @{ Algorithm = "CryptonightCcx";       Type = "AMD"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/ccx" }
    @{ Algorithm = "CryptonightDouble";    Type = "AMD"; MinMemGiB = 2;    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/double" }
    @{ Algorithm = "CryptonightFast";      Type = "AMD"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/fast" }
    @{ Algorithm = "CryptonightLite";      Type = "AMD"; MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/0" }
    @{ Algorithm = "CryptonightLiteV1";    Type = "AMD"; MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/1" }
    @{ Algorithm = "CryptonightHalf";      Type = "AMD"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/half" }
    @{ Algorithm = "CryptonightHeavy";     Type = "AMD"; MinMemGiB = 4;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/0" }
    @{ Algorithm = "CryptonightHeavyTube"; Type = "AMD"; MinMemGiB = 4;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/tube" }
    @{ Algorithm = "CryptonightPico";      Type = "AMD"; MinMemGiB = 0.25; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico" }
    @{ Algorithm = "CryptonightPicoTlo";   Type = "AMD"; MinMemGiB = 0.25; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico/tlo" }
#   @{ Algorithm = "CryptonightR";         Type = "AMD"; MinMemGiB = 2;    MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/r" } # ASIC
    @{ Algorithm = "CryptonightRto";       Type = "AMD"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rto" }
    @{ Algorithm = "CryptonightRwz";       Type = "AMD"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rwz" }
    @{ Algorithm = "CryptonightV1";        Type = "AMD"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/1" }
    @{ Algorithm = "CryptonightV2";        Type = "AMD"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/2" }
    @{ Algorithm = "CryptonightXao";       Type = "AMD"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/xao" }
    @{ Algorithm = "CryptonightHeavyXhv";  Type = "AMD"; MinMemGiB = 4;    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/xhv" }
    @{ Algorithm = "CryptonightZls";       Type = "AMD"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/zls" }
    @{ Algorithm = "KawPow";               Type = "AMD"; MinMemGiB = 0.77; MinerSet = 1; WarmupTimes = @(60, 15); ExcludePools = @(); Arguments = " --algo kawpow" } # NBMiner-v42.3 is fastest, but has 2% miner fee
#   @{ Algorithm = "Randomx";              Type = "AMD"; MinMemGiB = 3;    MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/0" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxArq";           Type = "AMD"; MinMemGiB = 4;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/arq" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxKeva";          Type = "AMD"; MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/keva" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxLoki";          Type = "AMD"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/loki" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxSfx";           Type = "AMD"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/sfx" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxWow";           Type = "AMD"; MinMemGiB = 3;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/wow" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "Uplexa";               Type = "AMD"; MinMemGiB = 0.25; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/upx2" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway

    @{ Algorithm = "Argon2Chukwa";         Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo argon2/chukwa" }
    @{ Algorithm = "Argon2ChukwaV2";       Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo argon2/chukwav2" }
    @{ Algorithm = "Argon2Ninja";          Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo argon2/ninja" }
    @{ Algorithm = "Argon2WRKZ";           Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo argon2/wrkz" }
#   @{ Algorithm = "Cryptonight";          Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/0" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightCcx";       Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/ccx" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightDouble";    Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/double" }  # Not profitable with CPU
#   @{ Algorithm = "CryptonightFast";      Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/fast" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightLite";      Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn-lite/0" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightLiteV1";    Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn-lite/1" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightHalf";      Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/half" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightHeavy";     Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 20);  ExcludePools = @(); Arguments = " --algo cn-heavy/0" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightHeavyTube"; Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn-heavy/tube" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightPico";      Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn-pico" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightPicoTlo";   Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn-pico/tlo" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightR";         Type = "CPU"; MinerSet = 3; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/r" } # ASIC
#   @{ Algorithm = "CryptonightRto";       Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/rto" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightRwz";       Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/rwz" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightUpx";       Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/upx2" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightV1";        Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/1" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightV2";        Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/2" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightXao";       Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/xao" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightHeavyXhv";  Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn-heavy/xhv" } # Not profitable with CPU
#   @{ Algorithm = "CryptonightZls";       Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/zls" } # Not profitable with CPU
#   @{ Algorithm = "Randomx";              Type = "CPU"; MinerSet = 3; WarmupTimes = @(45, 20);  ExcludePools = @(); Arguments = " --algo rx/0" } # ASIC
#   @{ Algorithm = "Flex";                 Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo flex" } # NOt workinf
    @{ Algorithm = "Ghostrider";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(180, 60); ExcludePools = @(); Arguments = " --algo gr" }
    @{ Algorithm = "RandomxArq";           Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo rx/arq" } # FPGA
    @{ Algorithm = "RandomXeq";            Type = "CPU"; MinerSet = 3; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo rx/xeq" }
    @{ Algorithm = "RandomxKeva";          Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo rx/keva" }
    @{ Algorithm = "RandomxLoki";          Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo rx/loki" }
    @{ Algorithm = "RandomxSfx";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo rx/sfx" }
    @{ Algorithm = "RandomxWow";           Type = "CPU"; MinerSet = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo rx/wow" }
    @{ Algorithm = "Uplexa";               Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo rx/upx2" }

    @{ Algorithm = "Cryptonight";          Type = "INTEL"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/0" }
    @{ Algorithm = "CryptonightCcx";       Type = "INTEL"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/ccx" }
    @{ Algorithm = "CryptonightDouble";    Type = "INTEL"; MinMemGiB = 2;    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/double" }
    @{ Algorithm = "CryptonightFast";      Type = "INTEL"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/fast" }
    @{ Algorithm = "CryptonightLite";      Type = "INTEL"; MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/0" }
    @{ Algorithm = "CryptonightLiteV1";    Type = "INTEL"; MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/1" }
    @{ Algorithm = "CryptonightHalf";      Type = "INTEL"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/half" }
    @{ Algorithm = "CryptonightHeavy";     Type = "INTEL"; MinMemGiB = 4;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/0" }
    @{ Algorithm = "CryptonightHeavyTube"; Type = "INTEL"; MinMemGiB = 4;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/tube" }
    @{ Algorithm = "CryptonightPico";      Type = "INTEL"; MinMemGiB = 0.25; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico" }
    @{ Algorithm = "CryptonightPicoTlo";   Type = "INTEL"; MinMemGiB = 0.25; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico/tlo" }
#   @{ Algorithm = "CryptonightR";         Type = "INTEL"; MinMemGiB = 2;    MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/r" } # ASIC
    @{ Algorithm = "CryptonightRto";       Type = "INTEL"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rto" }
    @{ Algorithm = "CryptonightRwz";       Type = "INTEL"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rwz" }
    @{ Algorithm = "CryptonightV1";        Type = "INTEL"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/1" }
    @{ Algorithm = "CryptonightV2";        Type = "INTEL"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/2" }
    @{ Algorithm = "CryptonightXao";       Type = "INTEL"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/xao" }
    @{ Algorithm = "CryptonightHeavyXhv";  Type = "INTEL"; MinMemGiB = 4;    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/xhv" }
    @{ Algorithm = "CryptonightZls";       Type = "INTEL"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/zls" } 
    @{ Algorithm = "KawPow";               Type = "INTEL"; MinMemGiB = 0.77; MinerSet = 1; WarmupTimes = @(60, 15); ExcludePools = @(); Arguments = " --algo kawpow" } # NBMiner-v42.3 is fastest, but has 2% miner fee
#   @{ Algorithm = "Randomx";              Type = "INTEL"; MinMemGiB = 3;    MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/0" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxArq";           Type = "INTEL"; MinMemGiB = 4;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/arq" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxKeva";          Type = "INTEL"; MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/keva" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxLoki";          Type = "INTEL"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/loki" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxSfx";           Type = "INTEL"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/sfx" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxWow";           Type = "INTEL"; MinMemGiB = 3;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/wow" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "Uplexa";               Type = "INTEL"; MinMemGiB = 0.25; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/upx2" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway

    @{ Algorithm = "Cryptonight";          Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/0" }
    @{ Algorithm = "CryptonightCcx";       Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/ccx" } # CryptoDredge-v0.27.0 is fastest, but has 1% miner fee
    @{ Algorithm = "CryptonightDouble";    Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/double" }
    @{ Algorithm = "CryptonightFast";      Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/fast" }
    @{ Algorithm = "CryptonightLite";      Type = "NVIDIA"; MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/0" }
    @{ Algorithm = "CryptonightLiteV1";    Type = "NVIDIA"; MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/1" }
    @{ Algorithm = "CryptonightHalf";      Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/half" } # CryptoDredge-v0.27.0 is fastest, but has 1% miner fee
    @{ Algorithm = "CryptonightHeavy";     Type = "NVIDIA"; MinMemGiB = 4;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/0" }
    @{ Algorithm = "CryptonightHeavyTube"; Type = "NVIDIA"; MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/tube" }
    @{ Algorithm = "CryptonightPico";      Type = "NVIDIA"; MinMemGiB = 0.25; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico" }
    @{ Algorithm = "CryptonightPicoTlo";   Type = "NVIDIA"; MinMemGiB = 0.25; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico/tlo" }
#   @{ Algorithm = "CryptonightR";         Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/r" } # ASIC
    @{ Algorithm = "CryptonightRto";       Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rto" }
    @{ Algorithm = "CryptonightRwz";       Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rwz" }
    @{ Algorithm = "CryptonightV1";        Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/1" }
    @{ Algorithm = "CryptonightV2";        Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/2" }
    @{ Algorithm = "CryptonightXao";       Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/xao" }
    @{ Algorithm = "CryptonightHeavyXhv";  Type = "NVIDIA"; MinMemGiB = 4;    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/xhv" }
    @{ Algorithm = "CryptonightZls";       Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/zls" }
    @{ Algorithm = "KawPow";               Type = "NVIDIA"; MinMemGiB = 0.77; MinerSet = 3; WarmupTimes = @(60, 15); ExcludePools = @(); Arguments = " --algo kawpow" } # Trex-v0.26.8 is fastest, but has 1% miner fee (Broken: https://github.com/RainbowMiner/RainbowMiner/issues/2224)
#   @{ Algorithm = "Randomx";              Type = "NVIDIA"; MinMemGiB = 3;    MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/0" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxArq";           Type = "NVIDIA"; MinMemGiB = 4;    MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/arq" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxKeva";          Type = "NVIDIA"; MinMemGiB = 1;    MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/keva" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxLoki";          Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/loki" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxSfx";           Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/sfx" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "RandomxWow";           Type = "NVIDIA"; MinMemGiB = 2;    MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/wow" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   @{ Algorithm = "Uplexa";               Type = "NVIDIA"; MinMemGiB = 0.5;  MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/upx2" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            # Optionally disable dev fee mining, requires change in source code
            # $Fee = If ($Config.DisableMinerFee) { 0 } Else { 1 }
            $Fee = 0

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    # $ExcludePools = $_.ExcludePools
                    # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name }) | Select-Object -Last $(If ($_.Type -eq "CPU") { 1 } Else { $MinerPools[0][$_.Algorithm].Count })) { 
                    ForEach ($Pool in $MinerPools[0][$_.Algorithm] | Select-Object -Last $(If ($_.Type -eq "CPU") { 1 } Else { $MinerPools[0][$_.Algorithm].Count })) { 

                        $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                        If ($AvailableMinerDevices = $MinerDevices.Where({ $_.Type -eq "CPU" -or $_.MemoryGiB -gt $MinMemGiB })) { 

                            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                            $Arguments = $_.Arguments
                            If ($_.Type -eq "CPU") { $Arguments += " --threads=$($AvailableMinerDevices.CIM.NumberOfLogicalProcessors -$($Config.CPUMiningReserveCPUcore))" }
                            ElseIf ("AMD", "INTEL" -contains $_.Type) { $Arguments += " --no-cpu --opencl --opencl-platform $($AvailableMinerDevices.PlatformId) --opencl-devices=$(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')" }
                            Else { $Arguments += " --no-cpu --cuda --cuda-devices=$(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')" }

                            If ("Flex", "RandomXeq" -contains $_.Algorithm) { $Path = $Path -replace '\\xmrig.exe$', '\xmrig-mo.exe' } # https://github.com/RainbowMiner/RainbowMiner/issues/2800

                            [PSCustomObject]@{ 
                                API         = "XmRig"
                                Arguments   = "$Arguments$(If ($Pool.Name -eq "NiceHash") { " --nicehash" })$(If ($Pool.PoolPorts[1]) { " --tls" }) --url=$($Pool.Host):$($Pool.PoolPorts.Where({ $_ -ne $null })[-1]) --user=$($Pool.User) --pass=$($Pool.Pass)$(If ($Pool.WorkerName) { " --rig-id $($Pool.WorkerName)" }) --donate-level $Fee --keepalive --http-enabled --http-host=127.0.0.1 --http-port=$($MinerAPIPort) --api-worker-id=$($Config.WorkerName) --api-id=$($MinerName) --retries=90 --retry-pause=1"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = @($Fee) # Dev fee
                                MinerSet    = $_.MinerSet
                                MinerUri    = "http://workers.xmrig.info/worker?url=$([System.Web.HTTPUtility]::UrlEncode("http://127.0.0.1:$($MinerAPIPort)"))?Authorization=Bearer $([System.Web.HTTPUtility]::UrlEncode($MinerName))"
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = $_.Type
                                URI         = $URI
                                WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}