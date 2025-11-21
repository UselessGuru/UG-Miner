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
Version:        6.6.7
Version date:   2024/01/29
#>

If (-not ($Devices = $Session.EnabledDevices.Where({ $_.Type -eq "AMD" -or ($_.OpenCL.ComputeCapability -ge "6.0" -and $_.CUDAVersion -ge [Version]"10.0") }))) { Return }

$URI = "https://github.com/NebuTech/NBMiner/releases/download/v42.3/NBMiner_42.3_Win.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\nbminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithm = "Autolykos2"; Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @("NiceHash"); Arguments = " --algo ergo --platform 2" }
    @{ Algorithm = "EtcHash";    Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinerSet = 1; WarmupTimes = @(30, 35); ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo etchash --platform 2 -enable-dag-cache" } # PhoenixMiner-v6.2c is fastest
    @{ Algorithm = "Ethash";     Type = "AMD"; Fee = @(0.01); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinerSet = 2; WarmupTimes = @(30, 35); ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo ethash --platform 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithm = "KawPow";     Type = "AMD"; Fee = @(0.02); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinerSet = 2; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @( );          Arguments = " --algo kawpow --platform 2" } # XmRig-v6.24.0 is almost as fast but has no fee
 
    @{ Algorithm = "BeamV3";     Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 3;    AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 0; Tuning = " -mt 1"; WarmupTimes = @(30, 40); ExcludeGPUarchitectures = "^Ampere$"; ExcludePools = @("NiceHash"); Arguments = " --algo beamv3 --platform 1" }
    @{ Algorithm = "Cuckoo29";   Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 5;    AdditionalWin10MemGB = 1; MinComputeCapability = 6.0; MinerSet = 1; Tuning = " -mt 1"; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";        ExcludePools = @();           Arguments = " --algo cuckoo_ae --platform 1" } # GMiner-v3.44 is fastest
    @{ Algorithm = "Autolykos2"; Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 1; Tuning = " -mt 1"; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = "^Ampere$"; ExcludePools = @();           Arguments = " --algo ergo --platform 1" }
    @{ Algorithm = "EtcHash";    Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 2; Tuning = " -mt 1"; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";        ExcludePools = @();           Arguments = " --algo etchash --platform 1 --enable-dag-cache" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithm = "Ethash";     Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 2; Tuning = " -mt 1"; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";        ExcludePools = @();           Arguments = " --algo ethash --platform 1 --enable-dag-cache" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    @{ Algorithm = "KawPow";     Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 1.20; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 2; Tuning = " -mt 1"; WarmupTimes = @(30, 10); ExcludeGPUarchitectures = " ";        ExcludePools = @();           Arguments = " --algo kawpow --platform 1" } # XmRig-v6.24.0 is almost as fast but has no fee
    @{ Algorithm = "Octopus";    Type = "NVIDIA"; Fee = @(0.03); MinMemGiB = 1.20; AdditionalWin10MemGB = 1; MinComputeCapability = 6.1; MinerSet = 2; Tuning = " -mt 1"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = "^Ampere$"; ExcludePools = @();           Arguments = " --algo octopus --platform 1" } # Trex-v0.26.8 is fastest
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Session.Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    $MinComputeCapability = $_.MinComputeCapability
                    If ($SupportedMinerDevices = $MinerDevices.Where({ [Double]$_.OpenCL.ComputeCapability -ge $MinComputeCapability -and $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        $ExcludePools = $_.ExcludePools
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 

                            $MinMemGiB = $_.MinMemGiB + $Pool.DAGsizeGiB
                            # Windows 10 requires more memory on some algos
                            If ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGiB += $_.AdditionalWin10MemGB }

                            If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                                $Arguments = $_.Arguments
                                Switch ($Pool.Protocol) { 
                                    "ethstratum1"  { $Arguments += " --url stratum"; Break }
                                    "ethstratum2"  { $Arguments += " --url nicehash"; Break }
                                    "ethstratumnh" { $Arguments += " --url nicehash"; Break }
                                    Default        { $Arguments += " --url stratum" }
                                }
                                $Arguments += If ($Pool.PoolPorts[1]) { "+ssl://" } Else  { "+tcp://" }
                                $Arguments += "$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --password $($Pool.Pass)"

                                # Optionally disable dev fee mining
                                If ($Session.Config.DisableMinerFee) { 
                                    $_.Fee = 0
                                    $Arguments += " --fee 0"
                                }

                                # Allow more time to build larger DAGs, must use type cast to keep values in $_
                                $WarmupTimes = [UInt16[]]$_.WarmupTimes
                                $WarmupTimes[0] += [UInt16]($Pool.DAGsizeGiB * 2)

                                # Apply tuning parameters
                                If ($Session.ApplyMinerTweaks) { $_.Arguments += $_.Tuning }

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
                                    Type        = $Type
                                    URI         = $URI
                                    WarmupTimes = $WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                    Workers      = @(@{ Pool = $Pool })
                                }
                            }
                        }
                    }
                }
            )
        }
    )
}