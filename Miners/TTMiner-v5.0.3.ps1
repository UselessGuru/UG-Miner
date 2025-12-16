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
Version:        6.7.10
Version date:   2025/12/16
#>

if (-not ($Devices = $Session.EnabledDevices.where({ $_.OpenCL.ComputeCapability -ge "5.0" }))) { return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/TT-Miner/ttminer503.7z"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\TT-Miner.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
#   @{ Algorithm = "Eaglesong";    MinMemGiB = 2;    WarmupTimes = @(30, 60); ExcludePools = @(); Arguments = " -algo EAGLESONG" } # ASIC
    @{ Algorithm = "Ethash";       MinMemGiB = 1.22; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " -algo ETHASH -intensity 15" }
    @{ Algorithm = "KawPow";       MinMemGiB = 1.22; WarmupTimes = @(90, 60); ExcludePools = @(); Arguments = " -algo KAWPOW" }
#   @{ Algorithm = "Lyra2RE3";     MinMemGiB = 2;    WarmupTimes = @(30, 60); ExcludePools = @(); Arguments = " -algo LYRA2V3" } # ASIC
#   @{ Algorithm = "MTP";          MinMemGiB = 3;    WarmupTimes = @(30, 60); ExcludePools = @(); Arguments = " -algo MTP -intensity 21" } # Algorithm is dead
    @{ Algorithm = "ProgPowEpic";  MinMemGiB = 1.22; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " -coin EPIC" }
    @{ Algorithm = "ProgPowSero";  MinMemGiB = 1.22; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " -coin SERO" }
    @{ Algorithm = "ProgPowVeil";  MinMemGiB = 1.22; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " -coin VEIL" }
    @{ Algorithm = "ProgPowZ";     MinMemGiB = 1.22; WarmupTimes = @(60, 60); ExcludePools = @(); Arguments = " -coin ZANO" }
    @{ Algorithm = "UbqHash";      MinMemGiB = 1.22; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " -algo UBQHASH -intensity 15" }
)

$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })
$Algorithms = $Algorithms.where({ $_.Algorithm -ne "Ethash" -or $MinerPools[0][$_.Algorithm].Epoch -le 384 }) # Miner supports Ethash up to epoch 384
$Algorithms = $Algorithms.where({ $_.Algorithm -ne "EtcHash" -or $MinerPools[0][$_.Algorithm].Epoch -lt 383 }) # Miner supports EtcHash up to epoch 382
$Algorithms = $Algorithms.where({ $_.Algorithm -ne "KawPow" -or $MinerPools[0][$_.Algorithm].DAGsizeGiB -lt "4" }) # Miner supports Kawpow up to 4GB

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.where({ $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.ForEach(
                { 
                    # $ExcludePools = $_.ExcludePools
                    # foreach ($Pool in $MinerPools[0][$_.Algorithm].where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name -and $_.Algorithm -notin @("Ethash", "KawPow") -or (<# Miner supports Ethash up to epoch 384 #>$_.Algorithm -eq "Ethash" -and $_.Epoch -le 384) -or (<# Miner supports Kawpow up to 4GB #>$_.Algorithm -eq "KawPow" -and $_.DAGsizeGiB -lt 4) })) { 
                    foreach ($Pool in $MinerPools[0][$_.Algorithm].where({ $_.PoolPorts[0] -and "Ethash", "KawPow" -notcontains $_.Algorithm -or (<# Miner supports Ethash up to epoch 384 #>$_.Algorithm -eq "Ethash" -and $_.Epoch -le 384) -or (<# Miner supports Kawpow up to 4GB #>$_.Algorithm -eq "KawPow" -and $_.DAGsizeGiB -lt 4) })) { 

                        $MinMemGiB = $_.MinMemGiB + $Pool.DAGsizeGiB
                        if ($AvailableMinerDevices = $MinerDevices.where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                            $Arguments = $_.Arguments
                            if ("CLO", "ETC", "ETH", "ETP", "EXP", "MUSIC", "PIRL", "RVN", "TCR", "UBQ", "VBK", "ZCOIN", "ZELS" -contains $Pool.Currency) { 
                                $Arguments = " -coin $($Pool.Currency)$($_.Arguments -replace " -algo \w+")"
                            }
                            if ($AvailableMinerDevices.where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace " -intensity [0-9]+" }

                            $Arguments += if ($Pool.Protocol -like "ethproxy*" -or $_.Algorithm -eq "ProgPowZ") { " -pool stratum1+tcp://" } else { " -pool stratum+tcp://" }
                            $Arguments += "$($Pool.Host):$($Pool.PoolPorts[0]) -user $($Pool.User) -pass $($Pool.Pass)"
                            if ($Pool.WorkerName) { $Arguments += " -worker $($Pool.WorkerName)" }

                            [PSCustomObject]@{ 
                                API         = "EthMiner"
                                Arguments   = "$Arguments -PRT 1 -PRS 0 -api-bind 127.0.0.1:$($MinerAPIPort) -device $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ",")"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = @(0) # Dev fee
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = "NVIDIA"
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