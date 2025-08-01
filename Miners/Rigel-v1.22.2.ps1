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
Version:        6.5.2
Version date:   2025/07/27
#>

# Add sha3x algorithm for Tari mining (dev fee 1%)
# Add dual mining combos with the following coins:
# ABEL (abelian+sha3x)
# ERGO (autolykos2+sha3x)
# IRON (fishhash+sha3x)
# CFX (octopus+sha3x)
# KLS (karlsenhashv2+sha3x)

If (-not ($Devices = $Session.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -gt "5.0" }))) { Return }

$URI = "https://github.com/rigelminer/rigel/releases/download/1.22.2/rigel-1.22.2-win.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\Rigel.exe"
$DeviceEnumerator = "Type_Vendor_Slot"
 
$Algorithms = @(
    @{ Algorithms = @("Autolykos2", "");                     Fee = @(0.01);         MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm autolykos2" }
    @{ Algorithms = @("Autolykos2", "Blake3");               Fee = @(0.01, 0.007);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm autolykos2+alephium" }
#   @{ Algorithms = @("Autolykos2", "HeavyHashKarlsenV2");   Fee = @(0.01, 0.02);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm autolykos2+karlsenhashv2" } # Not supported yet
    @{ Algorithms = @("Autolykos2", "IronFish");             Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm autolykos2+fishhash" }
    @{ Algorithms = @("Autolykos2", "SHA512256d");           Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm autolykos2+sha512256d" }
    @{ Algorithms = @("Autolykos2", "SHA3x");                Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm autolykos2+sha3x" }
    @{ Algorithms = @("Blake3", "");                         Fee = @(0.007);        MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm alephium" }
    @{ Algorithms = @("EtcHash", "");                        Fee = @(0.007);        MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm etchash" }
    @{ Algorithms = @("EtcHash", "Blake3");                  Fee = @(0.007, 0.007); MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludePools = @(@(), @()); Arguments = " --algorithm etchash+alephium" }
#   @{ Algorithms = @("EtcHash", "HeavyHashKarlsenv2");      Fee = @(0.007, 0.02);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludePools = @(@(), @()); Arguments = " --algorithm etchash+karlsenhashv2" } # Not supported yet
    @{ Algorithms = @("EtcHash", "IronFish");                Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludePools = @(@(), @()); Arguments = " --algorithm etchash+fishhash" }
    @{ Algorithms = @("EtcHash", "SHA512256d");              Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludePools = @(@(), @()); Arguments = " --algorithm etchash+sha512256d" }
    @{ Algorithms = @("Ethash", "");                         Fee = @(0.007);        MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " --algorithm ethash" }
    @{ Algorithms = @("Ethash", "Blake3");                   Fee = @(0.007, 0.007); MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 25); ExcludePools = @(@(), @()); Arguments = " --algorithm ethash+alephium" }
#   @{ Algorithms = @("Ethash", "HeavyHashKarlsenV2");       Fee = @(0.007, 0.02);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm ethash+karlsenhashv2" } # Not supported yet
    @{ Algorithms = @("Ethash", "IronFish");                 Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 25); ExcludePools = @(@(), @()); Arguments = " --algorithm ethash+fishhash" }
    @{ Algorithms = @("Ethash", "SHA512256d");               Fee = @(0.007, 0.01);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(60, 15); ExcludePools = @(@(), @()); Arguments = " --algorithm ethash+sha512256d" }
    @{ Algorithms = @("EthashB3", "");                       Fee = @(0.01);         MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " --algorithm ethashb3" }
    @{ Algorithms = @("EthashB3", "Blake3");                 Fee = @(0.01, 0.007);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm ethashb3+alephium" }
#   @{ Algorithms = @("EthashB3", "HeavyHashKarlsenV2");     Fee = @(0.01, 0.02);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 25); ExcludePools = @(@(), @()); Arguments = " --algorithm ethashb3+karlsenhashv2" } # Not supported yet
    @{ Algorithms = @("EthashB3", "IronFish");               Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm ethashb3+fishhash" }
    @{ Algorithms = @("EthashB3", "SHA512256d");             Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm ethashb3+sha512256d" }
    @{ Algorithms = @("EthashSHA256", "");                   Fee = @(0.01);         MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm abelian" }
    @{ Algorithms = @("EthashSHA256", "Blake3");             Fee = @(0.01, 0.007);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm abelian+alephium" }
#   @{ Algorithms = @("EthashSHA256", "HeavyHashKarlsenV2"); Fee = @(0.01, 0.02);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 25); ExcludePools = @(@(), @()); Arguments = " --algorithm abelian+karlsenhashv2" } # Not supported yet
    @{ Algorithms = @("EthashSHA256", "IronFish");           Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm abelian+fishhash" }
    @{ Algorithms = @("EthashSHA256", "SHA512256d");         Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm abelian+sha512256d" }
    @{ Algorithms = @("EthashSHA256", "SHA3x");              Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm abelian+sha3x" }
    @{ Algorithms = @("FishHash", "");                       Fee = @(0.01);         MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm fishhash" }
    @{ Algorithms = @("FishHash", "Blake3");                 Fee = @(0.01, 0.007);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm fishhash+alephium" }
#   @{ Algorithms = @("FishHash", "HeavyHashKarlsenV2");     Fee = @(0.01, 0.02);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 2; WarmupTimes = @(45, 25); ExcludePools = @(@(), @()); Arguments = " --algorithm fishhash+karlsenhashv2" } # Not supported yet
    @{ Algorithms = @("FishHash", "SHA512256d");             Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm fishhash+sha512256d" }
    @{ Algorithms = @("FishHash", "SHA3x");                  Fee = @(0.01, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm fishhash+sha3x" }
    @{ Algorithms = @("HeavyHashKarlsenv2", "");             Fee = @(0.02);         MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm karlsenhashv2" }
    @{ Algorithms = @("HeavyHashKarlsenv2", "SHA3x");        Fee = @(0.02);         MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm karlsenhashv2+sha3x" }
    @{ Algorithms = @("KawPow", "");                         Fee = @(0.01);         MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(90, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm kawpow" }
    @{ Algorithms = @("NexaPow", "");                        Fee = @(0.02);         MinMemGiB = 3.0;  Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " --algorithm nexapow" }
    @{ Algorithms = @("Octopus", "");                        Fee = @(0.02);         MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " --algorithm octopus" }
    @{ Algorithms = @("Octopus", "Blake3");                  Fee = @(0.02, 0.007);  MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " --algorithm octopus+alephium" }
#   @{ Algorithms = @("Octopus", "HeavyHashKarlsenV2");      Fee = @(0.02, 0.02);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " --algorithm octopus+karlsenhashv2" } # Not supported yet
    @{ Algorithms = @("Octopus", "SHA512256d");              Fee = @(0.02, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " --algorithm octopus+sha512256d" }
    @{ Algorithms = @("Octopus", "SHA3x");                   Fee = @(0.02, 0.01);   MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " --algorithm octopus+sha3x" }
    @{ Algorithms = @("ProgPowQuai", "");                    Fee = @(0.01);         MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm quai" }
    @{ Algorithms = @("ProgPowZano", "");                    Fee = @(0.01);         MinMemGiB = 0.94; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); Arguments = " --algorithm progpowz" }
    @{ Algorithms = @("SHA512256d", "");                     Fee = @(0.01);         MinMemGiB = 1.0;  Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " --algorithm sha512256d" }
    @{ Algorithms = @("SHA3x","");                           Fee = @(0.01);         MinMemGiB = 1.0;  Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " --algorithm sha3x" }
    @{ Algorithms = @("XelisHash", "");                      Fee = @(0.03);         MinMemGiB = 1.0;  Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " --algorithm xelishash" }
    @{ Algorithms = @("XelisHashV2", "");                    Fee = @(0.02);         MinMemGiB = 1.0;  Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " --algorithm xelishashv2" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] })
$Algorithms = $Algorithms.Where({ -not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIport + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    # $ExcludePools = $_.ExcludePools
                    # ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $ExcludePools[0] -notcontains $_.Name })) { 
                    ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]]) { 
                        # ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $ExcludePools[1] -notcontains $_.Name })) { 
                        ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]]) { 
                            $Pools = @(($Pool0, $Pool1).Where({ $_ }))

                            $MinMemGiB = $_.MinMemGiB + $Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB
                            If ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                $Arguments = $_.Arguments
                                If ("ABEL", "AIPG", "ALPH", "BLOCX", "CFX", "CLORE", "ERGO", "ETC", "ETHW", "GRAM", "HYP", "IRON", "KLS", "NEOX", "NEXA", "NX", "OCTA", "PYI", "RXD", "XEL", "XNA", "XPB", "ZIL" -contains $Pool0.Currency) { $Arguments += " --coin $($Pool0.Currency.ToLower())" }

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
                                    $Arguments += " --username [$Index]$($Pool.User -replace "\..*") --password [$Index]$($Pool.Pass) --worker [$Index]$(If ($Pool.WorkerName) { $Pool.WorkerName } ElseIf ($Pool.User -like "*.*") { $Pool.User -replace "^.+\." } Else { $Config.WorkerName })"

                                    $Index ++
                                }
                                Remove-Variable Pool

                                $Arguments += If ($Pool0.PoolPorts[1] -or ($_.Algorithms[1] -and $Pool1.PoolPorts[1])) { " --no-strict-ssl" } # Parameter cannot be used multiple times

                                # Allow more time to build larger DAGs, must use type cast to keep values in $_
                                $WarmupTimes = [UInt16[]]$_.WarmupTimes
                                $WarmupTimes[0] += [UInt16](($Pool0.DAGsizeGiB + $Pool1.DAGsizeGiB) * 2)

                                # Apply tuning parameters
                                If ($Session.ApplyMinerTweaks -and ($AvailableMinerDevices.Architecture | Sort-Object -Unique) -eq "Pascal" -and $Model -notmatch "^MX\d+") { $Arguments += $_.Tuning }

                                [PSCustomObject]@{ 
                                    API         = "Rigel"
                                    Arguments   = "$Arguments --api-bind 127.0.0.1:$($MinerAPIPort) --no-watchdog --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                    DeviceNames = $AvailableMinerDevices.Name
                                    Fee         = $_.Fee # Dev fee
                                    MinerSet    = $_.MinerSet
                                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                    Name        = $MinerName
                                    Path        = $Path
                                    Port        = $MinerAPIPort
                                    Type        = "NVIDIA"
                                    URI         = $URI
                                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                    Workers      = @($Pools.ForEach({ @{ Pool = $_ } }))
                                }
                            }
                        }
                    }
                }
            )
        }
    )
}
