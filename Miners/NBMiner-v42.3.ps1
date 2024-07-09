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
Version:        6.2.16
Version date:   2024/07/09
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.CUDAVersion -ge [Version]"10.0") }))) { Return }

$URI = "https://github.com/NebuTech/NBMiner/releases/download/v42.3/NBMiner_42.3_Win.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\nbminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithm = "Autolykos2"; Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinerSet = 0; WarmupTimes = @(30, 0);  ExcludePools = @(); Arguments = " --algo ergo --platform 2" }
    @{ Algorithm = "EtcHash";    Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinerSet = 1; WarmupTimes = @(30, 35); ExcludePools = @(); Arguments = " --algo etchash --platform 2 -enable-dag-cache" } # PhoenixMiner-v6.2c is fastest
    @{ Algorithm = "Ethash";     Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinerSet = 2; WarmupTimes = @(30, 35); ExcludePools = @(); Arguments = " --algo ethash --platform 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithm = "KawPow";     Type = "AMD"; Fee = @(0.02); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @(); Arguments = " --algo kawpow --platform 2" } # XmRig-v6.17.0 is almost as fast but has no fee
 
    @{ Algorithm = "BeamV3";     Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 3;    AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 0; Tuning = " -mt 1"; WarmupTimes = @(30, 40); ExcludePools = @("NiceHash"); Arguments = " --algo beamv3 --platform 1" }
    @{ Algorithm = "Cuckoo29";   Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 5;    AdditionalWin10MemGB = 1; MinComputeCapability = 6.0; MinerSet = 1; Tuning = " -mt 1"; WarmupTimes = @(30, 30); ExcludePools = @();           Arguments = " --algo cuckoo_ae --platform 1" } # GMiner-v3.44 is fastest
    @{ Algorithm = "Autolykos2"; Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 1; Tuning = " -mt 1"; WarmupTimes = @(30, 0);  ExcludePools = @();           Arguments = " --algo ergo --platform 1" }
    @{ Algorithm = "EtcHash";    Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 2; Tuning = " -mt 1"; WarmupTimes = @(30, 0);  ExcludePools = @();           Arguments = " --algo etchash --platform 1 --enable-dag-cache" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithm = "Ethash";     Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 2; Tuning = " -mt 1"; WarmupTimes = @(30, 0);  ExcludePools = @();           Arguments = " --algo ethash --platform 1 --enable-dag-cache" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithm = "KawPow";     Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 2; Tuning = " -mt 1"; WarmupTimes = @(30, 10); ExcludePools = @();           Arguments = " --algo kawpow --platform 1" } # XmRig-v6.17.0 is almost as fast but has no fee
    @{ Algorithm = "Octopus";    Type = "NVIDIA"; Fee = @(0.03); MinMemGiB = 1.20; AdditionalWin10MemGB = 1; MinComputeCapability = 6.1; MinerSet = 2; Tuning = " -mt 1"; WarmupTimes = @(45, 0);  ExcludePools = @();           Arguments = " --algo octopus --platform 1" } # Trex-v0.26.8 is fastest
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })

If ($Algorithms) { 

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            If ($MinerDevices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model) { 
                $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

                ($Algorithms | Where-Object Type -EQ $_.Type).ForEach(
                    { 
                        $MinComputeCapability = $_.MinComputeCapability
                        If ($SupportedMinerDevices = $MinerDevices.Where({ [Double]$_.OpenCL.ComputeCapability -ge $MinComputeCapability })) { 

                            # $ExcludePools = $_.ExcludePools
                            # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.Name -notin $ExcludePools })) { 
                            ForEach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                                $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                                # Windows 10 requires more memory on some algos
                                If ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGiB += $_.AdditionalWin10MemGB }
                                If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($Pool.AlgorithmVariant)"

                                    $Arguments = $_.Arguments
                                    $Arguments += Switch ($Pool.Protocol) { 
                                        "ethstratum1"  { " --url stratum" }
                                        "ethstratum2"  { " --url nicehash" }
                                        "ethstratumnh" { " --url nicehash" }
                                        Default        { " --url stratum" }
                                    }
                                    $Arguments += If ($Pool.PoolPorts[1]) { "+ssl://" } Else  { "+tcp://" }
                                    $Arguments += "$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User)"
                                    $Arguments += " --password $($Pool.Pass)"

                                    # Optionally disable dev fee mining
                                    If ($Config.DisableMinerFee) { 
                                        $_.Fee = 0
                                        $Arguments += " --fee 0"
                                    }

                                    # Allow more time to build larger DAGs, must use type cast to keep values from $_
                                    $WarmupTimes = [Int[]]$_.WarmupTimes
                                    $WarmupTimes[0] += [Int](($Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB) * 5)

                                    # Apply tuning parameters
                                    If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                                    [PSCustomObject]@{ 
                                        API         = "NBMiner"
                                        Arguments   = "$Arguments --no-watchdog --api 127.0.0.1:$($MinerAPIPort) --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
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
        }
    )
}