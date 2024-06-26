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
Version:        6.2.12
Version date:   2024/06/26
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -ne "NVIDIA" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge [Version]"455.23") }))) { Return }

$URI = "https://github.com/nanopool/nanominer/releases/download/v3.9.1/nanominer-windows-3.9.1.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\nanominer.exe"
$DeviceEnumerator = "Slot"

$Algorithms = @(
    [PSCustomObject]@{ Algorithms = @("Autolykos2");                   Type = "AMD"; Fee = @(0.025);        MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 20); ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Autolykos") } # NBMiner-v42.3 is fastest
#   [PSCustomObject]@{ Algorithms = @("Autolykos2", "HeavyHashKaspa"); Type = "AMD"; Fee = @(0.025, 0.025); MinMemGiB = 1.24; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 10); ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Autolykos", " -algo Kaspa") } # NBMiner-v42.3 is fastest
    [PSCustomObject]@{ Algorithms = @("EtcHash");                      Type = "AMD"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45,  0); ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @("");      Arguments = @(" -algo Etchash") } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "HeavyHashKaspa");    Type = "AMD"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @("GCN4");  Arguments = @(" -algo Etchash"," -algo Kaspa") } # ASIC
    [PSCustomObject]@{ Algorithms = @("Ethash");                       Type = "AMD"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @("");      Arguments = @(" -algo Ethash") } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithms = @("Ethash", "HeavyHashKaspa");     Type = "AMD"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @("GCN4");  Arguments = @(" -algo Ethash"," -algo Kaspa") } # ASIC
    [PSCustomObject]@{ Algorithms = @("EthashB3");                     Type = "AMD"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePools = @(@("ZergPool"), @());   ExcludeGPUArchitecture = @();        Arguments = @(" -algo EthashB3") }
#   [PSCustomObject]@{ Algorithms = @("EthashB3", "HeavyHashKaspa");   Type = "AMD"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePools = @(@("ZergPool"), @());   ExcludeGPUArchitecture = @("GCN4");  Arguments = @(" -algo EthashB3", " -algo Kaspa") } # ASIC
    [PSCustomObject]@{ Algorithms = @("EvrProgPow");                   Type = "AMD"; Fee = @(0.02);         MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Evrprogpow") }
    [PSCustomObject]@{ Algorithms = @("FiroPow");                      Type = "AMD"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo FiroPow") }
    [PSCustomObject]@{ Algorithms = @("FishHash");                     Type = "AMD"; Fee = @(0.01);         MinMemGiB = 6;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @("RDNA1"); Arguments = @(" -algo Fishhash") } # https://github.com/nanopool/nanominer/issues/427
    [PSCustomObject]@{ Algorithms = @("HeavyHashKarlsen");             Type = "AMD"; Fee = @(0.01);         MinMemGiB = 2;    MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Karlsen") }
#   [PSCustomObject]@{ Algorithms = @("HeavyHashKaspa");               Type = "AMD"; Fee = @(0.01);         MinMemGiB = 2;    MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Kaspa") } # ASIC
    [PSCustomObject]@{ Algorithms = @("KawPow");                       Type = "AMD"; Fee = @(0.02);         MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@("ProHashing"), @()); ExcludeGPUArchitecture = @();        Arguments = @(" -algo KawPow") } # TeamRedMiner-v0.10.21 is fastest
    [PSCustomObject]@{ Algorithms = @("UbqHash");                      Type = "AMD"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Ubqhash") } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithms = @("VertHash");                     Type = "AMD"; Fee = @(0.01);         MinMemGiB = 3;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Verthash") }

#   [PSCustomObject]@{ Algorithms = @("Randomx");    Type = "CPU"; Fee = @(0.02); MinerSet = 3; WarmupTimes = @(45, 0); ExcludePools = @(@(), @()); Arguments = @(" -algo Randomx") } # ASIC
    [PSCustomObject]@{ Algorithms = @("RandomNevo"); Type = "CPU"; Fee = @(0.02); MinerSet = 3; WarmupTimes = @(45, 0); ExcludePools = @(@(), @()); Arguments = @(" -algo RandomNEVO") }
    [PSCustomObject]@{ Algorithms = @("VerusHash");  Type = "CPU"; Fee = @(0.02); MinerSet = 3; WarmupTimes = @(69, 0); ExcludePools = @(@(), @()); Arguments = @(" -algo Verushash") }

    [PSCustomObject]@{ Algorithms = @("EtcHash");                    Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @(); Arguments = @(" -algo Etchash") }
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "HeavyHashKaspa");  Type = "INTEL"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 45); ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @(); Arguments = @(" -algo Etchash", " -algo Kaspa") } # ASIC
    [PSCustomObject]@{ Algorithms = @("Ethash");                     Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @(); Arguments = @(" -algo Ethash") }
#   [PSCustomObject]@{ Algorithms = @("Ethash", "HeavyHashKaspa");   Type = "INTEL"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @(); Arguments = @(" -algo Ethash", " -algo Kaspa") } # ASIC
    [PSCustomObject]@{ Algorithms = @("EthashB3");                   Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@("ZergPool"), @());   ExcludeGPUArchitecture = @(); Arguments = @(" -algo EthashB3") }
#   [PSCustomObject]@{ Algorithms = @("EthashB3", "HeavyHashKaspa"); Type = "INTEL"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; MinerSet = 2; WarmupTimes = @(45, 60); ExcludePools = @(@("ZergPool"), @());   ExcludeGPUArchitecture = @(); Arguments = @(" -algo EthashB3", " -algo Kaspa") } # ASIC
    [PSCustomObject]@{ Algorithms = @("EvrProgPow");                 Type = "INTEL"; Fee = @(0.02);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @(); Arguments = @(" -algo Evrprogpow") }
    [PSCustomObject]@{ Algorithms = @("FishHash");                   Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 6;    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @(); Arguments = @(" -algo Fishhash") }
    [PSCustomObject]@{ Algorithms = @("HeavyHashKarlsen");           Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @(); Arguments = @(" -algo Karlsen") }
#   [PSCustomObject]@{ Algorithms = @("HeavyHashKaspa");             Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @(); Arguments = @(" -algo Kaspa") } # ASIC
    [PSCustomObject]@{ Algorithms = @("KawPow");                     Type = "INTEL"; Fee = @(0.02);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@("ProHashing"), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -algo KawPow") } # Trex-v0.26.8 is fastest
    [PSCustomObject]@{ Algorithms = @("Octopus");                    Type = "INTEL"; Fee = @(0.02);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @(); Arguments = @(" -algo Octopus") } # NBMiner-v42.3 is faster
    [PSCustomObject]@{ Algorithms = @("UbqHash");                    Type = "INTEL"; Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 2; WarmupTimes = @(75, 45); ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @(); Arguments = @(" -algo Ubqhash") }

    [PSCustomObject]@{ Algorithms = @("Autolykos2");                   Type = "NVIDIA"; Fee = @(0.025);        MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Autolykos") } # Trex-v0.26.8 is fastest
#   [PSCustomObject]@{ Algorithms = @("Autolykos2", "HeavyHashKaspa"); Type = "NVIDIA"; Fee = @(0.025, 0.025); MinMemGiB = 1.24; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Autolykos", " -algo Kaspa") } # ASIC
    [PSCustomObject]@{ Algorithms = @("EtcHash");                      Type = "NVIDIA"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Etchash") } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "HeavyHashKaspa");    Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Etchash", " -algo Kaspa") } # ASIC
    [PSCustomObject]@{ Algorithms = @("Ethash");                       Type = "NVIDIA"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @("Other"); Arguments = @(" -algo Ethash") } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithms = @("Ethash", "HeavyHashKaspa");     Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePools = @(@("ZergPool"), @());   ExcludeGPUArchitecture = @("Other"); Arguments = @(" -algo Ethash", " -algo Kaspa") } # ASIC
    [PSCustomObject]@{ Algorithms = @("EthashB3");                     Type = "NVIDIA"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@("ZergPool"), @());   ExcludeGPUArchitecture = @("Other"); Arguments = @(" -algo EthashB3") }
#   [PSCustomObject]@{ Algorithms = @("EthashB3", "HeavyHashKaspa");   Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @("Other"); Arguments = @(" -algo EthashB3", " -algo Kaspa") } # ASIC
    [PSCustomObject]@{ Algorithms = @("EvrProgPow");                   Type = "NVIDIA"; Fee = @(0.02);         MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Evrprogpow") }
    [PSCustomObject]@{ Algorithms = @("FiroPow");                      Type = "NVIDIA"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo FiroPow") }
    [PSCustomObject]@{ Algorithms = @("FishHash");                     Type = "NVIDIA"; Fee = @(0.01);         MinMemGiB = 6;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Fishhash") }
    [PSCustomObject]@{ Algorithms = @("HeavyHashKarlsen");             Type = "NVIDIA"; Fee = @(0.01);         MinMemGiB = 2;    MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Karlsen") }
#   [PSCustomObject]@{ Algorithms = @("HeavyHashKaspa");               Type = "NVIDIA"; Fee = @(0.01);         MinMemGiB = 2;    MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Kaspa") } # ASIC
    [PSCustomObject]@{ Algorithms = @("KawPow");                       Type = "NVIDIA"; Fee = @(0.02);         MinMemGiB = 1.08; MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@("ProHashing"), @()); ExcludeGPUArchitecture = @();        Arguments = @(" -algo KawPow") } # Trex-v0.26.8 is fastest
    [PSCustomObject]@{ Algorithms = @("Octopus");                      Type = "NVIDIA"; Fee = @(0.02);         MinMemGiB = 1.08; MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Octopus") } # NBMiner-v42.3 is faster
    [PSCustomObject]@{ Algorithms = @("HeavyHashPyrin");               Type = "NVIDIA"; Fee = @(0.02);         MinMemGiB = 2;    MinerSet = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo pyrin") }
    [PSCustomObject]@{ Algorithms = @("UbqHash");                      Type = "NVIDIA"; Fee = @(0.01);         MinMemGiB = 1.08; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             ExcludeGPUArchitecture = @();        Arguments = @(" -algo Ubqhash") } # PhoenixMiner-v6.2c is fastest
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms.Where({ -not $_.Algorithms[1] }).ForEach({ $_.Algorithms += "" })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] -and $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]].Name -notin $_.ExcludePools[0] })
$Algorithms = $Algorithms.Where({ $MinerPools[1][$_.Algorithms[1]].Name -notin $_.ExcludePools[1] })
$Algorithms = $Algorithms.Where({ $Config.SSL -ne "Always" -or ($MinerPools[0][$_.Algorithms[0]].SSLSelfSignedCertificate -ne $true -and (-not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]].SSLSelfSignedCertificate -ne $true)) })

If ($Algorithms) { 

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            If ($MinerDevices = $Devices | Where-Object Model -EQ $_.Model) { 
                $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

                ($Algorithms | Where-Object Type -EQ $_.Type).ForEach(
                    { 
                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        If ($SupportedMinerDevices = $MinerDevices.Where({ $_.Type -eq "CPU" -or $_.Architecture -notin $ExcludeGPUArchitecture })) { 

                            $ExcludePools = $_.ExcludePools
                            ForEach ($Pool0 in $MinerPools[0][$_.Algorithms[0]].Where({ $_.Name -notin $ExcludePools[0] -and ($Config.SSL -ne "Always" -or $_.SSLSelfSignedCertificate -ne $true) }) | Select-Object -Last $(If ($_.Type -eq "CPU") { 1 } Else { $MinerPools[0][$_.Algorithms[0]].Count })) { 
                                ForEach ($Pool1 in $MinerPools[1][$_.Algorithms[1]].Where({ $_.Name -notin $ExcludePools[1] -and ($Config.SSL -ne "Always" -or $_.SSLSelfSignedCertificate -ne $true) }) | Select-Object -Last $(If ($_.Type -eq "CPU") { 1 } Else { $MinerPools[1][$_.Algorithms[1]].Count })) { 
                                    $Pools = @(($Pool0, $Pool1).Where({ $_ }))

                                    $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                                    If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.Type -eq "CPU" -or $_.MemoryGiB -ge $MinMemGiB })) { 

                                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$($AvailableMinerDevices.Model | Select-Object -Unique)-$($Pool0.AlgorithmVariant)$(If ($Pool1) { "&$($Pool1.AlgorithmVariant)" })"

                                        $Arguments = ""
                                        ForEach ($Pool in $Pools) { 
                                            $Arguments += "$($_.Arguments[$Pools.IndexOf($Pool)])"
                                            $Arguments += If ($Pool.PoolPorts[1] -and $Pool.SSLSelfSignedCertificate -ne $true) { " -pool1 $($Pool.Host):$($Pool.PoolPorts[1])" } Else { " -pool1 $($Pool.Host):$($Pool.PoolPorts[0]) -useSSL false" }
                                            $Arguments += " -wallet $($Pool.User -replace '\..+')"
                                            $Arguments += " -rigName $($Pool.User)$(If ($Pool.WorkerName -and $Pool.User -notmatch "\.$($Pool.WorkerName)$") { $Pool.WorkerName })"
                                            $Arguments += " -rigPassword $($Pool.Pass)"
                                            $Arguments += " -devices $(($AvailableMinerDevices | Sort-Object Name -Unique).ForEach({ '{0:x}' -f $_.$DeviceEnumerator })) -join ',')"
                                        }
                                        Remove-Variable Pool

                                        $Arguments += " -mport 0 -webPort $MinerAPIPort -checkForUpdates false -noLog true -watchdog false"

                                        # Apply tuning parameters
                                        If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                                        If ($_.Algorithms -contains "VertHash") { 
                                            If ((Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -eq 1283457024) { 
                                                If (-not (Get-Item -Path ".\Bin\$Name\VertHash.dat" -ErrorAction Ignore).length -eq 1283457024) { 
                                                    New-Item -ItemType HardLink -Path ".\Bin\$Name\VertHash.dat" -Target $Variables.VerthashDatPath -Force | Out-Null
                                                }
                                            }
                                            Else { 
                                                $PrerequisitePath = $Variables.VerthashDatPath
                                                $PrerequisiteURI = "https://github.com/UselessGuru/UG-Miner-Extras/releases/download/VertHashDataFile/VertHash.dat"
                                            }
                                        }
                                        Else { 
                                            $PrerequisitePath = ""
                                            $PrerequisiteURI = ""
                                        }

                                        [PSCustomObject]@{ 
                                            API              = "NanoMiner"
                                            Arguments        = $Arguments
                                            DeviceNames      = $AvailableMinerDevices.Name
                                            Fee              = $_.Fee # Dev fee
                                            MinerSet         = $_.MinerSet
                                            MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/#/"
                                            Name             = $MinerName
                                            Path             = $Path
                                            Port             = $MinerAPIPort
                                            PrerequisitePath = $PrerequisitePath
                                            PrerequisiteURI  = $PrerequisiteURI
                                            Type             = $_.Type
                                            URI              = $URI
                                            WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                            Workers          = @($Pools.ForEach({ @{ Pool = $_ } }))
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
