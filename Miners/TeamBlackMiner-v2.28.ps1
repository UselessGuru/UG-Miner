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
Version:        6.7.9
Version date:   2025/12/15
#>

# V2.28 produces nothing but bad shares with kapwow, use v.26 instead
# Improved support for the NVIDIA 5xxx series
# The miner exits faster. From 5 seconds to less than 1 second. (faster algo profit switching)

if (-not ($Devices = $Session.EnabledDevices.where({ $_.Type -eq "AMD" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.CUDAversion -ge [System.Version]"12.6") }))) { return }

$URI = "https://github.com/sp-hash/TeamBlackMiner/releases/download/v2.28/TeamBlackMiner_2_28_cuda_12_8.7z"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\TBMiner.exe"

$DeviceSelector = @{ AMD = " --cl-devices"; NVIDIA = " --cuda-devices" }
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithms = @("EtcHash", "");            SecondaryAlgorithmPrefix = "";      Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = ""; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo etchash" }
    @{ Algorithms = @("EtcHash", "EthashB3");    SecondaryAlgorithmPrefix = "ethb3"; Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = "^RDNA2$"; ExcludePools = @(@(), @()); Arguments = " --algo etc+ethb3" }
    @{ Algorithms = @("EtcHash", "EvrProgPow");  SecondaryAlgorithmPrefix = "evr";   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo etc+evr" }
    @{ Algorithms = @("EtcHash", "FiroPow");     SecondaryAlgorithmPrefix = "firo";  Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo etc+firo" }
#   @{ Algorithms = @("EtcHash", "KawPow");      SecondaryAlgorithmPrefix = "rvn";   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo etc+rvn" } # Invalid shares with Kawpow, use 2.26 instead
    @{ Algorithms = @("EtcHash", "MeowPow");     SecondaryAlgorithmPrefix = "meow";  Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo etc+meow" }
    @{ Algorithms = @("EtcHash", "VertHash");    SecondaryAlgorithmPrefix = "vtc";   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo etc+vtc --verthash-data ..\.$($Session.VertHashDatPath)" } # 120 Seconds; https://github.com/sp-hash/TeamBlackMiner/issues/450
    @{ Algorithms = @("Ethash", "");             SecondaryAlgorithmPrefix = "";      Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = ""; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo ethash" }
#   @{ Algorithms = @("Ethash", "EthashB3");     SecondaryAlgorithmPrefix = "ethb3"; Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = "^RDNA2$"; ExcludePools = @(@(), @()); Arguments = " --algo eth+ethb3" } # https://github.com/sp-hash/TeamBlackMiner/issues/459
    @{ Algorithms = @("Ethash", "EvrProgPow");   SecondaryAlgorithmPrefix = "evr";   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo eth+evr" }
    @{ Algorithms = @("Ethash", "FiroPow");      SecondaryAlgorithmPrefix = "firo";  Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo eth+firo" }
#   @{ Algorithms = @("Ethash", "KawPow");       SecondaryAlgorithmPrefix = "rvn";   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo eth+rvn" } # Invalid shares with Kawpow, use 2.26 instead
    @{ Algorithms = @("Ethash", "MeowPow");      SecondaryAlgorithmPrefix = "meow";  Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo eth+meow" }
    @{ Algorithms = @("Ethash", "VertHash");     SecondaryAlgorithmPrefix = "vtc";   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo eth+vtc --verthash-data ..\.$($Session.VertHashDatPath)" } # 120 Secs; https://github.com/sp-hash/TeamBlackMiner/issues/450
    @{ Algorithms = @("EthashB3", "");           SecondaryAlgorithmPrefix = "";      Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = ""; WarmupTimes = @(20, 15); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo ethashb3" }
    @{ Algorithms = @("EthashB3", "FiroPow");    SecondaryAlgorithmPrefix = "firo";  Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(20, 30); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo ethb3+firo" }
    @{ Algorithms = @("EthashB3", "EvrProgPow"); SecondaryAlgorithmPrefix = "evr";   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(20, 30); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo ethb3+evr" }
#   @{ Algorithms = @("EthashB3", "KawPow");     SecondaryAlgorithmPrefix = "rvn";   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(20, 45); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo ethb3+rvn" } # Invalid shares with Kawpow, use 2.26 instead
    @{ Algorithms = @("EthashB3", "MeowPow");    SecondaryAlgorithmPrefix = "meow";  Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(20, 45); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo ethb3+meow" }
    @{ Algorithms = @("EthashB3", "VertHash");   SecondaryAlgorithmPrefix = "vtc";   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Tuning = ""; WarmupTimes = @(20, 30); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo ethb3+vtc --verthash-data ..\.$($Session.VertHashDatPath)" } # 120 Seconds; https://github.com/sp-hash/TeamBlackMiner/issues/450
    @{ Algorithms = @("EvrProgPow", "");         SecondaryAlgorithmPrefix = "";      Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = ""; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo evrprogpow" }
    @{ Algorithms = @("FiroPow", "");            SecondaryAlgorithmPrefix = "";      Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = ""; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo firopow" }
#   @{ Algorithms = @("KawPow", "");             SecondaryAlgorithmPrefix = "";      Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = ""; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo kawpow" } # Invalid shares with Kawpow, use 2.26 instead
    @{ Algorithms = @("MeowPow", "");            SecondaryAlgorithmPrefix = "";      Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = ""; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo meowpow" }
    @{ Algorithms = @("VertHash", "");           SecondaryAlgorithmPrefix = "";      Type = "AMD"; Fee = @(0.005);        MinMemGiB = 3.0;  Tuning = ""; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " ";       ExcludePools = @(@(), @()); Arguments = " --algo verthash --verthash-data ..\.$($Session.VertHashDatPath)" }
 
    @{ Algorithms = @("EtcHash", "");            SecondaryAlgorithmPrefix = "";      Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = " --tweak 2"; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo etchash" }
#   @{ Algorithms = @("EtcHash", "EthashB3");    SecondaryAlgorithmPrefix = "ethb3"; Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo etc+ethb3" }
    @{ Algorithms = @("EtcHash", "EvrProgPow");  SecondaryAlgorithmPrefix = "evr";   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo etc+evr" }
    @{ Algorithms = @("EtcHash", "FiroPow");     SecondaryAlgorithmPrefix = "firo";  Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo etc+firo" }
#   @{ Algorithms = @("EtcHash", "KawPow");      SecondaryAlgorithmPrefix = "rvn";   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo etc+rvn" } # Invalid shares with Kawpow, use 2.26 instead
    @{ Algorithms = @("EtcHash", "MeowPow");     SecondaryAlgorithmPrefix = "meow";  Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo etc+meow" }
    @{ Algorithms = @("EtcHash", "VertHash");    SecondaryAlgorithmPrefix = "vtc";   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo etc+vtc --verthash-data ..\.$($Session.VertHashDatPath)" }
    @{ Algorithms = @("Ethash", "");             SecondaryAlgorithmPrefix = "";      Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = " --tweak 2"; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo ethash" }
    @{ Algorithms = @("Ethash", "EthashB3");     SecondaryAlgorithmPrefix = "ethb3"; Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo eth+ethb3" }
    @{ Algorithms = @("Ethash", "EvrProgPow");   SecondaryAlgorithmPrefix = "evr";   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo eth+evr" }
    @{ Algorithms = @("Ethash", "FiroPow");      SecondaryAlgorithmPrefix = "firo";  Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo eth+firo" }
#   @{ Algorithms = @("Ethash", "KawPow");       SecondaryAlgorithmPrefix = "rvn";   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo eth+rvn" } # Invalid shares with Kawpow, use 2.26 instead
    @{ Algorithms = @("Ethash", "MeowPow");      SecondaryAlgorithmPrefix = "meow";  Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo eth+meow" }
    @{ Algorithms = @("Ethash", "VertHash");     SecondaryAlgorithmPrefix = "vtc";   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo eth+vtc --verthash-data ..\.$($Session.VertHashDatPath)" }
    @{ Algorithms = @("EthashB3", "");           SecondaryAlgorithmPrefix = "";      Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = " --tweak 2"; WarmupTimes = @(20, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo ethashb3" }
    @{ Algorithms = @("EthashB3", "EvrProgPow"); SecondaryAlgorithmPrefix = "evr";   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(20, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo ethb3+evr" }
    @{ Algorithms = @("EthashB3", "FiroPow");    SecondaryAlgorithmPrefix = "firo";  Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(20, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo ethb3+firo" }
#   @{ Algorithms = @("EthashB3", "KawPow");     SecondaryAlgorithmPrefix = "rvn";   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(20, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo ethb3+rvn" } # Invalid shares with Kawpow, use 2.26 instead
    @{ Algorithms = @("EthashB3", "MeowPow");    SecondaryAlgorithmPrefix = "meow";  Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(20, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo ethb3+meow" }
    @{ Algorithms = @("EthashB3", "VertHash");   SecondaryAlgorithmPrefix = "vtc";   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Tuning = " --tweak 2"; WarmupTimes = @(20, 45); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo ethb3+vtc --verthash-data ..\.$($Session.VertHashDatPath)" }
    @{ Algorithms = @("EvrProgPow", "");         SecondaryAlgorithmPrefix = "";      Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = " --tweak 2"; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo evrprogpow" }
    @{ Algorithms = @("FiroPow", "");            SecondaryAlgorithmPrefix = "";      Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = " --tweak 2"; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo firopow" }
#   @{ Algorithms = @("KawPow", "");             SecondaryAlgorithmPrefix = "";      Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = " --tweak 2"; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo kawpow" } # Invalid shares with Kawpow, use 2.26 instead
    @{ Algorithms = @("MeowPow", "");            SecondaryAlgorithmPrefix = "";      Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Tuning = " --tweak 2"; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo meowpow" }
    @{ Algorithms = @("VertHash", "");           SecondaryAlgorithmPrefix = "";      Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 3.0;  Tuning = " --tweak 2"; WarmupTimes = @(30, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = " --algo verthash --verthash-data ..\.$($Session.VertHashDatPath)" }
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
                                        if ($Pool0.Pass) { $Arguments += " --server-passwd $($Pool0.Pass)" }

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