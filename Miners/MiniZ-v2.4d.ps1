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

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" -or $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/MiniZ/miniZ_v2.4d_win-x64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\miniZ.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "Equihash1254";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA1");                         ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=125,4 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA1");                         ExcludePools = @();           AutoCoinPers = " --par=144,5"; Arguments = " --amd" } # FPGA
    [PSCustomObject]@{ Algorithm = "Equihash1505";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 4.0;  MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA1");                         ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=150,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1927";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.3;  MinerSet = 1; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();                                ExcludePools = @();           AutoCoinPers = " --par=192,7"; Arguments = " --amd" } #FPGA
    [PSCustomObject]@{ Algorithm = "Equihash2109";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA1");                         ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=210,9 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "EtcHash";          Type = "AMD"; Fee = @(0.0075); MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3");          ExcludePools = @("NiceHash"); AutoCoinPers = "";             Arguments = " --amd --par=etcHash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Type = "AMD"; Fee = @(0.0075); MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3");          ExcludePools = @("NiceHash"); AutoCoinPers = "";             Arguments = " --amd --par=ethash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "EthashB3";         Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                                ExcludePools = @( );          AutoCoinPers = "";             Arguments = " --amd --par=ethashb3 --dag-fix" }
    [PSCustomObject]@{ Algorithm = "EvrProgPow";       Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1"); ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --pers=EVRMORE-PROGPOW --dag-fix" }
    [PSCustomObject]@{ Algorithm = "FiroPow";          Type = "AMD"; Fee = @(0.0075); MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1"); ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --pers=firo" }
    [PSCustomObject]@{ Algorithm = "HeavyHashKarlsen"; Type = "AMD"; Fee = @(0.008);  MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other");                         ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --pers=kls" }
    [PSCustomObject]@{ Algorithm = "HeavyHashPyrin";   Type = "AMD"; Fee = @(0.008);  MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other");                         ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --pers=pyr" }
    [PSCustomObject]@{ Algorithm = "KawPow";           Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 35); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1"); ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=kawpow --dag-fix --pers=RAVENCOINKAWPOW" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1"); ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=progpow --pers=sero" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Type = "AMD"; Fee = @(0.01);   MinMemGiB = 8.0;  MinerSet = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1"); ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=progpow --pers=veil" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Type = "AMD"; Fee = @(0.01);   MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1"); ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=progpow --pers=VeriBlock" }
    [PSCustomObject]@{ Algorithm = "ProgPowZ";         Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1"); ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=progpow --pers=auto" }

    [PSCustomObject]@{ Algorithm = "BeamV3";           Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 4.0;  MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePools = @("NiceHash"); AutoCoinPers = "";             Arguments = " --nvidia --par=beam3" }
    [PSCustomObject]@{ Algorithm = "Equihash1254";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 3.0;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=125,4 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.0;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           AutoCoinPers = " --par=144,5"; Arguments = " --nvidia" } # FPGA
    [PSCustomObject]@{ Algorithm = "Equihash1505";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 4.0;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=150,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1927";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.3;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = " --par=192,7"; Arguments = " --nvidia" } # FPGA
    [PSCustomObject]@{ Algorithm = "Equihash2109";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.0;  MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=210,9 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash965";      Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.0;  MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=96,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "EtcHash";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePools = @("NiceHash"); AutoCoinPers = "";             Arguments = " --nvidia --par=etcHash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePools = @("NiceHash"); AutoCoinPers = "";             Arguments = " --nvidia --par=ethash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "EthashB3";         Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=ethashb3 --dag-fix" }
    [PSCustomObject]@{ Algorithm = "EvrProgPow";       Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --pers=EVRMORE-PROGPOW --dag-fix" }
    [PSCustomObject]@{ Algorithm = "FiroPow";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --pers=firo" }
    [PSCustomObject]@{ Algorithm = "HeavyHashKarlsen"; Type = "NVIDIA"; Fee = @(0.008);  MinMemGiB = 2.0;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --pers=kls" }
    [PSCustomObject]@{ Algorithm = "HeavyHashPyrin";   Type = "NVIDIA"; Fee = @(0.008);  MinMemGiB = 2.0;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --pers=pyr" }
    [PSCustomObject]@{ Algorithm = "KawPow";           Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 35); ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=kawpow --dag-fix --pers=RAVENCOINKAWPOW" }
    [PSCustomObject]@{ Algorithm = "Octopus";          Type = "NVIDIA"; Fee = @(0.03);   MinMemGiB = 1.24; Minerset = 0; Tuning = " --ocX"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=octopus" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --pers=sero" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 8.0;  MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --pers=veil" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 2.0;  MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --pers=VeriBlock" }
    [PSCustomObject]@{ Algorithm = "ProgPowZ";         Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 0.80; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --pers=auto" }
)       

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0].($_.Algorithm) })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })

If ($Algorithms) { 

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            If ($MinerDevices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model) { 
                $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

                ($Algorithms | Where-Object Type -EQ $_.Type).ForEach(
                    { 
                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        If ($SupportedMinerDevices = $MinerDevices.Where({ $_.Architecture -notin $ExcludeGPUArchitecture })) { 

                            $ExcludePools = $_.ExcludePools
                            ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $_.Name -notin $ExcludePools })) { 

                                $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                                If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($Pool.AlgorithmVariant)"

                                    $Arguments = $_.Arguments
                                    $Arguments += " --url=$(If ($Pool.PoolPorts[1]) { "ssl://" })$($Pool.User)@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1)"
                                    $Arguments += " --pass=$($Pool.Pass)"
                                    If ($Pool.WorkerName -and $Pool.User -notmatch "\.$($Pool.WorkerName)$") { $Arguments += " --worker=$($Pool.WorkerName)" }
                                    If ($_.AutoCoinPers) { $Arguments += $(Get-EquihashCoinPers -Command " --pers " -Currency $Pool.Currency -DefaultCommand $_.AutoCoinPers) }

                                    # Apply tuning parameters
                                    If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                                    [PSCustomObject]@{ 
                                        API          = "MiniZ"
                                        Arguments    = "$Arguments --jobtimeout=900 --retries=99 --retrydelay=1 --stat-int=10 --nohttpheaders --latency --all-shares --extra --tempunits=C --show-pers --fee-time=60 --telemetry $MinerAPIPort -cd $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:d2}' -f $_ }) -join ' ')"
                                        DeviceNames  = $AvailableMinerDevices.Name
                                        Fee          = $_.Fee # Dev fee
                                        MinerSet     = $_.MinerSet
                                        MinerUri     = "http://127.0.0.1:$($MinerAPIPort)"
                                        Name         = $MinerName
                                        Path         = $Path
                                        Port         = $MinerAPIPort
                                        Type         = $_.Type
                                        URI          = $URI
                                        WarmupTimes  = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
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