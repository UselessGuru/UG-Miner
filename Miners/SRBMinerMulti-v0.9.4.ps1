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
Version:        6.7.11
Version date:   2025/12/18
#>

# Support for Pitcairn, Tahiti, Hawaii, Fiji and Tonga was removed in later versions
if (-not ($Devices = $Session.EnabledDevices.where({ $_.Type -eq "AMD" -and $_.Architecture -match "GCN[1-3]" }))) { return }

$URI = "https://github.com/doktor83/SRBMiner-Multi/releases/download/0.9.4/SRBMiner-Multi-0-9-4-win64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\SRBMiner-MULTI.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# Algorithm parameter values are case sensitive!
$Algorithms = @( 
    @{ Algorithm = "0x10";              Fee = @(0.0085); MinMemGiB = 2;    WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --disable-cpu --algorithm 0x10" }
    @{ Algorithm = "Argon2d16000";      Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --disable-cpu --algorithm argon2d_16000" }
    @{ Algorithm = "Argon2d500";        Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --disable-cpu --algorithm argon2d_dynamic" }
    @{ Algorithm = "Argon2Chukwa";      Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --disable-cpu --algorithm argon2id_chukwa" }
    @{ Algorithm = "Argon2Chukwa2";     Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --disable-cpu --algorithm argon2id_chukwa2" }
    @{ Algorithm = "Autolykos2";        Fee = @(0.02; ); MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm autolykos2" }
    @{ Algorithm = "Blake2b";           Fee = @(0);    ; MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm blake2b" } # FPGA
#   @{ Algorithm = "Blake2s";           Fee = @(0);    ; MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm blake2s" } # ASIC
    @{ Algorithm = "Blake3";            Fee = @(0.01); ; MinMemGiB = 2;    WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm blake3_alephium" }
    @{ Algorithm = "CircCash";          Fee = @(00085;); MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm circcash" }
    @{ Algorithm = "CryptonightCcx";    Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm cryptonight_ccx" }
    @{ Algorithm = "CryptonightGpu";    Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(60, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm cryptonight_gpu" }
    @{ Algorithm = "CryptonightTalleo"; Fee = @(0);    ; MinMemGiB = 1;    WarmupTimes = @(60, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm cryptonight_talleo" }
    @{ Algorithm = "CryptonightTurtle"; Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm cryptonight_turtle" } # TeamRedMiner-v0.10.3 is fastest
    @{ Algorithm = "CryptonightUpx";    Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm cryptonight_upx" }
    @{ Algorithm = "CryptonightXhv";    Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm cryptonight_xhv" }
#   @{ Algorithm = "DynamoCoin";        Fee = @(0.01); ; MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm dynamo" } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
    @{ Algorithm = "EtcHash";           Fee = @(0.0065); MinMemGiB = 1.24; WarmupTimes = @(90, 75); ExcludePools = @(); Arguments = " --disable-cpu --algorithm etchash --gpu-boost 50" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithm = "Ethash";            Fee = @(0.0065); MinMemGiB = 1.24; WarmupTimes = @(90, 75); ExcludePools = @(); Arguments = " --disable-cpu --algorithm ethash --gpu-boost 50" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithm = "FiroPow";           Fee = @(0.0085); MinMemGiB = 1.24; WarmupTimes = @(60, 75); ExcludePools = @(); Arguments = " --disable-cpu --algorithm firopow --gpu-boost 50" }
    @{ Algorithm = "HeavyHash";         Fee = @(0.01); ; MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm heavyhash" } # FPGA
#   @{ Algorithm = "K12";               Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm k12" } # ASIC
    @{ Algorithm = "KawPow";            Fee = @(0.0085); MinMemGiB = 1.24; WarmupTimes = @(90, 75); ExcludePools = @(); Arguments = " --disable-cpu --algorithm kawpow --gpu-boost 50" }
#   @{ Algorithm = "Keccak";            Fee = @(0);    ; MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm keccak" } # ASIC
    @{ Algorithm = "Lyra2v2Webchain";   Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm lyra2v2_webchain" }
    @{ Algorithm = "ProgPowEpic";       Fee = @(0.0065); MinMemGiB = 2;    WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm progpow_epic" }
    @{ Algorithm = "ProgPowSero";       Fee = @(0.0065); MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm progpow_sero" }
    @{ Algorithm = "ProgPowVeil";       Fee = @(0.0065); MinMemGiB = 2;    WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm progpow_veil" }
    @{ Algorithm = "ProgPowVeriblock";  Fee = @(0.0065); MinMemGiB = 2;    WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm progpow_veriblock" }
    @{ Algorithm = "ProgPowanoZ";       Fee = @(0.0065); MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm progpow_zano" }
    @{ Algorithm = "SHA3d";             Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm sha3d" } # FPGU
#   @{ Algorithm = "VerusHash";         Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --disable-cpu --algorithm verushash" }
    @{ Algorithm = "VertHash";          Fee = @(0.0125); MinMemGiB = 1;    WarmupTimes = @(30, 10); ExcludePools = @(); Arguments = " --disable-cpu --algorithm verthash --verthash-dat-path ..\.$($Session.VertHashDatPath)" }
    @{ Algorithm = "Yescrypt";          Fee = @(0.0085); MinMemGiB = 1;    WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --disable-cpu --algorithm yescrypt" }
)

$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithm] })

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.where({ $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.ForEach(
                { 
                    if ($_.Algorithm -eq "VertHash" -and (Get-Item -Path $Session.VertHashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                        $PrerequisitePath = $Session.VertHashDatPath
                        $PrerequisiteURI = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
                    }
                    else { 
                        $PrerequisitePath = ""
                        $PrerequisiteURI = ""
                    }

                    # $ExcludePools = $_.ExcludePools
                    # foreach ($Pool in $MinerPools[0][$_.Algorithm].where({ $ExcludePools -notcontains $_.Name })) { 
                    foreach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                        $MinMemGiB = $_.MinMemGiB + $Pool.DAGsizeGiB
                        if ($AvailableMinerDevices = $MinerDevices.where({ $_.MemoryGiB -gt $MinMemGiB })) { 

                            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                            $Arguments = $_.Arguments
                            switch ($Pool.Protocol) { 
                                "ethproxy"     { $Arguments += " --esm 0"; break }
                                "ethstratum1"  { $Arguments += " --esm 1"; break }
                                "ethstratum2"  { $Arguments += " --esm 2"; break }
                                "ethstratumnh" { $Arguments += " --esm 2"; break }
                                "minerproxy"   { $Arguments += " --esm 1" }
                            }
                            $Arguments += " --pool $($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --wallet $($Pool.User) --password $($Pool.Pass)"
                            if ($Pool.WorkerName) { $Arguments += " --worker $($Pool.WorkerName)" }
                            if ($Pool.PoolPorts[1]) { $Arguments += " --tls true" }

                            [PSCustomObject]@{ 
                                API              = "SRBMiner"
                                Arguments        = "$Arguments --disable-workers-ramp-up --api-rig-name $($Session.Config.Pools.($Pool0.Name).WorkerName) --api-enable --api-port $MinerAPIPort --gpu-auto-tune 2 --gpu-id $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames      = $AvailableMinerDevices.Name
                                Fee              = $_.Fee # Dev fee
                                MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/stats"
                                Name             = $MinerName
                                Path             = $Path
                                Port             = $MinerAPIPort
                                PrerequisitePath = $PrerequisitePath
                                PrerequisiteURI  = $PrerequisiteURI
                                Type             = "AMD"
                                URI              = $URI
                                WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers          = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}