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
Version:        6.7.30
Version date:   2026/02/26
#>

if (-not ($Devices = $Session.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.0" }))) { return }

$URI = "https://github.com/trexminer/T-Rex/releases/download/0.26.8/t-rex-0.26.8-win.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\t-rex.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithms = @("Autolykos2", "");       Fee = @(0.02);       MinMemGiB = 1.08; Tuning = " --mt 3"; WarmupTimes = @(45, 0);   ExcludePools = @(@(), @()); Arguments = " --algo autolykos2 --intensity 25" }
    @{ Algorithms = @("Blake3", "");           Fee = @(0.01);       MinMemGiB = 2;    Tuning = " --mt 3"; WarmupTimes = @(45, 0);   ExcludePools = @(@(), @()); Arguments = " --algo blake3 --intensity 25" }
    @{ Algorithms = @("EtcHash", "");          Fee = @(0.01);       MinMemGiB = 1.08; Tuning = " --mt 3"; WarmupTimes = @(60, 5);   ExcludePools = @(@(), @()); Arguments = " --algo etchash --intensity 25" } # GMiner-v3.44 is fastest
    @{ Algorithms = @("EtcHash", "Blake3");    Fee = @(0.01, 0.01); MinMemGiB = 1.08; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = " --algo etchash --dual-algo blake3 --lhr-tune -1 --lhr-autotune-interval 1" }
    @{ Algorithms = @("Ethash", "");           Fee = @(0.01);       MinMemGiB = 1.08; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = " --algo ethash --intensity 25" } # GMiner-v3.44 is fastest
    @{ Algorithms = @("Ethash", "Autolykos2"); Fee = @(0.01, 0.02); MinMemGiB = 8;    Tuning = " --mt 3"; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = " --algo ethash --dual-algo autolykos2 --lhr-tune -1 --lhr-autotune-interval 1" }
    @{ Algorithms = @("Ethash", "Blake3");     Fee = @(0.01, 0.01); MinMemGiB = 1.08; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = " --algo ethash --dual-algo blake3 --lhr-tune -1 --lhr-autotune-interval 1" }
    @{ Algorithms = @("Ethash", "FiroPow");    Fee = @(0.01, 0.01); MinMemGiB = 10;   Tuning = " --mt 3"; WarmupTimes = @(255, 15); ExcludePools = @(@(), @()); Arguments = " --algo ethash --dual-algo firopow --lhr-tune -1" }
    @{ Algorithms = @("Ethash", "KawPow");     Fee = @(0.01, 0.01); MinMemGiB = 10;   Tuning = " --mt 3"; WarmupTimes = @(255, 15); ExcludePools = @(@(), @()); Arguments = " --algo ethash --dual-algo kawpow --lhr-tune -1" }
    @{ Algorithms = @("Ethash", "Octopus");    Fee = @(0.01, 0.02); MinMemGiB = 8;    Tuning = " --mt 3"; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = " --algo ethash --dual-algo octopus --lhr-tune -1" }
    @{ Algorithms = @("FiroPow", "");          Fee = @(0.01);       MinMemGiB = 1.08; Tuning = " --mt 3"; WarmupTimes = @(60, 30);  ExcludePools = @(@(), @()); Arguments = " --algo firopow --intensity 25" }
    @{ Algorithms = @("KawPow", "");           Fee = @(0.01);       MinMemGiB = 1.08; Tuning = " --mt 3"; WarmupTimes = @(45, 20);  ExcludePools = @(@(), @()); Arguments = " --algo kawpow --intensity 25" } # XmRig-v6.25.0 is almost as fast but has no fee
#   @{ Algorithms = @("MTP", "");              Fee = @(0.01);       MinMemGiB = 3;    Tuning = " --mt 3"; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = " --algo mtp --intensity 21" } # Algorithm is dead
    @{ Algorithms = @("MTPTcr", "");           Fee = @(0.01);       MinMemGiB = 3;    Tuning = " --mt 3"; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = " --algo mtp-tcr --intensity 21" }
    @{ Algorithms = @("Multi", "");            Fee = @(0.01);       MinMemGiB = 2;    Tuning = " --mt 3"; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = " --algo multi --intensity 25" }
    @{ Algorithms = @("Octopus", "");          Fee = @(0.02);       MinMemGiB = 1.08; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = " --algo octopus" } # 6GB is not enough
    @{ Algorithms = @("ProgPowSero", "");      Fee = @(0.01);       MinMemGiB = 1.08; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = " --algo progpow --coin sero" }
    @{ Algorithms = @("ProgPowVeil", "");      Fee = @(0.01);       MinMemGiB = 1.08; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = " --algo progpow-veil --intensity 24" }
    @{ Algorithms = @("ProgPowVeriblock", ""); Fee = @(0.01);       MinMemGiB = 2;    Tuning = " --mt 3"; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = " --algo progpow-veriblock" }
    @{ Algorithms = @("ProgPowZ", "");         Fee = @(0.01);       MinMemGiB = 1.08; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = " --algo progpowz --intensity 25" }
#   @{ Algorithms = @("Tensority", "");        Fee = @(0.01);       MinMemGiB = 2;    Tuning = " --mt 3"; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = " --algo tensority --intensity 25" } # ASIC
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.Where({ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] })

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.ForEach(
                { 
                    # $ExcludePools = $_.ExcludePools
                    foreach ($Pool0 in $MinerPools[0][$_.Algorithms[0]]) { 
                        foreach ($Pool1 in $MinerPools[1][$_.Algorithms[1]]) { 

                            $MinMemGiB = $_.MinMemGiB + $Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB
                            if ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(if ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                if ($AvailableMinerDevices.Where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace " --intensity .+$" }

                                $Arguments = $_.Arguments
                                switch ($Pool0.Protocol) { 
                                    "ethstratum1"  { $Arguments += " --url stratum2"; break }
                                    "ethstratum2"  { $Arguments += " --url stratum2"; break }
                                    "ethstratumnh" { $Arguments += " --url stratum2"; break }
                                    default        { $Arguments += " --url stratum" }
                                }
                                $Arguments += if ($Pool0.PoolPorts[1]) { "+ssl" } else { "+tcp" }
                                $Arguments += "://$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1)"
                                $Arguments += " --user $($Pool0.User) --pass $($Pool0.Pass)"
                                if ($Pool0.WorkerName) { $Arguments += " --worker $($Pool0.WorkerName)" }

                                if ("CLO", "ETC", "ETH", "ETHW", "ETP", "EXP", "MUSIC", "PIRL", "RVN", "TCR", "UBQ", "VBK", "ZCOIN", "ZELS" -contains $Pool0.Currency) { 
                                    $Arguments += " --coin $($Pool0.Currency)"
                                }

                                if ($_.Algorithms[1]) { 
                                    switch ($Pool1.Protocol) { 
                                        "ethstratum1"  { $Arguments += " --url2 stratum2"; break }
                                        "ethstratum2"  { $Arguments += " --url2 stratum2"; break }
                                        "ethstratumnh" { $Arguments += " --url2 stratum2"; break }
                                        default        { $Arguments += " --url2 stratum" }
                                    }
                                    $Arguments += if ($Pool1.PoolPorts[1]) { "+ssl" } else { "+tcp" }
                                    $Arguments += "://$($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1)"
                                    $Arguments += " --user2 $($Pool1.User) --pass2 $($Pool1.Pass)"
                                    if ($Pool1.WorkerName) { $Arguments += " --worker2 $($Pool1.WorkerName)" }
                                }

                                if ($Arguments -notmatch "--kernel [0-9]") { $_.WarmupTimes[0] += 15 } # Allow extra seconds for kernel auto tuning

                                # Apply tuning parameters
                                if ($Session.ApplyMinerTweaks) { $_.Arguments += $_.Tuning }

                                [PSCustomObject]@{ 
                                    API         = "Trex"
                                    Arguments   = "$Arguments --no-strict-ssl --no-watchdog --gpu-report-interval 5 --quiet --retry-pause 1 --timeout 50000 --api-bind-http 127.0.0.1:$($MinerAPIPort) --api-read-only --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                    DeviceNames = $AvailableMinerDevices.Name
                                    Fee         = $_.Fee # Dev fee
                                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)/trex"
                                    Name        = $MinerName
                                    Path        = $Path
                                    Port        = $MinerAPIPort
                                    Type        = "NVIDIA"
                                    URI         = $URI
                                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                    Workers     = @(($Pool0, $Pool1).Where({ $_ }).ForEach({ @{ Pool = $_ } }))
                                }
                            }
                        }
                    }
                }
            )
        }
    )
}