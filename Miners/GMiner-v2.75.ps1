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
Version:        6.7.19
Version date:   2026/01/08
#>

if (-not ($Devices = $Session.EnabledDevices.Where({ ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or $_.OpenCL.ComputeCapability -ge "5.0" }))) { return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/GMiner/GMiner2.75.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\miner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithm = "Equihash1927"; Fee = @(0.02); MinMemGiB = 2.8; Type = "AMD"; Tuning = ""; WarmupTimes = @(30, 0); ExcludePools = @(); AutoCoinPers = " --pers auto"; Arguments = " --algo equihash192_7 --cuda 0 --opencl 1" } # FPGA

    @{ Algorithm = "Equihash1927"; Fee = @(0.02); MinMemGiB = 2.8; Type = "NVIDIA"; Tuning = ""; WarmupTimes = @(30, 0); ExcludePools = @(); AutoCoinPers = " --pers auto"; Arguments = " --algo equihash192_7 --cuda 1 --opencl 0" } # FPGA
)

$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

if ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Top 1)

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    # $ExcludePools = $_.ExcludePools
                    # foreach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 
                    foreach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                        $MinMemGiB = $_.MinMemGiB + $Pool.DAGsizeGiB
                        # Windows 10 requires more memory on some algos
                        if ($_.Algorithm -match 'Cuckaroo.*|Cuckoo.*' -and [System.Environment]::OSVersion.Version -ge [System.Version]"10.0.0.0") { $MinMemGiB += 1 }
                        if ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                            $Arguments = "$($_.Arguments) --server $($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --pass $($Pool.Pass)"

                            if ($null -ne $Pool.DAGsizeGiB -and "MiningPoolHub", "NiceHash" -contains $Pool.Name) { $Arguments += " --proto stratum" }
                            if ($Pool.PoolPorts[1]) { $Arguments += " --ssl 1" }
                            if ($_.AutoCoinPers) { $Arguments += Get-EquihashCoinPers -Command " --pers " -Currency $Pool.Currency -DefaultCommand $_.AutoCoinPers }

                            # Contest ETH address (if ETH wallet is specified in config)
                            # $Arguments += If ($Session.Config.Wallets.ETH) { " --contest_wallet $($Session.Config.Wallets.ETH)" } else { " --contest_wallet 0x92e6F22C1493289e6AD2768E1F502Fc5b414a287" }

                            # Apply tuning parameters
                            if ($Session.ApplyMinerTweaks) { $_.Arguments += $_.Tuning }

                            [PSCustomObject]@{ 
                                API         = "Gminer"
                                Arguments   = "$Arguments --api $MinerAPIPort --watchdog 0 --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join " ")"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = $_.Fee # Dev fee
                                MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = $Type
                                URI         = $URI
                                WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}