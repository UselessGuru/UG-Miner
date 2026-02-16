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
Version:        6.7.28
Version date:   2026/02/16
#>

if (-not ($Devices = $Session.EnabledDevices.Where({ $_.Type -eq "CPU" -or $_.Type -eq "INTEL" -or ($_.Type -eq "AMD" -and $_.Architecture -notmatch "GCN[1-3]" -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0") -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge "510.00") }))) { return }

$URI = "https://github.com/doktor83/SRBMiner-Multi/releases/download/2.9.2/SRBMiner-Multi-2-9-2-win64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\SRBMiner-MULTI.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# Note: CCLHash, YespowerDogemone, astrixhash, xehash were removed in v2.9.5; keep v2.9.2 for these algorithms
# Note: progpow_veil, progpow_quai, ethashr5 were removed in v3.1,0; keep v2.9.2 for these algorithms

# UG: Added EvoHash (removed in v2.9.3)
# UG: Added HooHash (removed in v2.9.4)
# UG: Added EthashB3 (removed in v2.9.7)
# UG: Added Liberty (removed in v2.9.8)
# UG: Added SHA256dt (removed in v2.9.8)
# UG: Added FpHash (removed in v3.1.2)

# Algorithm parameter values are case sensitive!
$Algorithms = @( 
    @{ Algorithms = @("AstrixHash", "");        Type = "AMD"; Fee = @(0.01);           MinMemGiB = 2;    WarmupTimes = @(45, 20); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm astrixhash") }
    @{ Algorithms = @("Autolykos2", "HooHash"); Type = "AMD"; Fee = @(0.01, 0.02);     MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm hoohash") }
    @{ Algorithms = @("CLCHash", "");           Type = "AMD"; Fee = @(0.02);           MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm clchash") }
    @{ Algorithms = @("EtcHash", "SHA256dt");   Type = "AMD"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm etchash", " --algorithm sha256dt") }
    @{ Algorithms = @("Ethash", "SHA256dt");    Type = "AMD"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethash", " --algorithm sha256dt") }
    @{ Algorithms = @("EthashB3", "");          Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethashb3") }
    @{ Algorithms = @("EthashB3", "Decred");    Type = "AMD"; Fee = @(0.0085, 0.01);   MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethashb3", " --algorithm blake3_decred") }
    @{ Algorithms = @("EthashB3", "SHA256dt");  Type = "AMD"; Fee = @(0.01, 0.0085);   MinMemGiB = 1.24; WarmupTimes = @(45, 40); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethashb3", " --algorithm sha256dt") }
    @{ Algorithms = @("EthashR5", "");          Type = "AMD"; Fee = @(0.02);           MinMemGiB = 1.24; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm ethashr5") }
    @{ Algorithms = @("EvoHash", "");           Type = "AMD"; Fee = @(0.02);           MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm evohash") }
    @{ Algorithms = @("FpHash", "");            Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fphash") }
    @{ Algorithms = @("HooHash", "");           Type = "AMD"; Fee = @(0.02);           MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm hoohash") }
    @{ Algorithms = @("Liberty", "");           Type = "AMD"; Fee = @(0.02);           MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm blake3_lbrt") }
    @{ Algorithms = @("ProgPowQuai", "");       Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_quai") }
    @{ Algorithms = @("ProgPowVeil", "");       Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm progpow_veil") }
    @{ Algorithms = @("SHA256dt", "");          Type = "AMD"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(45, 20); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm sha256dt") }
    @{ Algorithms = @("XeChain", "");           Type = "AMD"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(90, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm xechain") }

    @{ Algorithms = @("Argon2d16000", "");     Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 15); ExcludePools = @(@(), @()); Arguments = @(" --disable-gpu --algorithm argon2d_16000") } # Bad shares in v2.9.9
    @{ Algorithms = @("YespowerDogemone", ""); Type = "CPU"; Fee = @(0.0085); WarmupTimes = @(60, 25); ExcludePools = @(@(), @()); Arguments = @(" --disable-gpu --algorithm yespowerdogemone") }

    @{ Algorithms = @("AstrixHash", "");        Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm astrixhash") }
    @{ Algorithms = @("Autolykos2", "HooHash"); Type = "INTEL"; Fee = @(0.01, 0.02);     MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm autolykos2 --autolykos2-preload", " --algorithm hoohash") }
    @{ Algorithms = @("CLCHash", "");           Type = "INTEL"; Fee = @(0.02);           MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm clchash") }
    @{ Algorithms = @("EtcHash", "SHA256dt");   Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm etchash", " --algorithm sha256dt") }
    @{ Algorithms = @("Ethash", "SHA256dt");    Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethash", " --algorithm sha256dt") }
    @{ Algorithms = @("EthashB3", "");          Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethashb3") }
    @{ Algorithms = @("EthashB3", "Decred");    Type = "INTEL"; Fee = @(0.0085, 0.01);   MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethashb3", " --algorithm blake3_decred") }
    @{ Algorithms = @("EthashB3", "SHA256dt");  Type = "INTEL"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethashb3", " --algorithm sha256dt") }
    @{ Algorithms = @("EthashR5", "");          Type = "INTEL"; Fee = @(0.02);           MinMemGiB = 1.24; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm ethashr5") }
    @{ Algorithms = @("EvoHash", "");           Type = "INTEL"; Fee = @(0.02);           MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm evohash") }
    @{ Algorithms = @("FpHash", "");            Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fphash") }
    @{ Algorithms = @("HooHash", "");           Type = "INTEL"; Fee = @(0.02);           MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm hoohash") }
    @{ Algorithms = @("Liberty", "");           Type = "INTEL"; Fee = @(0.02);           MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm blake3_lbrt") }
    @{ Algorithms = @("ProgPowQuai", "");       Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_quai") }
    @{ Algorithms = @("ProgPowVeil", "");       Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm progpow_veil") }
    @{ Algorithms = @("SHA256dt", "");          Type = "INTEL"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm sha256dt") }
    @{ Algorithms = @("XeChain", "");           Type = "INTEL"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(90, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-nvidia --algorithm xechain") }

    @{ Algorithms = @("AstrixHash", "");        Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(30, 20); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm astrixhash") }
    @{ Algorithms = @("Autolykos2", "HooHash"); Type = "NVIDIA"; Fee = @(0.01, 0.02);     MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$";          ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm autolykos2 --autolykos2-preload", " --algorithm hoohash") }
    @{ Algorithms = @("CLCHash", "");           Type = "NVIDIA"; Fee = @(0.02);           MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm clchash") }
    @{ Algorithms = @("EtcHash", "SHA256dt");   Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm etchash", " --algorithm sha256dt") }
    @{ Algorithms = @("Ethash", "SHA256dt");    Type = "NVIDIA"; Fee = @(0.0065, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(60, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethash", " --algorithm sha256dt") }
    @{ Algorithms = @("EthashB3", "");          Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethashb3") }
    @{ Algorithms = @("EthashB3", "Decred");    Type = "NVIDIA"; Fee = @(0.0085, 0.01);   MinMemGiB = 1.24; WarmupTimes = @(45, 20); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethashb3", " --algorithm blake3_decred") }
    @{ Algorithms = @("EthashB3", "SHA256dt");  Type = "NVIDIA"; Fee = @(0.0085, 0.0085); MinMemGiB = 1.24; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = "^Pascal$";         ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethashb3", " --algorithm sha256dt") }
    @{ Algorithms = @("EthashR5", "");          Type = "NVIDIA"; Fee = @(0.02);           MinMemGiB = 1.24; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm ethashr5") }
    @{ Algorithms = @("EvoHash", "");           Type = "NVIDIA"; Fee = @(0.02);           MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$";          ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm evohash") }
    @{ Algorithms = @("FpHash", "");            Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-intel --disable-gpu-nvidia --algorithm fphash") }
    @{ Algorithms = @("HooHash", "");           Type = "NVIDIA"; Fee = @(0.02);           MinMemGiB = 1;    WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^Other$";          ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm hoohash") }
    @{ Algorithms = @("Liberty", "");           Type = "NVIDIA"; Fee = @(0.02);           MinMemGiB = 1;    WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm blake3_lbrt") }
    @{ Algorithms = @("ProgPowQuai", "");       Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_quai") }
    @{ Algorithms = @("ProgPowVeil", "");       Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1.24; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm progpow_veil") }
    @{ Algorithms = @("SHA256dt", "");          Type = "NVIDIA"; Fee = @(0.0085);         MinMemGiB = 1;    WarmupTimes = @(45, 15); ExcludeGPUarchitectures = "^Other$|^Pascal$"; ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm sha256dt") }
    @{ Algorithms = @("XeChain", "");           Type = "NVIDIA"; Fee = @(0.01);           MinMemGiB = 1;    WarmupTimes = @(90, 0);  ExcludeGPUarchitectures = " ";                ExcludePools = @(@(), @()); Arguments = @(" --disable-cpu --disable-gpu-amd --disable-gpu-intel --algorithm xechain") }
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.Where({ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] })

if ($Algorithms) { 

    if (-not $Session.Config.DryRun) { 
        # Allowed max loss for 1. algorithm
        # $GpuDualMaxLosses = @(2, 4, 7, 10, 15, 21, 30)
        $GpuDualMaxLosses = @(5)

        # Build command sets for max loss
        $Algorithms = $Algorithms.ForEach(
            { 
                $_.PsObject.Copy()
                if ($_.Algorithms[1]) { 
                    foreach ($GpuDualMaxLoss in $GpuDualMaxLosses) { 
                        $_.GpuDualMaxLoss = $GpuDualMaxLoss
                        $_.PsObject.Copy()
                    }
                }
            }
        )
    }

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    if ($SupportedMinerDevices = $MinerDevices.Where({ $_.Type -eq "CPU" -or $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        if ($_.Algorithms[0] -eq "VertHash" -and (Get-Item -Path $Session.VertHashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                            $PrerequisitePath = $Session.VertHashDatPath
                            $PrerequisiteURI  = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
                        }
                        else { 
                            $PrerequisitePath = ""
                            $PrerequisiteURI  = ""
                        }

                        $ExcludePools = $_.ExcludePools
                        foreach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $ExcludePools[0] -notcontains $_.Name })) { 
                            foreach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $ExcludePools[1] -notcontains $_.Name })) { 
                                $Pools = @(($Pool0, $Pool1).Where({ $_ }))

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB
                                if ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -gt $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(if ($Pool1) { "&$($Pool1.AlgorithmVariant)$(if ($_.GpuDualMaxLoss) { "-$($_.GpuDualMaxLoss)" })"})"

                                    $Arguments = ""
                                    foreach ($Pool in $Pools) { 
                                        if ($Pool.Algorithm -match $Session.RegexAlgoIsEthash) { 
                                            switch ($Pool.Protocol) { 
                                                "minerproxy"   { $Arguments += " --esm 0"; break }
                                                "ethproxy"     { $Arguments += " --esm 0"; break }
                                                "ethstratum1"  { $Arguments += " --esm 1"; break }
                                                "ethstratum2"  { $Arguments += " --esm 2"; break }
                                                "ethstratumnh" { $Arguments += " --esm 2" }
                                            }
                                        }
                                        $Arguments += "$($_.Arguments[$Pools.IndexOf($Pool)]) --pool $($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --wallet $($Pool.User) --password $($Pool.Pass)"
                                        if ($Pool.Name -eq "NiceHash" ) { $Arguments += " --nicehash true" }
                                        if ($Pool.WorkerName) { $Arguments += " --worker $($Pool.WorkerName)" }
                                        $Arguments += if ($Pool.PoolPorts[1]) { " --tls true" } else { " --tls false" }
                                        if ($_.GpuDualMaxLoss) { $Arguments += " --gpu-dual-max-loss $($_.GpuDualMaxLoss)" }
                                    }
                                    Remove-Variable Pool

                                    if ($_.Type -eq "CPU") { 
                                        $Arguments += " --cpu-threads $($AvailableMinerDevices.CIM.NumberOfLogicalProcessors - $Session.Config.CPUMiningReserveCPUcore)"
                                    }
                                    else { 
                                        $Arguments += " --gpu-id $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                    }

                                    # Allow more time to build larger DAGs, must use type cast to keep values in $_
                                    $WarmupTimes = [UInt16[]]$_.WarmupTimes
                                    $WarmupTimes[0] += [UInt16](($Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB) * 2)

                                    if ($_.Algorithms[0] -eq "KawPow" -and "HashCryptos", "MiningDutch" -contains $Pool0) { $Arguments += " --retry-time 1" }

                                    # Apply tuning parameters
                                    if ($_.Type -eq "CPU" -and -not $Session.ApplyMinerTweaks) { $_.Arguments += " --disable-msr-tweaks" }

                                    [PSCustomObject]@{ 
                                        API              = "SRBMiner"
                                        Arguments        = "$Arguments --api-rig-name $($Session.Config.Pools.($Pool0.Name).WorkerName) --api-enable --api-port $MinerAPIPort"
                                        DeviceNames      = $AvailableMinerDevices.Name
                                        Fee              = $_.Fee # Dev fee
                                        MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/stats"
                                        Name             = $MinerName
                                        Path             = $Path
                                        Port             = $MinerAPIPort
                                        PrerequisitePath = $PrerequisitePath
                                        PrerequisiteURI  = $PrerequisiteURI
                                        Type             = $Type
                                        URI              = $URI
                                        WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                        Workers          = @($Pools.ForEach({ @{ Pool = $_ } }))
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
