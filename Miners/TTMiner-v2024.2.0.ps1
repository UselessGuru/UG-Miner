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
Version:        6.2.13
Version date:   2024/06/30
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ ($_.Type -eq "NVIDIA" -and $_.OpenCL.ComputeCapability -gt "5.0") -or $_.Type -eq "AMD" } ))) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.0" } { "https://github.com/TrailingStop/TT-Miner-release/releases/download/2024.2.0/TT-Miner-2024.2.0.zip" }
    Default           { Return }
}
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\TT-Miner.exe"
$DeviceEnumerator = "Type_Index"

$Algorithms = @(
#     [PSCustomObject]@{ Algorithm = "Blake3";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Blake3" }
#     [PSCustomObject]@{ Algorithm = "EtcHash";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a EtcHash" }
#     [PSCustomObject]@{ Algorithm = "Ethash";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.00; MinerSet = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Ethash" }
#     [PSCustomObject]@{ Algorithm = "EthashB3";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.00; MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a EthashB3" }
#     [PSCustomObject]@{ Algorithm = "EvrProPow";        Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a EvrProgPow" }
#     [PSCustomObject]@{ Algorithm = "FiroPow";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a FiroPow" }
#     [PSCustomObject]@{ Algorithm = "FiroPowSCC";       Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c SCC" }
#     [PSCustomObject]@{ Algorithm = "FishHash";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 4;    MinerSet = 2; WarmupTimes = @(30, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a FishHash" }
#     [PSCustomObject]@{ Algorithm = "KawPow";           Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(90, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a KawPow" }
# #   [PSCustomObject]@{ Algorithm = "MemeHash";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(120, 30); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Memehash" } # Not yet working
#     [PSCustomObject]@{ Algorithm = "MeowPow";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(120, 30); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a meowpow" }
#     [PSCustomObject]@{ Algorithm = "ProgPowEpic";      Type = "AMD"; Fee = @(0.02); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c EPIC" }
#     [PSCustomObject]@{ Algorithm = "ProgPowSero";      Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c SERO" }
#     [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c VEIL" }
#     [PSCustomObject]@{ Algorithm = "ProgPowZ";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c ZANO" }
#     [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a vProgPow" }
# #   [PSCustomObject]@{ Algorithm = "SHA256d";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA256D" } # ASIC
#     [PSCustomObject]@{ Algorithm = "SHA256dt";         Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA256DT" }
#     [PSCustomObject]@{ Algorithm = "SHA3D";            Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Sha3D" }
#     [PSCustomObject]@{ Algorithm = "SHA512256d";       Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA512256D" }
#     [PSCustomObject]@{ Algorithm = "SHA3Solidity";     Type = "AMD"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA3SOL" }
#     [PSCustomObject]@{ Algorithm = "UbqHash";          Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a UbqHash" }

    [PSCustomObject]@{ Algorithm = "Blake3";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Blake3" }
    [PSCustomObject]@{ Algorithm = "EtcHash";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a EtcHash" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.00; MinerSet = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Ethash" }
    [PSCustomObject]@{ Algorithm = "EthashB3";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.00; MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a EthashB3" }
    [PSCustomObject]@{ Algorithm = "EvrProPow";        Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a EvrProgPow" }
    [PSCustomObject]@{ Algorithm = "FiroPow";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a FiroPow" }
    [PSCustomObject]@{ Algorithm = "FiroPowSCC";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c SCC" }
    [PSCustomObject]@{ Algorithm = "FishHash";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 4;    MinerSet = 2; WarmupTimes = @(30, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a FishHash" }
#   [PSCustomObject]@{ Algorithm = "Ghostrider";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 3;    MinerSet = 2; WarmupTimes = @(180, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Ghostrider" } # No hashrate
    [PSCustomObject]@{ Algorithm = "KawPow";           Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(90, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a KawPow" }
#   [PSCustomObject]@{ Algorithm = "MemeHash";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(120, 30); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Memehash" } # Not yet working
    [PSCustomObject]@{ Algorithm = "MeowPow";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(120, 30); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a meowpow" }
    [PSCustomObject]@{ Algorithm = "ProgPowEpic";      Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c EPIC" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c SERO" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c VEIL" }
    [PSCustomObject]@{ Algorithm = "ProgPowZ";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c ZANO" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 2; WarmupTimes = @(60, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a vProgPow" }
#   [PSCustomObject]@{ Algorithm = "SHA256d";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA256D" } # ASIC
    [PSCustomObject]@{ Algorithm = "SHA256dt";         Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA256DT" }
    [PSCustomObject]@{ Algorithm = "SHA3D";            Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Sha3D" }
    [PSCustomObject]@{ Algorithm = "SHA512256d";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA512256D" }
    [PSCustomObject]@{ Algorithm = "SHA3Solidity";     Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1;    MinerSet = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA3SOL" }
    [PSCustomObject]@{ Algorithm = "UbqHash";          Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.24; MinerSet = 1; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a UbqHash" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
# $Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            If ($MinerDevices = $Devices | Where-Object Model -EQ $_.Model) { 
                $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

                ($Algorithms | Where-Object Type -EQ $_.Type).ForEach(
                    { 
                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        If ($SupportedMinerDevices = $MinerDevices.Where({ $_.Architecture -notin $ExcludeGPUArchitecture })) { 

                            # $ExcludePools = $_.ExcludePools
                            # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $_.Name -notin $ExcludePools })) { 
                            ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] })) { 

                                $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                                If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($Pool.AlgorithmVariant)"

                                    If ($Pool.Currency -in @("AKA", "ALPH", "ALT", "ARL", "AVS", "BBC", "BCH", "BLACK", "BNBTC", "BTC", "BTRM", "BUT", "CLO", "CLORE", "EGAZ", "EGEM", "ELH", "EPIC", "ETC", "ETHF", "ETHO", "ETHW", "ETI", "ETP", "EVOX", "EVR", "EXP", "FiroPowFIRO", "FITA", "FRENS", "GRAMS", "GSPC", "HVQ", "IRON", "JGC", "KAW", "KCN", "LAB", "LTR", "MEOW", "MEWC", "NAPI", "NEOX", "NOVO", "OCTA", "PAPRY", "PRCO", "REDE", "RTH", "RTM", "RVN", "RXD", "SATO", "SATOX", "SCC", "SERO", "THOON", "TTM", "UBQ", "VBK", "VEIL", "VKAX", "VTE", "XNA", "YERB", "ZANO", "ZELS", "ZIL", "ZKBTC")) { 
                                        $Arguments = "$($_.Arguments -replace ' -[a|c] \w+') -c $($Pool.Currency)"
                                    }
                                    Else { 
                                        $Arguments = $_.Arguments
                                    }
                                    If ($AvailableMinerDevices.Where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace ' -intensity [0-9\.]+' }

                                    $Arguments += " -o $(If ($Pool.PoolPorts[1]) { "ssl://" } Else { "tcp://" })$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1)"
                                    $Arguments += " -u $($Pool.User)"
                                    If ($Pool.Pass) { $Arguments += " -p $($Pool.Pass)" }
                                    If ($Pool.WorkerName) { $Arguments += " -w $($Pool.WorkerName)" }

                                    [PSCustomObject]@{ 
                                        API         = "EthMiner"
                                        Arguments   = "$Arguments -report-average 5 -report-interval 5$(If ($_.Algorithm -match $Variables.RegexAlgoHasDAG) { " -daginfo" }) -b 127.0.0.1:$($MinerAPIPort) -d $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                        DeviceNames = $AvailableMinerDevices.Name
                                        Fee         = $_.Fee # Dev fee
                                        MinerSet    = $_.MinerSet
                                        MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
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
                    }
                )
            }
        }
    )
}
