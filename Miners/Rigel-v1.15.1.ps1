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
Version:        6.2.2
Version date:   2024/03/28
#>

# Return 
If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -gt "5.0" }))) { Return }

$URI = "https://github.com/rigelminer/rigel/releases/download/1.15.1/rigel-1.15.1-win.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\Rigel.exe"
$DeviceEnumerator = "Type_Vendor_Slot"
 
$Algorithms = @(
    [PSCustomObject]@{ Algorithms = @("Autolykos2");                       Fee = @(0.01);         MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm autolykos2" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "Blake3");             Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm autolykos2+alephium" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "HeavyHashKarlsen");   Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm autolykos2+karlsenhash" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "HeavyHashPyrin");     Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm autolykos2+pyrinhash" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "IronFish");           Fee = @(0.01, 0.007);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm autolykos2+ironfish" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "FishHash");           Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm autolykos2+fishhash" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "SHA512256d");         Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @("ZPool")); Arguments = " --algorithm autolykos2+sha512256d" }
    [PSCustomObject]@{ Algorithms = @("Blake3");                           Fee = @(0.007);        MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm alephium" }
    [PSCustomObject]@{ Algorithms = @("EtcHash");                          Fee = @(0.007);        MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm etchash" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake3");                Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm etchash+alephium" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "HeavyHashKarlsen");      Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm etchash+karlsenhash" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "HeavyHashPyrin");        Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm etchash+pyrinhash" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "IronFish");              Fee = @(0.007, 0.007); MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm etchash+ironfish" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "FishHash");              Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm etchash+fishhash" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "SHA512256d");            Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @("ZPool")); Arguments = " --algorithm etchash+sha512256d" }
    [PSCustomObject]@{ Algorithms = @("Ethash");                           Fee = @(0.007);        MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ethash" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake3");                 Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ethash+alephium" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "HeavyHashKarlsen");       Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ethash+karlsenhash" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "HeavyHashPyrin");         Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ethash+pyrinhash" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "IronFish");               Fee = @(0.007, 0.007); MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ethash+ironfish" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "FishHash");               Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ethash+fishhash" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "SHA512256d");             Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @("ZPool")); Arguments = " --algorithm ethash+sha512256d" }
    [PSCustomObject]@{ Algorithms = @("EthashB3");                         Fee = @(0.01);         MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ethashb3" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "Blake3");               Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ethashb3+alephium" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "HeavyHashKarlsen");     Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ethashb3+karlsenhash" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "HeavyHashPyrin");       Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ethashb3+pyrinhash" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "IronFish");             Fee = @(0.01, 0.007);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ethashb3+ironfish" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "FishHash");             Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ethashb3+fishhash" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "SHA512256d");           Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @("ZPool")); Arguments = " --algorithm ethashb3+sha512256d" }
    [PSCustomObject]@{ Algorithms = @("EthashSHA256");                     Fee = @(0.01);         MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm abelian" }
    [PSCustomObject]@{ Algorithms = @("EthashSHA256", "Blake3");           Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm abelian+alephium" }
    [PSCustomObject]@{ Algorithms = @("EthashSHA256", "HeavyHashKarlsen"); Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm abelian+karlsenhash" }
    [PSCustomObject]@{ Algorithms = @("EthashSHA256", "HeavyHashPyrin");   Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm abelian+pyrinhash" }
    [PSCustomObject]@{ Algorithms = @("EthashSHA256", "IronFish");         Fee = @(0.01, 0.007);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm abelian+ironfish" }
    [PSCustomObject]@{ Algorithms = @("EthashSHA256", "FishHash");         Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm abelian+fishhash" }
    [PSCustomObject]@{ Algorithms = @("EthashSHA256", "SHA512256d");       Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @("ZPool")); Arguments = " --algorithm abelian+sha512256d" }
    [PSCustomObject]@{ Algorithms = @("HeavyHashKarlsen");                 Fee = @(0.007);        MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm karlsenhash" }
    [PSCustomObject]@{ Algorithms = @("HeavyHashPyrin");                   Fee = @(0.01);         MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm pyrinhash" }
    [PSCustomObject]@{ Algorithms = @("IronFish");                         Fee = @(0.007);        MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ironfish" }
    [PSCustomObject]@{ Algorithms = @("FishHash");                         Fee = @(0.01);         MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm fishhash" }
    [PSCustomObject]@{ Algorithms = @("KawPow");                           Fee = @(0.01);         MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(90, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm ravencoin" }
    [PSCustomObject]@{ Algorithms = @("NexaPow");                          Fee = @(0.02);         MinMemGiB = 3.0;  Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm nexapow" }
    [PSCustomObject]@{ Algorithms = @("Octopus");                          Fee = @(0.02);         MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm octopus" }
    [PSCustomObject]@{ Algorithms = @("Octopus", "Blake3");                Fee = @(0.02, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm octopus+alephium" }
    [PSCustomObject]@{ Algorithms = @("Octopus", "HeavyHashKarlsen");      Fee = @(0.02, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm octopus+karlsenhash" }
    [PSCustomObject]@{ Algorithms = @("Octopus", "HeavyHashPyrin");        Fee = @(0.02, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm octopus+pyrinhash" }
    [PSCustomObject]@{ Algorithms = @("Octopus", "SHA512256d");            Fee = @(0.02, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm octopus+sha512256d" }
    [PSCustomObject]@{ Algorithms = @("PowBlocks");                        Fee = @(0.007);        MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());        Arguments = " --algorithm powblocks" }
    [PSCustomObject]@{ Algorithms = @("SHA512256d");                       Fee = @(0.01);         MinMemGiB = 1.0;  Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@("ZPool"), @()); Arguments = " --algorithm sha512256d" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms.Where({ -not $_.Algorithms[1] }) | ForEach-Object { $_.Algorithms += "" }
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] -and $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]].Name -notin $_.ExcludePools[0] })
$Algorithms = $Algorithms.Where({ $MinerPools[1][$_.Algorithms[1]].Name -notin $_.ExcludePools[1] })

If ($Algorithms) { 

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            If ($Miner_Devices = $Devices | Where-Object Model -EQ $_.Model) { 
                $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

                $Algorithms.ForEach(
                    { 
                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        If ($AvailableMiner_Devices = $Miner_Devices.Where({ $_.Architecture -notin $ExcludeGPUArchitecture })) { 

                            $ExcludePools = $_.ExcludePools
                            ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $_.Name -notin $ExcludePools[0] })) { 
                                ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $_.Name -notin $ExcludePools[1] })) { 
                                    $Pools = @(($Pool0, $Pool1).Where({ $_ }))

                                    $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB
                                    If ($AvailableMiner_Devices = $AvailableMiner_Devices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                        $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                        $Arguments = $_.Arguments
                                        If ($Pool0.Currency -in @("AIPG", "CLORE", "ETHW", "NEOX", "OCTA", "RVN", "XNA", "XPB")) { $Arguments += " --coin $($Pool0.Currency.ToLower())" }

                                        $Index = 1
                                        ForEach ($Pool in $Pools) { 
                                            Switch ($Pool.Protocol) { 
                                                "ethproxy"     { $Arguments += " --url [$Index]ethproxy"; Break }
                                                "ethstratum1"  { $Arguments += " --url [$Index]ethstratum"; Break }
                                                "ethstratum2"  { $Arguments += " --url [$Index]ethstratum"; Break }
                                                "ethstratumnh" { $Arguments += " --url [$Index]ethstratum"; Break }
                                                Default        { $Arguments += " --url [$Index]stratum" }
                                            }
                                            $Arguments += If ($Pool.PoolPorts[1]) { "+ssl://" } Else { "+tcp://" }
                                            $Arguments += "$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1)"
                                            $Arguments += " --username [$Index]$($Pool.User -replace "\.$($Config.Workername)$")"
                                            $Arguments += " --password [$Index]$($Pool.Pass)"
                                            $Arguments += " --worker [$Index]$($Config.WorkerName)"
                                            $Index ++
                                        }
                                        Remove-Variable Pool

                                        $Arguments += If ($Pool0.PoolPorts[1] -or ($_.Algorithms[1] -and $Pool1.PoolPorts[1])) { " --no-strict-ssl" } # Parameter cannot be used multiple times

                                        # Apply tuning parameters
                                        If ($Variables.UseMinerTweaks -and ($AvailableMiner_Devices.Architecture | Sort-Object -Unique) -eq "Pascal" -and ($AvailableMiner_Devices.Model | Sort-Object -Unique) -notmatch "^MX\d+") { $Arguments += $_.Tuning }

                                        [PSCustomObject]@{ 
                                            API         = "Rigel"
                                            Arguments   = "$Arguments --api-bind 127.0.0.1:$($MinerAPIPort) --no-watchdog --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                            DeviceNames = $AvailableMiner_Devices.Name
                                            Fee         = $_.Fee # Dev fee
                                            MinerSet    = $_.MinerSet
                                            MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                            Name        = $Miner_Name
                                            Path        = $Path
                                            Port        = $MinerAPIPort
                                            Type        = "NVIDIA"
                                            URI         = $Uri
                                            WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                            Workers     = @($Pools | ForEach-Object { @{ Pool = $_ } })
                                        }
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
