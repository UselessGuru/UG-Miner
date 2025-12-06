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
Version:        6.7.4
Version date:   2025/12/06
#>

# TT needs avx2 and aes https://github.com/TrailingStop/TT-Miner-beta/issues/7#issuecomment-2158058291
if (($Session.CPUfeatures -match "^AES$|^AVX2$").count -ne 2) { return }
if (-not ($Devices = $Session.EnabledDevices.where({ ($_.Type -eq "NVIDIA" -and $_.OpenCL.ComputeCapability -gt "5.0") -or "AMD", "NVIDIA" -contains $_.Type }))) { return }

$URI = switch ($Session.DriverVersion.CUDA) { 
    { $_ -ge [System.Version]"11.0" } { "http://www.tradeproject.de/download/Miner/TT-Miner-2024.3.3b6.zip"; break }
    default { return }
}
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\TT-Miner.exe"
$DeviceEnumerator = "Bus"

$Algorithms = @(
    @{ Algorithm = "Blake3";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 2.0;  WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a Blake3" }
    @{ Algorithm = "EtcHash";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a EtcHash" }
    @{ Algorithm = "Ethash";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.00; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a Ethash" }
    @{ Algorithm = "EthashB3";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.00; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a EthashB3" }
    @{ Algorithm = "EvrProPow";        Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a EvrProgPow" }
    @{ Algorithm = "FiroPow";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a FiroPow" }
    @{ Algorithm = "FishHash";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a fishhash" }
    @{ Algorithm = "KawPow";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(75, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a KawPow" }
    @{ Algorithm = "MeowPow";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(120, 0); ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a meowpow" }
    @{ Algorithm = "ProgPowEpic";      Type = "AMD"; Fee = @(0.02); MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -c EPIC" }
    @{ Algorithm = "ProgPowSero";      Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -c SERO" }
    @{ Algorithm = "ProgPowVeil";      Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -c VEIL" }
    @{ Algorithm = "ProgPowZ";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -c ZANO" }
    @{ Algorithm = "ProgPowVeriblock"; Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a vProgPow" }
    @{ Algorithm = "SCCpow";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -c SCC" }
#   @{ Algorithm = "SHA256d";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a SHA256D" } # ASIC
    @{ Algorithm = "SHA256dt";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a SHA256DT" }
    @{ Algorithm = "SHA3D";            Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a Sha3D" }
#   @{ Algorithm = "SHA512256d";       Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = "^GCN4$"; ExcludePools = @(); Arguments = " -a SHA512256D" } # https://github.com/TrailingStop/TT-Miner-beta/issues/12
    @{ Algorithm = "SHA3Solidity";     Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a SHA3SOL" }
    @{ Algorithm = "UbqHash";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " ";      ExcludePools = @(); Arguments = " -a UbqHash" }

    @{ Algorithm = "Ghostrider";       Type = "CPU"; Fee = @(0.01); WarmupTimes = @(30, 0); ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a Ghostrider" }
    @{ Algorithm = "Flex";             Type = "CPU"; Fee = @(0.01); WarmupTimes = @(30, 0); ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a Flex" }
    @{ Algorithm = "SpectreX";         Type = "CPU"; Fee = @(0.01); WarmupTimes = @(60, 0); ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a SpectreX" }
    @{ Algorithm = "XelisHash";        Type = "CPU"; Fee = @(0.01); WarmupTimes = @(30, 0); ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a Xelis" }

    @{ Algorithm = "Blake3";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2.0;  WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a Blake3" }
    @{ Algorithm = "EtcHash";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a EtcHash" }
    @{ Algorithm = "Ethash";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.00; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a Ethash" }
    @{ Algorithm = "EthashB3";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.00; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a EthashB3" }
    @{ Algorithm = "EvrProPow";        Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a EvrProgPow" }
    @{ Algorithm = "FiroPow";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a FiroPow" }
    @{ Algorithm = "FishHash";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a FishHash" }
    @{ Algorithm = "Ghostrider";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 3;    WarmupTimes = @(300, 0); ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a Ghostrider" }
    @{ Algorithm = "KawPow";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(75, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a KawPow" }
    @{ Algorithm = "MeowPow";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(120, 0); ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a meowpow" }
    @{ Algorithm = "ProgPowEpic";      Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -c EPIC" }
    @{ Algorithm = "ProgPowSero";      Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -c SERO" }
    @{ Algorithm = "ProgPowVeil";      Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -c VEIL" }
    @{ Algorithm = "ProgPowZ";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -c ZANO" }
    @{ Algorithm = "ProgPowVeriblock"; Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a vProgPow" }
    @{ Algorithm = "SCCpow";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -c SCC" }
#   @{ Algorithm = "SHA256d";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a SHA256D" } # ASIC
    @{ Algorithm = "SHA256dt";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a SHA256DT" }
    @{ Algorithm = "SHA3D";            Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a Sha3D" }
    @{ Algorithm = "SHA512256d";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a SHA512256D" }
    @{ Algorithm = "SHA3Solidity";     Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a SHA3SOL" }
    @{ Algorithm = "UbqHash";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " -a UbqHash" }
)

$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.where({ $_.Algorithm -ne "EtcHash" -or $MinerPools[0][$_.Algorithm].Epoch -lt 383 }) # Miner supports EtcHash up to epoch 382

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.where({ $_.Type -eq $Type }).ForEach(
                { 
                    # $ExcludePools = $_.ExcludePools
                    # foreach ($Pool in $MinerPools[0][$_.Algorithm].where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 
                    foreach ($Pool in $MinerPools[0][$_.Algorithm].where({ $_.PoolPorts[0] })) { 

                        $MinMemGiB = $_.MinMemGiB + $Pool.DAGsizeGiB
                        if ($AvailableMinerDevices = $MinerDevices.where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                            if ("AKA", "ALPH", "ALT", "ARL", "AVS", "BBC", "BCH", "BLACK", "BNBTC", "BTC", "BTRM", "BUT", "CLO", "CLORE", "EGAZ", "EGEM", "ELH", "EPIC", "ETC", "ETHF", "ETHO", "ETHW", "ETI", "ETP", "EVOX", "EVR", "EXP", "FiroPowFIRO", "FITA", "FRENS", "GRAMS", "GSPC", "HVQ", "IRON", "JGC", "KAW", "KCN", "KIIRO", "LAB", "LTR", "MEOW", "MEWC", "NAPI", "NEOX", "NOVO", "OCTA", "PAPRY", "PRCO", "REDE", "RTH", "RTM", "RVN", "RXD", "SATO", "SATOX", "SCC", "SERO", "THOON", "TTM", "UBQ", "VBK", "VEIL", "VKAX", "VTE", "XNA", "YERB", "ZANO", "ZELS", "ZIL", "ZKBTC" -contains $Pool.Currency) { 
                                $Arguments = "$($_.Arguments -replace " -[a|c] \w+") -c $($Pool.Currency)"
                            }
                            else { 
                                $Arguments = $_.Arguments
                            }
                            if ($AvailableMinerDevices.where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace " -intensity [0-9]+" }
                            $Arguments += " -o "
                            switch ($Pool.Protocol) { 
                                "ethstratum1" { $Arguments += "stratum+"; break }
                                "ethstratum2" { $Arguments += "stratum+"; break }
                                "ethstratumnh" { $Arguments += "stratum+"; break }
                                # Default        { $Arguments += "stratum+" }
                            }
                            $Arguments += if ($Pool.PoolPorts[1]) { "ssl://" } else { "tcp://" }
                            $Arguments += "$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) -u $($Pool.User) -p $($Pool.Pass)"
                            if ($Pool.WorkerName) { $Arguments += " -w $($Pool.WorkerName)" }

                            # Allow more time to build larger DAGs, must use type cast to keep values in $_
                            $WarmupTimes = [UInt16[]]$_.WarmupTimes
                            $WarmupTimes[0] += [UInt16]($Pool.DAGsizeGiB * 5)

                            [PSCustomObject]@{ 
                                API         = "EthMiner"
                                Arguments   = "$Arguments -report-average 5 -report-interval 5$(if ($_.Algorithm -match $Session.RegexAlgoHasDAG) { " -daginfo" }) -b 127.0.0.1:$($MinerAPIPort)$(if ($_.Type -eq "CPU") { " -cpu $AvailableMinerDevices.$($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $Session.Config.CPUMiningReserveCPUcore)" } else { " -d $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x2}:00' -f $_ }) -join ',') -cuda-order" })"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = $_.Fee # Dev fee
                                MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = $Type
                                URI         = $URI
                                WarmupTimes = $WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}
