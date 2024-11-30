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
Version:        6.3.18
Version date:   2024/11/30
#>

# TT needs avx2 and aes https://github.com/TrailingStop/TT-Miner-beta/issues/7#issuecomment-2158058291
If (($Variables.CPUfeatures -match "^AES$|^AVX2$").count -ne 2) { Return }
If (-not ($Devices = $Variables.EnabledDevices.Where({ ($_.Type -eq "NVIDIA" -and $_.OpenCL.ComputeCapability -gt "5.0") -or "AMD", "NVIDIA" -contains $_.Type }))) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge [System.Version]"11.0" } { "https://github.com/TrailingStop/TT-Miner-release/releases/download/2024.3.2/TT-Miner-2024.3.2.zip" }
    Default                           { Return }
}
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\TT-Miner.exe"
$DeviceEnumerator = "Type_Index"

$Algorithms = @(
    @{ Algorithm = "Blake3";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a Blake3" }
    @{ Algorithm = "EtcHash";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a EtcHash" }
    @{ Algorithm = "Ethash";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.00; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a Ethash" }
    @{ Algorithm = "EthashB3";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.00; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a EthashB3" }
    @{ Algorithm = "EvrProPow";        Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a EvrProgPow" }
#   @{ Algorithm = "FiroPow";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a FiroPow" } # https://github.com/TrailingStop/TT-Miner-release/issues/52
    @{ Algorithm = "FishHash";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a fishhash" }
    @{ Algorithm = "KawPow";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(75, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a KawPow" }
#   @{ Algorithm = "MemeHash";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(120, 0); ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a Memehash" } # Not yet working
    @{ Algorithm = "MeowPow";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(120, 0); ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a meowpow" }
    @{ Algorithm = "ProgPowEpic";      Type = "AMD"; Fee = @(0.02); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -c EPIC" }
    @{ Algorithm = "ProgPowSero";      Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -c SERO" }
    @{ Algorithm = "ProgPowVeil";      Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -c VEIL" }
    @{ Algorithm = "ProgPowZ";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -c ZANO" }
    @{ Algorithm = "ProgPowVeriblock"; Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a vProgPow" }
#   @{ Algorithm = "SCCpow";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -c SCC" } # https://github.com/TrailingStop/TT-Miner-release/issues/52
#   @{ Algorithm = "SHA256d";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a SHA256D" } # ASIC
    @{ Algorithm = "SHA256dt";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a SHA256DT" }
    @{ Algorithm = "SHA3D";            Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a Sha3D" }
    @{ Algorithm = "SHA512256d";       Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = @("GCN4"); ExcludePools = @(); Arguments = " -a SHA512256D" }
    @{ Algorithm = "SHA3Solidity";     Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a SHA3SOL" }
    @{ Algorithm = "UbqHash";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @();       ExcludePools = @(); Arguments = " -a UbqHash" }

    @{ Algorithm = "Ghostrider";       Type = "CPU"; Fee = @(0.01); MinerSet = 0; WarmupTimes = @(30, 0); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a Ghostrider" }
    @{ Algorithm = "Flex";             Type = "CPU"; Fee = @(0.01); MinerSet = 0; WarmupTimes = @(30, 0); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a Flex" }
    @{ Algorithm = "SpectreX";         Type = "CPU"; Fee = @(0.01); MinerSet = 1; WarmupTimes = @(60, 0); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a SpectreX" }
    @{ Algorithm = "XelisHash";        Type = "CPU"; Fee = @(0.01); MinerSet = 0; WarmupTimes = @(30, 0); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a Xelis" }

    @{ Algorithm = "Blake3";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a Blake3" }
    @{ Algorithm = "EtcHash";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a EtcHash" }
    @{ Algorithm = "Ethash";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.00; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a Ethash" }
    @{ Algorithm = "EthashB3";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.00; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a EthashB3" }
    @{ Algorithm = "EvrProPow";        Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a EvrProgPow" }
#   @{ Algorithm = "FiroPow";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a FiroPow" } # https://github.com/TrailingStop/TT-Miner-release/issues/52
    @{ Algorithm = "FishHash";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a FishHash" }
#   @{ Algorithm = "Ghostrider";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 3;    MinerSet = 2; WarmupTimes = @(180, 0); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a Ghostrider" } # No hashrates
    @{ Algorithm = "KawPow";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(75, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a KawPow" }
#   @{ Algorithm = "MemeHash";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(120, 0); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a Memehash" } # Not yet working
    @{ Algorithm = "MeowPow";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(120, 0); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a meowpow" }
    @{ Algorithm = "ProgPowEpic";      Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -c EPIC" }
    @{ Algorithm = "ProgPowSero";      Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -c SERO" }
    @{ Algorithm = "ProgPowVeil";      Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -c VEIL" }
    @{ Algorithm = "ProgPowZ";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -c ZANO" }
    @{ Algorithm = "ProgPowVeriblock"; Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a vProgPow" }
#   @{ Algorithm = "SCCpow";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -c SCC" } # https://github.com/TrailingStop/TT-Miner-release/issues/52
#   @{ Algorithm = "SHA256d";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a SHA256D" } # ASIC
    @{ Algorithm = "SHA256dt";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a SHA256DT" }
    @{ Algorithm = "SHA3D";            Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a Sha3D" }
    @{ Algorithm = "SHA512256d";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a SHA512256D" }
    @{ Algorithm = "SHA3Solidity";     Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a SHA3SOL" }
    @{ Algorithm = "UbqHash";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -a UbqHash" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    If ($SupportedMinerDevices = $MinerDevices.Where({ $ExcludeGPUarchitectures -notcontains $_.Architecture })) { 

                        # $ExcludePools = $_.ExcludePools
                        # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name })) { 
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] })) { 

                            $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                            If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                                If ("AKA", "ALPH", "ALT", "ARL", "AVS", "BBC", "BCH", "BLACK", "BNBTC", "BTC", "BTRM", "BUT", "CLO", "CLORE", "EGAZ", "EGEM", "ELH", "EPIC", "ETC", "ETHF", "ETHO", "ETHW", "ETI", "ETP", "EVOX", "EVR", "EXP", "FiroPowFIRO", "FITA", "FRENS", "GRAMS", "GSPC", "HVQ", "IRON", "JGC", "KAW", "KCN", "KIIRO", "LAB", "LTR", "MEOW", "MEWC", "NAPI", "NEOX", "NOVO", "OCTA", "PAPRY", "PRCO", "REDE", "RTH", "RTM", "RVN", "RXD", "SATO", "SATOX", "SCC", "SERO", "THOON", "TTM", "UBQ", "VBK", "VEIL", "VKAX", "VTE", "XNA", "YERB", "ZANO", "ZELS", "ZIL", "ZKBTC" -contains $Pool.Currency) { 
                                    $Arguments = "$($_.Arguments -replace ' -[a|c] \w+') -c $($Pool.Currency)"
                                }
                                Else { 
                                    $Arguments = $_.Arguments
                                }
                                If ($AvailableMinerDevices.Where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace " -intensity [0-9]+" }
                                $Arguments += " -o "
                                Switch ($Pool.Protocol) { 
                                    "ethstratum1"  { $Arguments += "stratum+" }
                                    "ethstratum2"  { $Arguments += "stratum+" }
                                    "ethstratumnh" { $Arguments += "stratum+" }
                                    # Default        { $Arguments += "stratum+" }
                                }
                                $Arguments += "$(If ($Pool.PoolPorts[1]) { "ssl://" } Else { "tcp://" })$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1)"
                                $Arguments += " -u $($Pool.User)"
                                If ($Pool.Pass) { $Arguments += " -p $($Pool.Pass)" }
                                If ($Pool.WorkerName) { $Arguments += " -w $($Pool.WorkerName)" }

                                # Allow more time to build larger DAGs, must use type cast to keep values in $_
                                $WarmupTimes = [UInt16[]]$_.WarmupTimes
                                $WarmupTimes[0] += [UInt16]($Pool.DAGSizeGiB * 5)

                                [PSCustomObject]@{ 
                                    API         = "EthMiner"
                                    Arguments   = "$Arguments -report-average 5 -report-interval 5$(If ($_.Algorithm -match $Variables.RegexAlgoHasDAG) { " -daginfo" }) -b 127.0.0.1:$($MinerAPIPort)$(If ($_.Type -eq "CPU") { " -cpu $AvailableMinerDevices.$($AvailableMinerDevices.CIM.NumberOfLogicalProcessors -$($Config.CPUMiningReserveCPUcore))" } Else { " -d $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')" })"
                                    DeviceNames = $AvailableMinerDevices.Name
                                    Fee         = $_.Fee # Dev fee
                                    MinerSet    = $_.MinerSet
                                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                    Name        = $MinerName
                                    Path        = $Path
                                    Port        = $MinerAPIPort
                                    Type        = $_.Type
                                    URI         = $URI
                                    WarmupTimes = $WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                    Workers     = @(@{ Pool = $Pool })
                                }
                            }
                        }
                    }
                }
            )
        }
    )
}
