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
Version:        6.7.7
Version date:   2025/12/12
#>

# V2.27 produces nothing but bad shares with kapwow, use v2.26 instead

if (-not ($Devices = $Session.EnabledDevices.where({ $_.Type -eq "AMD" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.CUDAversion -ge [System.Version]"12.6") }))) { return }

$URI = "https://github.com/sp-hash/TeamBlackMiner/releases/download/v2.26/TeamBlackMiner_2_26_cuda_12_6.7z"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\TBMiner.exe"

$DeviceSelector = @{ AMD = " --cl-devices"; NVIDIA = " --cuda-devices" }
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithms = @("EtcHash", "KawPow");  SecondaryAlgorithmPrefix = "rvn"; Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo etc+rvn" }
    @{ Algorithms = @("Ethash", "KawPow");   SecondaryAlgorithmPrefix = "rvn"; Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo eth+rvn" }
    @{ Algorithms = @("EthashB3", "KawPow"); SecondaryAlgorithmPrefix = "rvn"; Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(20, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo ethb3+rvn" }
    @{ Algorithms = @("KawPow", "");         SecondaryAlgorithmPrefix = "";    Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = ""; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo kawpow" }
 
    @{ Algorithms = @("EtcHash", "KawPow");  SecondaryAlgorithmPrefix = "rvn"; Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo etc+rvn" }
    @{ Algorithms = @("Ethash", "KawPow");   SecondaryAlgorithmPrefix = "rvn"; Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo eth+rvn" }
    @{ Algorithms = @("EthashB3", "KawPow"); SecondaryAlgorithmPrefix = "rvn"; Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(20, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo ethb3+rvn" }
    @{ Algorithms = @("KawPow", "");         SecondaryAlgorithmPrefix = "";    Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = " --tweak 2"; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo kawpow" }
)

$Algorithms = $Algorithms.where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.where({ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] })

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    if ($SupportedMinerDevices = $MinerDevices.where({ $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        if ($_.Algorithms -contains "VertHash" -and (Get-Item -Path $Session.VertHashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                            $PrerequisitePath = $Session.VertHashDatPath
                            $PrerequisiteURI = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
                        }
                        else { 
                            $PrerequisitePath = ""
                            $PrerequisiteURI = ""
                        }

                        $ExcludePools = $_.ExcludePools
                        foreach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].where({ $ExcludePools[0] -notcontains $_.Name })) { 
                            foreach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].where({ $ExcludePools[1] -notcontains $_.Name })) { 

                                # Dual algorithm mining: Both pools must support same protocol (SSL or non-SSL) :-(
                                if (-not $_.Algorithms[1] -or ($Pool0.PoolPorts[0] -and $Pool1.PoolPorts[0]) -or ($Pool0.PoolPorts[1] -and $Pool1.PoolPorts[1])) { 

                                    $MinMemGiB = $_.MinMemGiB + $Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB
                                    if ($AvailableMinerDevices = $SupportedMinerDevices.where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(if ($Pool1) { "&$($Pool1.AlgorithmVariant)$(if ($_.Intensity) { "-$($_.Intensity)" })"})"

                                        $Arguments = "$($_.Arguments) --hostname $($Pool0.Host) --wallet $($Pool0.User)"
                                        $Arguments += if (($Pool0.PoolPorts[1] -and -not $_.Algorithms[1]) -or ($Pool0.PoolPorts[1] -and $Pool1.PoolPorts[1])) { " --ssl --ssl-verify-none --ssl-port $($Pool0.PoolPorts[1])" } else { " --port $($Pool0.PoolPorts[0])" }
                                        $Arguments += " --server-passwd $($Pool0.Pass)"

                                        if ($_.SecondaryAlgorithmPrefix) { 
                                            $Arguments += " --$($_.SecondaryAlgorithmPrefix)-hostname $($Pool1.Host) --$($_.SecondaryAlgorithmPrefix)-wallet $($Pool1.User) --$($_.SecondaryAlgorithmPrefix)-passwd $($Pool1.Pass)"
                                            $Arguments += if ($Pool0.PoolPorts[1] -and $Pool1.PoolPorts[1]) { " --$($_.SecondaryAlgorithmPrefix)-port $($Pool1.PoolPorts[1])" } else { " --$($_.SecondaryAlgorithmPrefix)-port $($Pool1.PoolPorts[0])" }
                                            if ($_.Intensity) { $Arguments += " --dual-xintensity $($_.Intensity)" }
                                        }

                                        # Allow more time to build larger DAGs, must use type cast to keep values in $_
                                        $WarmupTimes = [UInt16[]]$_.WarmupTimes
                                        $WarmupTimes[0] += [UInt16](($Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB) * 5)

                                        # Apply tuning parameters
                                        if ($Session.ApplyMinerTweaks) { $_.Arguments += $_.Tuning }

                                        [PSCustomObject]@{ 
                                            API              = "TeamBlackMiner"
                                            Arguments        = "$Arguments --api --api-version 1.4 --api-port $MinerAPIPort$($DeviceSelector.($AvailableMinerDevices.Type | Select-Object -Unique)) [$((($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ })) -join ',')]"
                                            DeviceNames      = $AvailableMinerDevices.Name
                                            Fee              = $_.Fee # Dev fee
                                            MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/summary"
                                            Name             = $MinerName
                                            Path             = $Path
                                            Port             = $MinerAPIPort
                                            PrerequisitePath = $PrerequisitePath
                                            PrerequisiteURI  = $PrerequisiteURI
                                            Type             = $Type
                                            URI              = $URI
                                            WarmupTimes      = $WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                            Workers          = @(($Pool0, $Pool1).where({ $_ }).ForEach({ @{ Pool = $_ } }))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            )
        }
    )
}