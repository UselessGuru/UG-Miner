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
Version:        6.4.23
Version date:   2025/04/10
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.CUDAversion -ge [System.Version]"11.6" -and $_.CUDAversion -lt [System.Version]"12.6" }))) { Return }

$URI = "https://github.com/sp-hash/TeamBlackMiner/releases/download/v2.25/TeamBlackMiner_2_25_cuda_12_2.7z"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\TBMiner.exe"

$DeviceSelector = @{ AMD = " --cl-devices"; NVIDIA = " --cuda-devices" }
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithms = @("EtcHash", "");            Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15);  ExcludePools = @(@(), @());                             Arguments = " --algo etchash" }
    @{ Algorithms = @("EtcHash", "EthashB3");    Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(90, 15);  ExcludePools = @(@(), @());                             Arguments = " --algo etc+ethb3" }
    @{ Algorithms = @("EtcHash", "EvrProgPow");  Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(90, 15);  ExcludePools = @(@(), @());                             Arguments = " --algo etc+evr" }
    @{ Algorithms = @("EtcHash", "FiroPow");     Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(90, 45);  ExcludePools = @(@(), @());                             Arguments = " --algo etc+firo" }
    @{ Algorithms = @("EtcHash", "KawPow");      Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(90, 45);  ExcludePools = @(@(), @("HashCryptos", "MiningDutch")); Arguments = " --algo etc+rvn" }
    @{ Algorithms = @("EtcHash", "MeowPow");     Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(90, 45);  ExcludePools = @(@(), @());                             Arguments = " --algo etc+meow" }
    @{ Algorithms = @("EtcHash", "VertHash");    Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(120, 60); ExcludePools = @(@(), @());                             Arguments = " --algo etc+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    @{ Algorithms = @("Ethash", "");             Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15);  ExcludePools = @(@(), @());                             Arguments = " --algo ethash" }
    @{ Algorithms = @("Ethash", "EthashB3");     Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(90, 45);  ExcludePools = @(@(), @());                             Arguments = " --algo eth+ethb3" }
    @{ Algorithms = @("Ethash", "EvrProgPow");   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(90, 45);  ExcludePools = @(@(), @("HashCryptos"));                Arguments = " --algo eth+evr" }
    @{ Algorithms = @("Ethash", "FiroPow");      Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(90, 45);  ExcludePools = @(@(), @());                             Arguments = " --algo eth+firo" }
    @{ Algorithms = @("Ethash", "KawPow");       Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(90, 20);  ExcludePools = @(@(), @("HashCryptos", "MiningDutch")); Arguments = " --algo eth+rvn" }
    @{ Algorithms = @("Ethash", "MeowPow");      Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(90, 20);  ExcludePools = @(@(), @());                             Arguments = " --algo eth+meow" }
    @{ Algorithms = @("Ethash", "VertHash");     Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(120, 45); ExcludePools = @(@(), @());                             Arguments = " --algo eth+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    @{ Algorithms = @("EthashB3", "");           Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(90, 60);  ExcludePools = @(@(), @());                             Arguments = " --algo ethashb3" }
    @{ Algorithms = @("EthashB3", "EvrProgPow"); Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(90, 45);  ExcludePools = @(@(), @());                             Arguments = " --algo ethb3+evr" }
    @{ Algorithms = @("EthashB3", "FiroPow");    Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(90, 45);  ExcludePools = @(@(), @());                             Arguments = " --algo ethb3+firo" }
    @{ Algorithms = @("EthashB3", "KawPow");     Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(90, 45);  ExcludePools = @(@(), @("HashCryptos", "MiningDutch")); Arguments = " --algo ethb3+rvn" }
    @{ Algorithms = @("EthashB3", "MeowPow");    Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(90, 45);  ExcludePools = @(@(), @());                             Arguments = " --algo ethb3+meow" }
    @{ Algorithms = @("EthashB3", "VertHash");   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(120, 45); ExcludePools = @(@(), @());                             Arguments = " --algo ethb3+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    @{ Algorithms = @("EvrProgPow", "");         Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(90, 15);  ExcludePools = @(@(), @());                             Arguments = " --algo evrprogpow" }
    @{ Algorithms = @("FiroPow", "");            Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(90, 30);  ExcludePools = @(@(), @());                             Arguments = " --algo firopow" }
    @{ Algorithms = @("KawPow", "");             Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 30);  ExcludePools = @(@("HashCryptos", "MiningDutch"), @()); Arguments = " --algo kawpow" }
    @{ Algorithms = @("MeowPow", "");            Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; MinerSet = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 30);  ExcludePools = @(@(), @());                             Arguments = " --algo meowpow" }
    @{ Algorithms = @("VertHash", "");           Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 3.0;  MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @());                             Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.Where({ $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    If ($_.Algorithms -contains "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                        $PrerequisitePath = $Variables.VerthashDatPath
                        $PrerequisiteURI = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
                    }
                    Else { 
                        $PrerequisitePath = ""
                        $PrerequisiteURI = ""
                    }

                    $ExcludePools = $_.ExcludePools
                    ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $ExcludePools[0] -notcontains $_.Name })) { 
                        ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $ExcludePools[1] -notcontains $_.Name })) { 

                            # Dual algorithm mining: Both pools must support same protocol (SSL or non-SSL) :-(
                            If (-not $_.Algorithms[1] -or ($Pool0.PoolPorts[0] -and $Pool1.PoolPorts[0]) -or ($Pool0.PoolPorts[1] -and $Pool1.PoolPorts[1])) { 

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                                If ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)$(If ($_.Intensity) { "-$($_.Intensity)" })"})"

                                    $Arguments = $_.Arguments
                                    $Arguments += " --hostname $($Pool0.Host)"
                                    $Arguments += " --wallet $($Pool0.User)"
                                    $Arguments += If (($Pool0.PoolPorts[1] -and -not $_.Algorithms[1]) -or ($Pool0.PoolPorts[1] -and $Pool1.PoolPorts[1])) { " --ssl --ssl-verify-none --ssl-port $($Pool0.PoolPorts[1])" } Else { " --port $($Pool0.PoolPorts[0])" }
                                    If ($Pool0.Pass) { $Arguments += " --server-passwd $($Pool0.Pass)" }

                                    $SecondAlgo = Switch ($_.Algorithms[1]) { 
                                        "EthashB3"   { "ethb3" }
                                        "EvrProgPow" { "evr" }
                                        "FiroPow"    { "firo" }
                                        "KawPow"     { "rvn" }
                                        "MeowPow"    { "meow" }
                                        "VertHash"   { "vtc" }
                                        Default      { "" }
                                    }
                                    If ($SecondAlgo) { 
                                        $Arguments += " --$($SecondAlgo)-hostname $($Pool1.Host) --$($SecondAlgo)-wallet $($Pool1.User) --$($SecondAlgo)-passwd $($Pool1.Pass)"
                                        $Arguments += If ($Pool0.PoolPorts[1] -and $Pool1.PoolPorts[1]) { " --$($SecondAlgo)-port $($Pool1.PoolPorts[1])" } Else { " --$($SecondAlgo)-port $($Pool1.PoolPorts[0])" }
                                        If ($_.Intensity) { $Arguments += " --dual-xintensity $($_.Intensity)" }
                                    }

                                    # Allow more time to build larger DAGs, must use type cast to keep values in $_
                                    $WarmupTimes = [UInt16[]]$_.WarmupTimes
                                    $WarmupTimes[0] += [UInt16](($Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB) * 5)

                                    # Apply tuning parameters
                                    If ($Variables.ApplyMinerTweaks) { $_.Arguments += $_.Tuning }

                                    [PSCustomObject]@{ 
                                        API              = "TeamBlackMiner"
                                        Arguments        = "$Arguments --api --api-version 1.4 --api-port $MinerAPIPort$($DeviceSelector.($AvailableMinerDevices.Type | Select-Object -Unique)) [$((($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ })) -join ',')]"
                                        DeviceNames      = $AvailableMinerDevices.Name
                                        Fee              = $_.Fee # Dev fee
                                        MinerSet         = $_.MinerSet
                                        MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/summary"
                                        Name             = $MinerName
                                        Path             = $Path
                                        Port             = $MinerAPIPort
                                        PrerequisitePath = $PrerequisitePath
                                        PrerequisiteURI  = $PrerequisiteURI
                                        Type             = $Type
                                        URI              = $URI
                                        WarmupTimes      = $WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                        Workers          = @(($Pool0, $Pool1).Where({ $_ }).ForEach({ @{ Pool = $_ } }))
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