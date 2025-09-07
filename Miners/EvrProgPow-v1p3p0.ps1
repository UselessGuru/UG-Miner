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
Version:        6.5.11
Version date:   2025/09/07
#>

If (-not ($Devices = $Session.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = "https://github.com/EvrmoreOrg/evrprogpowminer/releases/download/v1.3.0-a66d921b/evrprogpowminer-windows64-v1p3p0-a66d921b.7z"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\evrprogpowminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithm = "EvrProgPow"; MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(75, 10); ExcludePools = @(); Arguments = "" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Session.ConfigRunning.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model })
            $MinerAPIPort = $Session.ConfigRunning.APIport + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    If ($SupportedMinerDevices = $MinerDevices) { 
                        # $ExcludePools = $_.ExcludePools
                        # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                            $MinMemGiB = $_.MinMemGiB + $Pool.DAGsizeGiB 
                            If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                                $Protocol = Switch ($Pool.Protocol) { 
                                    "ethproxy"    { "stratum1"; Break }
                                    "ethstratum1" { "stratum2"; Break }
                                    "ethstratum2" { "stratum2"; Break }
                                    Default       { "stratum" }
                                }
                                $Protocol += If ($Pool.PoolPorts[1]) { "+tls" } Else { "+tcp" }

                                [PSCustomObject]@{ 
                                    API         = "EthMiner"
                                    Arguments   = "$($_.Arguments) --pool $($Protocol)://$([System.Web.HttpUtility]::UrlEncode($Pool.User)):$([System.Web.HttpUtility]::UrlEncode($Pool.Pass))@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --farm-recheck 10000 --farm-retries 40 --work-timeout 100000 --response-timeout 720 --api-port -$($MinerAPIPort) --cuda --cuda-devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                    DeviceNames = $AvailableMinerDevices.Name
                                    EnvVars     = @("SSL_NOVERIFY=TRUE")
                                    Fee         = @(0) # Dev fee
                                    MinerSet    = $_.MinerSet
                                    Name        = $MinerName
                                    Path        = $Path
                                    Port        = $MinerAPIPort
                                    Type        = "NVIDIA"
                                    URI         = $URI
                                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                    Workers      = @(@{ Pool = $Pool })
                                }
                            }
                        }
                    }
                }
            )
        }
    )
}