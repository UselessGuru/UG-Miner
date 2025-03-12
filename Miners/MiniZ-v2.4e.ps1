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
Version:        6.4.16
Version date:   2025/03/12
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" -or $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/MiniZ/miniZ_v2.4e_win-x64.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\miniZ.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithm = "Equihash1254";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";                 ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=125,4 --smart-pers" }
    @{ Algorithm = "Equihash1445";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = "^GCN1$";            ExcludePools = @();           AutoCoinPers = " --par=144,5"; Arguments = " --amd" } # FPGA
    @{ Algorithm = "Equihash1505";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 4.0;  MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = "^RDNA1$";           ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=150,5 --smart-pers" }
    @{ Algorithm = "Equihash1927";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.3;  MinerSet = 1; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = " ";                 ExcludePools = @();           AutoCoinPers = " --par=192,7"; Arguments = " --amd" } #FPGA
    @{ Algorithm = "Equihash2109";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(30, 30); ExcludeGPUarchitectures = "^RDNA1$";           ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=210,9 --smart-pers" }
    @{ Algorithm = "EtcHash";          Type = "AMD"; Fee = @(0.0075); MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = "^GCN[123]$";        ExcludePools = @("NiceHash"); AutoCoinPers = "";             Arguments = " --amd --par=etcHash --dag-fix" }
    @{ Algorithm = "Ethash";           Type = "AMD"; Fee = @(0.0075); MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = "^GCN[123]$";        ExcludePools = @("NiceHash"); AutoCoinPers = "";             Arguments = " --amd --par=ethash --dag-fix" }
    @{ Algorithm = "EthashB3";         Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " ";                 ExcludePools = @( );          AutoCoinPers = "";             Arguments = " --amd --par=ethashb3 --dag-fix" }
    @{ Algorithm = "EvrProgPow";       Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = "^GCN[123]$";        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --pers=EVRMORE-PROGPOW --dag-fix" }
    @{ Algorithm = "FiroPow";          Type = "AMD"; Fee = @(0.0075); MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(55, 45); ExcludeGPUarchitectures = " ";                 ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --algo=firo" }
    @{ Algorithm = "FishHash";         Type = "AMD"; Fee = @(0.0075); MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(55, 45); ExcludeGPUarchitectures = " ";                 ExcludePools = @("NiceHash"); AutoCoinPers = "";             Arguments = " --amd --algo=fishhash" }
    @{ Algorithm = "KawPow";           Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(60, 35); ExcludeGPUarchitectures = "^GCN[123]$";        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=kawpow --dag-fix --pers=RAVENCOINKAWPOW" }
    @{ Algorithm = "ProgPowSero";      Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = "^GCN[123]$";        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=progpow --pers=sero" }
    @{ Algorithm = "ProgPowVeil";      Type = "AMD"; Fee = @(0.01);   MinMemGiB = 8.0;  MinerSet = 2; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = "^GCN[123]$|^RDNA1"; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=progpow --pers=veil" }
    @{ Algorithm = "ProgPowVeriblock"; Type = "AMD"; Fee = @(0.01);   MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = "^GCN[123]$|^RDNA1"; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=progpow --pers=VeriBlock" }
    @{ Algorithm = "ProgPowZ";         Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = "^GCN[123]$";        ExcludePools = @();           AutoCoinPers = "";             Arguments = " --amd --par=progpow --pers=auto" }

    @{ Algorithm = "BeamV3";           Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 4.0;  MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludePools = @("NiceHash"); AutoCoinPers = "";             Arguments = " --nvidia --par=beam3" }
    @{ Algorithm = "Equihash1254";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 3.0;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=125,4 --smart-pers" }
    @{ Algorithm = "Equihash1445";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.0;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = " --par=144,5"; Arguments = " --nvidia" } # FPGA
    @{ Algorithm = "Equihash1505";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 4.0;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=150,5 --smart-pers" }
    @{ Algorithm = "Equihash1927";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.3;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = " --par=192,7"; Arguments = " --nvidia" } # FPGA
    @{ Algorithm = "Equihash2109";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.0;  MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=210,9 --smart-pers" }
    @{ Algorithm = "Equihash965";      Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.0;  MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=96,5 --smart-pers" }
    @{ Algorithm = "EtcHash";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludePools = @("NiceHash"); AutoCoinPers = "";             Arguments = " --nvidia --par=etcHash --dag-fix" }
    @{ Algorithm = "Ethash";           Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludePools = @("NiceHash"); AutoCoinPers = "";             Arguments = " --nvidia --par=ethash --dag-fix" }
    @{ Algorithm = "EthashB3";         Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=ethashb3 --dag-fix" }
    @{ Algorithm = "EvrProgPow";       Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --pers=EVRMORE-PROGPOW --dag-fix" }
    @{ Algorithm = "FiroPow";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(55, 45); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --algo=firo" }
    @{ Algorithm = "KawPow";           Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(60, 35); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=kawpow --dag-fix --pers=RAVENCOINKAWPOW" }
    @{ Algorithm = "Octopus";          Type = "NVIDIA"; Fee = @(0.03);   MinMemGiB = 1.24; Minerset = 0; Tuning = " --ocX"; WarmupTimes = @(45, 0);  ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --par=octopus" }
    @{ Algorithm = "ProgPowSero";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 1.08; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --pers=sero" }
    @{ Algorithm = "ProgPowVeil";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 8.0;  MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --pers=veil" }
    @{ Algorithm = "ProgPowVeriblock"; Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 2.0;  MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(30, 15); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --pers=VeriBlock" }
    @{ Algorithm = "ProgPowZ";         Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 0.80; MinerSet = 2; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUarchitectures = " "; ExcludePools = @();           AutoCoinPers = "";             Arguments = " --nvidia --pers=auto" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0].($_.Algorithm) })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    If ($SupportedMinerDevices = $MinerDevices.Where({ $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        $ExcludePools = $_.ExcludePools
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 

                            $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                            If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                                $Arguments = $_.Arguments
                                $Arguments += " --url=$(If ($Pool.PoolPorts[1]) { "ssl://" })$($Pool.User)@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1)"
                                $Arguments += " --pass=$($Pool.Pass)"
                                If ($Pool.WorkerName -and $Pool.User -notmatch "\.$($Pool.WorkerName)$") { $Arguments += " --worker=$($Pool.WorkerName)" }
                                If ($_.AutoCoinPers) { $Arguments += $(Get-EquihashCoinPers -Command " --pers " -Currency $Pool.Currency -DefaultCommand $_.AutoCoinPers) }

                                # Apply tuning parameters
                                If ($Variables.ApplyMinerTweaks) { $_.Arguments += $_.Tuning }

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
                                    Type         = $Type
                                    URI          = $URI
                                    WarmupTimes  = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
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