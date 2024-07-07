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
Version:        6.2.15
Version date:   2024/07/07
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0" }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/TeamRedMiner/teamredminer-v0.10.21-win.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\teamredminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithms = @("Autolykos2");                       Fee = @(0.02);       MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=autolykos2" }
    @{ Algorithms = @("Autolykos2", "Blake3");             Fee = @(0.02, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @("NiceHash")); ExcludeGPUArchitecture = @();                                  Arguments = " --algo=autolykos2" }
    @{ Algorithms = @("Autolykos2", "HeavyHashKarlsea");   Fee = @(0.02, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=autolykos2" }
#   @{ Algorithms = @("Autolykos2", "HeavyHashKaspa");     Fee = @(0.02, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=autolykos2" } # ASIC
    @{ Algorithms = @("Autolykos2", "HeavyHashPyrin");     Fee = @(0.02, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=autolykos2" }
    @{ Algorithms = @("Autolykos2", "FishHash");           Fee = @(0.02, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @("NiceHash")); ExcludeGPUArchitecture = @();                                  Arguments = " --algo=autolykos2" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    @{ Algorithms = @("Blake3");                           Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@("NiceHash"), @()); ExcludeGPUArchitecture = @();                                  Arguments = " --algo=alph" }
    @{ Algorithms = @("Chukwa");                           Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=trtl_chukwa" }
    @{ Algorithms = @("Chukwa2");                          Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=trtl_chukwa2" }
    @{ Algorithms = @("CryptonightCcx");                   Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cn_conceal --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightHeavy");                 Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cn_heavy --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightHaven");                 Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cn_haven --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightHeavyTube");             Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cn_saber --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
#   @{ Algorithms = @("CryptonightR");                     Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 3; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnr --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" } # ASIC
    @{ Algorithms = @("CryptonightV1");                    Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightDouble");                Fee = @(0.025);      MinMemGiB = 4.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_dbl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" } # XmRig-v6.21.3.15 is fastest
    @{ Algorithms = @("CryptonightHalf");                  Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_half --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightTurtle");                Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_trtl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightRwz");                   Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_rwz --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CryptonightUpx");                   Fee = @(0.025);      MinMemGiB = 3.0;  MinerSet = 1; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_upx2 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    @{ Algorithms = @("CuckarooD29");                      Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cuckarood29_grin" } # 2GB is not enough
#   @{ Algorithms = @("Cuckatoo31");                       Fee = @(0.025);      MinMemGiB = 3.0;  MinerSet = 3; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cuckatoo31_grin" } # ASIC
    @{ Algorithms = @("EtcHash");                          Fee = @(0.01);       MinMemGiB = 0.77; MinerSet = 1; WarmupTimes = @(45, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=etchash" } # PhoenixMiner-v6.2c is fastest
    @{ Algorithms = @("EtcHash", "Blake3");                Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @("NiceHash")); ExcludeGPUArchitecture = @();                                  Arguments = " --algo=etchash" }
    @{ Algorithms = @("EtcHash", "HeavyHashKarlsen");      Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=etchash" }
#   @{ Algorithms = @("EtcHash", "HeavyHashKaspa");        Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=etchash" } # ASIC
    @{ Algorithms = @("EtcHash", "HeavyHashPyrin");        Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=etchash" }
    @{ Algorithms = @("EtcHash", "FishHash");              Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @("NiceHash")); ExcludeGPUArchitecture = @();                                  Arguments = " --algo=etchash" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    @{ Algorithms = @("Ethash");                           Fee = @(0.01);       MinMemGiB = 0.77; MinerSet = 0; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=ethash" } # PhoenixMiner-v6.2c is fastest
    @{ Algorithms = @("Ethash", "Blake3");                 Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @("NiceHash")); ExcludeGPUArchitecture = @();                                  Arguments = " --algo=ethash" }
    @{ Algorithms = @("Ethash", "HeavyHashKarlsen");       Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=ethash" }
#   @{ Algorithms = @("Ethash", "HeavyHashKaspa");         Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=ethash" } # ASIC
    @{ Algorithms = @("Ethash", "HeavyHashPyrin");         Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=ethash" }
    @{ Algorithms = @("Ethash", "FishHash");               Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @("NiceHash")); ExcludeGPUArchitecture = @();                                  Arguments = " --algo=ethash" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    @{ Algorithms = @("EthashSHA256");                     Fee = @(0.01);       MinMemGiB = 0.77; MinerSet = 0; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=abel" }
    @{ Algorithms = @("EthashSHA256", "Blake3");           Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @("NiceHash")); ExcludeGPUArchitecture = @();                                  Arguments = " --algo=abel" }
    @{ Algorithms = @("EthashSHA256", "HeavyHashKarlsen"); Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=abel" }
#   @{ Algorithms = @("EthashSHA256", "HeavyHashKaspa");   Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=abel" } # ASIC
    @{ Algorithms = @("EthashSHA256", "HeavyHashPyrin");   Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=abel" }
    @{ Algorithms = @("EthashSHA256", "FishHash");         Fee = @(0.01, 0.01); MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @("NiceHash")); ExcludeGPUArchitecture = @();                                  Arguments = " --algo=abel" }
    @{ Algorithms = @("FiroPow");                          Fee = @(0.02);       MinMemGiB = 0.77; MinerSet = 0; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("RDNA3");                           Arguments = " --algo=firopow" } # Wildrig-v0.40.5 is fastest on Polaris
    @{ Algorithms = @("FishHash");                         Fee = @(0.01);       MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@("NiceHash"), @()); ExcludeGPUArchitecture = @();                                  Arguments = " --algo=ironfish" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    @{ Algorithms = @("KawPow");                           Fee = @(0.02);       MinMemGiB = 0.77; MinerSet = 0; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=kawpow" } # Wildrig-v0.40.5 is fastest on Polaris
    @{ Algorithms = @("HeavyHashKarlsen");                 Fee = @(0.01);       MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=karlsen" }
#   @{ Algorithms = @("HeavyHashKaspa");                   Fee = @(0.01);       MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=kas" } # ASIC
    @{ Algorithms = @("HeavyHashPyrin");                   Fee = @(0.01);       MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @();                                  Arguments = " --algo=pyrin" }
#   @{ Algorithms = @("Lyra2Z");                           Fee = @(0.03);       MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=lyra2z" } # ASIC
#   @{ Algorithms = @("Lyra2RE3");                         Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=lyra2rev3" } # ASIC
    @{ Algorithms = @("MTP");                              Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(45, 45);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA3");                   Arguments = " --algo=mtp" } # Algorithm is dead
    @{ Algorithms = @("Nimiq");                            Fee = @(0.025);      MinMemGiB = 4.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA3");                   Arguments = " --algo=nimiq" }
    @{ Algorithms = @("Phi2");                             Fee = @(0.03);       MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=phi2" }
    @{ Algorithms = @("VertHash");                         Fee = @(0.02);       MinMemGiB = 4.0;  MinerSet = 1; WarmupTimes = @(75, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1");                            Arguments = " --algo=verthash --verthash_file=..\.$($Variables.VerthashDatPath)" }
#   @{ Algorithms = @("X16r");                             Fee = @(0.025);      MinMemGiB = 4.0;  MinerSet = 3; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=x16r" } # ASIC
    @{ Algorithms = @("X16rv2");                           Fee = @(0.025);      MinMemGiB = 4.0;  MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=x16rv2" }
    @{ Algorithms = @("X16s");                             Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=x16s" }
    @{ Algorithms = @("X16rt");                            Fee = @(0.025);      MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());           ExcludeGPUArchitecture = @("GCN1", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=x16rt" } # FPGA
) 

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms.Where({ -not $_.Algorithms[1] }).ForEach({ $_.Algorithms += "" })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] -and $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]].Name -notin $_.ExcludePools[0] })
$Algorithms = $Algorithms.Where({ $MinerPools[1][$_.Algorithms[1]].Name -notin $_.ExcludePools[1] })
$Algorithms = $Algorithms.Where({ $Config.SSL -ne "Always" -or ($MinerPools[0][$_.Algorithms[0]].SSLSelfSignedCertificate -eq $false -and (-not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]].SSLSelfSignedCertificate -ne $true)) }) # https://github.com/todxx/teamredminer/issues/773

If ($Algorithms) { 

    ($Devices | Select-Object Model -Unique).ForEach(
        { 
            If ($MinerDevices = $Devices | Where-Object Model -EQ $_.Model) { 
                $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

                $Algorithms.ForEach(
                    { 
                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        If ($SupportedMinerDevices = $MinerDevices.Where({ $_.Architecture -notin $ExcludeGPUArchitecture })) { 

                            If ($_.Algorithms -contains "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                                $PrerequisitePath = $Variables.VerthashDatPath
                                $PrerequisiteURI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/TeamRedMiner/TeamRedMiner-v0.10.21-win.zip"
                            }
                            Else { 
                                $PrerequisitePath = ""
                                $PrerequisiteURI = ""
                            }

                            $ExcludePools = $_.ExcludePools
                            ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $_.Name -notin $ExcludePools[0] -and ($Config.SSL -ne "Always" -or $_.SSLSelfSignedCertificate -ne $true) })) { 
                                ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $_.Name -notin $ExcludePools[1] -and ($Config.SSL -ne "Always" -or $_.SSLSelfSignedCertificate -ne $true) })) { 

                                    $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                                    If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                        $Arguments = $_.Arguments
                                        $Arguments += " --pool_force_ensub --url=$(If ($Pool0.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1)"
                                        $Arguments += Switch ($Pool0.Protocol) { 
                                            "ethstratumnh" { " --eth_stratum_mode=nicehash" }
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
                                        If ($_.Algorithms[0] -match '^Et(c)hash.+' -and $AvailableMinerDevices.Model -notmatch "^Radeon RX [0-9]{3} ") { $_.Fee = @(0.0075) } # Polaris cards 0.75%

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
        }
    )
}