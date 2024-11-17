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
Version:        6.3.14
Version date:   2024/11/17
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0" }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/TeamRedMiner/teamredminer-v0.10.21-win.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\teamredminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithms = @("Autolykos2");                       Fee = @(0.02);       MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=autolykos2" }
    @{ Algorithms = @("Autolykos2", "Blake3");             Fee = @(0.02, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=autolykos2" }
    @{ Algorithms = @("Autolykos2", "HeavyHashKarlsea");   Fee = @(0.02, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=autolykos2" }
#   @{ Algorithms = @("Autolykos2", "HeavyHashKaspa");     Fee = @(0.02, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=autolykos2" } # ASIC
    @{ Algorithms = @("Autolykos2", "HeavyHashPyrin");     Fee = @(0.02, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=autolykos2" }
    @{ Algorithms = @("Autolykos2", "FishHash");           Fee = @(0.02, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=autolykos2" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    @{ Algorithms = @("Blake3");                           Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@("NiceHash"), @()); Arguments = " --algo=alph" }
    @{ Algorithms = @("Chukwa");                           Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=trtl_chukwa" }
    @{ Algorithms = @("Chukwa2");                          Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=trtl_chukwa2" }
    @{ Algorithms = @("CryptonightCcx");                   Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=cn_conceal --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightHeavy");                 Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=cn_heavy --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightHaven");                 Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=cn_haven --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightHeavyTube");             Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=cn_saber --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
#   @{ Algorithms = @("CryptonightR");                     Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 3; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=cnr --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" } # ASIC
    @{ Algorithms = @("CryptonightV1");                    Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=cnv8 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightDouble");                Fee = @(0.025);      MinMemGiB = 4.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=cnv8_dbl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" } # XmRig-v6.22.0.3 is fastest
    @{ Algorithms = @("CryptonightHalf");                  Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=cnv8_half --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightTurtle");                Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=cnv8_trtl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightRwz");                   Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=cnv8_rwz --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightUpx");                   Fee = @(0.025);      MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=cnv8_upx2 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CuckarooD29");                      Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=cuckarood29_grin" } # 2GB is not enough
#   @{ Algorithms = @("Cuckatoo31");                       Fee = @(0.025);      MinMemGiB = 3.0;  MinerSet = 3; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=cuckatoo31_grin" } # ASIC
    @{ Algorithms = @("EtcHash");                          Fee = @(0.01);       MinMemGiB = 0.77; MinerSet = 1; WarmupTimes = @(45, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=etchash" } # PhoenixMiner-v6.2c is fastest
    @{ Algorithms = @("EtcHash", "Blake3");                Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=etchash" }
    @{ Algorithms = @("EtcHash", "HeavyHashKarlsen");      Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=etchash" }
#   @{ Algorithms = @("EtcHash", "HeavyHashKaspa");        Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=etchash" } # ASIC
    @{ Algorithms = @("EtcHash", "HeavyHashPyrin");        Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=etchash" }
    @{ Algorithms = @("EtcHash", "FishHash");              Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=etchash" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    @{ Algorithms = @("Ethash");                           Fee = @(0.01);       MinMemGiB = 0.77; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=ethash" } # PhoenixMiner-v6.2c is fastest
    @{ Algorithms = @("Ethash", "Blake3");                 Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=ethash" }
    @{ Algorithms = @("Ethash", "HeavyHashKarlsen");       Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=ethash" }
#   @{ Algorithms = @("Ethash", "HeavyHashKaspa");         Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=ethash" } # ASIC
    @{ Algorithms = @("Ethash", "HeavyHashPyrin");         Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=ethash" }
    @{ Algorithms = @("Ethash", "FishHash");               Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=ethash" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    @{ Algorithms = @("EthashSHA256");                     Fee = @(0.01);       MinMemGiB = 0.77; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=abel" }
    @{ Algorithms = @("EthashSHA256", "Blake3");           Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=abel" }
    @{ Algorithms = @("EthashSHA256", "HeavyHashKarlsen"); Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=abel" }
#   @{ Algorithms = @("EthashSHA256", "HeavyHashKaspa");   Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=abel" } # ASIC
    @{ Algorithms = @("EthashSHA256", "HeavyHashPyrin");   Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=abel" }
    @{ Algorithms = @("EthashSHA256", "FishHash");         Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @("NiceHash")); Arguments = " --algo=abel" }
    @{ Algorithms = @("FiroPow");                          Fee = @(0.02);       MinMemGiB = 0.77; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @("RDNA3");                           ExcludePools = @(@(), @());           Arguments = " --algo=firopow" } # Wildrig-v0.40.9 is fastest on Polaris
    @{ Algorithms = @("FishHash");                         Fee = @(0.01);       MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@("NiceHash"), @()); Arguments = " --algo=ironfish" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    @{ Algorithms = @("KawPow");                           Fee = @(0.02);       MinMemGiB = 0.77; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=kawpow" } # Wildrig-v0.40.9 is fastest on Polaris
    @{ Algorithms = @("HeavyHashKarlsen");                 Fee = @(0.01);       MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=karlsen" }
#   @{ Algorithms = @("HeavyHashKaspa");                   Fee = @(0.01);       MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=kas" } # ASIC
    @{ Algorithms = @("HeavyHashPyrin");                   Fee = @(0.01);       MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @();                                  ExcludePools = @(@(), @());           Arguments = " --algo=pyrin" }
#   @{ Algorithms = @("Lyra2Z");                           Fee = @(0.03);       MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=lyra2z" } # ASIC
#   @{ Algorithms = @("Lyra2RE3");                         Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=lyra2rev3" } # ASIC
#   @{ Algorithms = @("MTP");                              Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUarchitectures = @("GCN1", "RDNA3");                   ExcludePools = @(@(), @());           Arguments = " --algo=mtp" } # Algorithm is dead
    @{ Algorithms = @("Nimiq");                            Fee = @(0.025);      MinMemGiB = 4.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA3");                   ExcludePools = @(@(), @());           Arguments = " --algo=nimiq" }
    @{ Algorithms = @("Phi2");                             Fee = @(0.03);       MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=phi2" }
    @{ Algorithms = @("VertHash");                         Fee = @(0.02);       MinMemGiB = 4.0;  MinerSet = 1; WarmupTimes = @(75, 15); ExcludeGPUarchitectures = @("GCN1");                            ExcludePools = @(@(), @());           Arguments = " --algo=verthash --verthash_file=..\.$($Variables.VerthashDatPath)" }
#   @{ Algorithms = @("X16r");                             Fee = @(0.025);      MinMemGiB = 4.0;  MinerSet = 3; WarmupTimes = @(60, 60); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=x16r" } # ASIC
    @{ Algorithms = @("X16rv2");                           Fee = @(0.025);      MinMemGiB = 4.0;  MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=x16rv2" }
    @{ Algorithms = @("X16s");                             Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=x16s" }
    @{ Algorithms = @("X16rt");                            Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUarchitectures = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(@(), @());           Arguments = " --algo=x16rt" } # FPGA
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms.Where({ -not $_.Algorithms[1] }).ForEach({ $_.Algorithms += "" })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] -and $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] })
$Algorithms = $Algorithms.Where({ $Config.SSL -ne "Always" -or ($MinerPools[0][$_.Algorithms[0]].SSLselfSignedCertificate -eq $false -and (-not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]].SSLselfSignedCertificate -eq $false)) }) # https://github.com/todxx/teamredminer/issues/773

If ($Algorithms) { 

    ($Devices | Sort-Object Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    If ($SupportedMinerDevices = $MinerDevices.Where({ $ExcludeGPUarchitectures -notcontains $_.Architecture })) { 

                        If ($_.Algorithms -contains "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                            $PrerequisitePath = $Variables.VerthashDatPath
                            $PrerequisiteURI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/TeamRedMiner/TeamRedMiner-v0.10.21-win.zip"
                        }
                        Else { 
                            $PrerequisitePath = ""
                            $PrerequisiteURI = ""
                        }

                        $ExcludePools = $_.ExcludePools
                        ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $ExcludePools[0] -notcontains $_.Name -and ($Config.SSL -ne "Always" -or $_.SSLselfSignedCertificate -ne $true) })) { 
                            ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $ExcludePools[1] -notcontains $_.Name -and ($Config.SSL -ne "Always" -or $_.SSLselfSignedCertificate -ne $true) })) { 

                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                                If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                    $Arguments = $_.Arguments
                                    $Arguments += " --pool_force_ensub --url=$(If ($Pool0.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1)"
                                    Switch ($Pool0.Protocol) { 
                                        "ethstratumnh" { $Arguments += " --eth_stratum_mode=nicehash" }
                                    }
                                    $Arguments += " --user=$($Pool0.User)$(If ($Pool0.WorkerName -and $Pool0.User -notmatch "\.$($Pool0.WorkerName)$") { ".$($Pool0.WorkerName)" })"
                                    $Arguments += " --pass=$($Pool0.Pass)"

                                    If ($_.Algorithms[1]) { 
                                        Switch ($_.Algorithms[1]) { 
                                            "Blake3"           { $Arguments += " --alph_start" }
                                            "FishHash"         { $Arguments += " --iron_start" }
                                            "HeavyHashKarlsen" { $Arguments += " --karlsen_start" }
                                            "HeavyHashKaspa"   { $Arguments += " --kas_start" }
                                            "HeavyHashPyrin"   { $Arguments += " --pyrin_start" }
                                        }
                                        $Arguments += " --url=$(If ($Pool1.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1)"
                                        $Arguments += " --user=$($Pool1.User)$(If ($Pool1.WorkerName -and $Pool1.User -notmatch "\.$($Pool1.WorkerName)$") { ".$($Pool1.WorkerName)" })"
                                        $Arguments += " --pass=$($Pool1.Pass)"
                                        Switch ($_.Algorithms[1]) { 
                                            "Blake3"           { $Arguments += " --alph_end" }
                                            "HeavyHashKarlsen" { $Arguments += " --karlsen_end" }
                                            "HeavyHashKaspa"   { $Arguments += " --kas_end" }
                                            "HeavyHashPyrin"   { $Arguments += " --pyrin_end" }
                                            "IronFish"         { $Arguments += " --iron_end" }
                                        }
                                    }
                                    If ($_.Algorithms[0] -match '^Et(c)hash.+' -and $AvailableMinerDevices.Model -notmatch "^Radeon RX [0-9]{3} .+") { $_.Fee = @(0.0075) } # Polaris cards 0.75%

                                    [PSCustomObject]@{ 
                                        API              = "Xgminer"
                                        Arguments        = "$Arguments --no_gpu_monitor --init_style=3 --hardware=gpu --api_listen=127.0.0.1:$MinerAPIPort --devices=$(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:d}' -f $_ }) -join ',')"
                                        DeviceNames      = $AvailableMinerDevices.Name
                                        Fee              = $_.Fee # Dev fee
                                        MinerSet         = $_.MinerSet
                                        Name             = $MinerName
                                        Path             = $Path
                                        Port             = $MinerAPIPort
                                        PrerequisitePath = $PrerequisitePath
                                        PrerequisiteURI  = $PrerequisiteURI
                                        Type             = "AMD"
                                        URI              = $URI
                                        WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
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