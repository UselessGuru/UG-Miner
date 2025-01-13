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
Version:        6.4.1
Version date:   2025/01/13
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/TT-Miner/ttminer503.7z"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\TT-Miner.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
#   @{ Algorithm = "Eaglesong";    MinMemGiB = 2;    MinerSet = 3; WarmupTimes = @(30, 60); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -algo EAGLESONG" } # ASIC
    @{ Algorithm = "Ethash";       MinMemGiB = 1.22; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -algo ETHASH -intensity 15" }
    @{ Algorithm = "KawPow";       MinMemGiB = 1.22; MinerSet = 2; WarmupTimes = @(90, 60); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -algo KAWPOW" }
#   @{ Algorithm = "Lyra2RE3";     MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 60); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -algo LYRA2V3" } # ASIC
#   @{ Algorithm = "MTP";          MinMemGiB = 3;    MinerSet = 2; WarmupTimes = @(30, 60); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -algo MTP -intensity 21" } # Algorithm is dead
    @{ Algorithm = "ProgPowEpic";  MinMemGiB = 1.22; MinerSet = 2; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -coin EPIC" }
    @{ Algorithm = "ProgPowSero";  MinMemGiB = 1.22; MinerSet = 2; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -coin SERO" }
    @{ Algorithm = "ProgPowVeil";  MinMemGiB = 1.22; MinerSet = 2; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -coin VEIL" }
    @{ Algorithm = "ProgPowZ";     MinMemGiB = 1.22; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -coin ZANO" }
    @{ Algorithm = "UbqHash";      MinMemGiB = 1.22; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @(); ExcludePools = @(); Arguments = " -algo UBQHASH -intensity 15" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })
$Algorithms = $Algorithms.Where({ $_.Algorithm -ne "Ethash" -or $MinerPools[0][$_.Algorithm].Epoch -le 384 }) # Miner supports Ethash up to epoch 384
$Algorithms = $Algorithms.Where({ $_.Algorithm -ne "KawPow" -or $MinerPools[0][$_.Algorithm].DAGSizeGiB -lt "4" }) # Miner supports Kawpow up to 4GB

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    # $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    If ($SupportedMinerDevices = $MinerDevices) { 
                    # If ($SupportedMinerDevices = $MinerDevices.Where({ $ExcludeGPUarchitectures -notcontains $_.Architecture })) { 

                        # $ExcludePools = $_.ExcludePools
                        # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $ExcludePools -notcontains $_.Name -and $_.Algorithm -notin @("Ethash", "KawPow") -or (<# Miner supports Ethash up to epoch 384 #>$_.Algorithm -eq "Ethash" -and $_.Epoch -le 384) -or (<# Miner supports Kawpow up to 4GB #>$_.Algorithm -eq "KawPow" -and $_.DAGSizeGiB -lt 4) })) { 
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and "Ethash", "KawPow" -notcontains $_.Algorithm -or (<# Miner supports Ethash up to epoch 384 #>$_.Algorithm -eq "Ethash" -and $_.Epoch -le 384) -or (<# Miner supports Kawpow up to 4GB #>$_.Algorithm -eq "KawPow" -and $_.DAGSizeGiB -lt 4) })) { 

                            $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                            If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                                $Arguments = $_.Arguments
                                If ("CLO", "ETC", "ETH", "ETP", "EXP", "MUSIC", "PIRL", "RVN", "TCR", "UBQ", "VBK", "ZANO", "ZCOIN", "ZELS" -contains $Pool.Currency) { 
                                    $Arguments = " -coin $($Pool.Currency)$($_.Arguments -replace ' -algo \w+')"
                                }
                                If ($AvailableMinerDevices.Where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace " -intensity [0-9]+" }

                                $Arguments += If ($Pool.Protocol -like "ethproxy*" -or $_.Algorithm -eq "ProgPowZ") { " -pool stratum1+tcp://" } Else { " -pool stratum+tcp://" }
                                $Arguments += "$($Pool.Host):$($Pool.PoolPorts[0]) -user $($Pool.User)"
                                If ($Pool.WorkerName) { $Arguments += " -worker $($Pool.WorkerName)" }
                                $Arguments += " -pass $($Pool.Pass)"

                                [PSCustomObject]@{ 
                                    API         = "EthMiner"
                                    Arguments   = "$Arguments -PRT 1 -PRS 0 -api-bind 127.0.0.1:$($MinerAPIPort) -device $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                    DeviceNames = $AvailableMinerDevices.Name
                                    Fee         = @(0) # Dev fee
                                    MinerSet    = $_.MinerSet
                                    Name        = $MinerName
                                    Path        = $Path
                                    Port        = $MinerAPIPort
                                    Type        = "NVIDIA"
                                    URI         = $URI
                                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
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