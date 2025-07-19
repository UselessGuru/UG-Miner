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
Version:        6.5.1
Version date:   2025/07/19
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" -or $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/KawpowMiner/KawpowMiner_v1.2.4.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\kawpowminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithm = "KawPow"; Type = "AMD"; MinMemGiB = 0.93; MinerSet = 2; WarmupTimes = @(75, 10); ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " --opencl --opencl-devices" }

    @{ Algorithm = "KawPow"; Type = "NVIDIA"; MinMemGiB = 0.93; MinerSet = 2; WarmupTimes = @(75, 10); ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " --cuda --cuda-devices" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIport + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    # $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    # If ($SupportedMinerDevices = $MinerDevices.Where({ $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 
                    If ($SupportedMinerDevices = $MinerDevices) { 

                        # $ExcludePools = $_.ExcludePools
                        # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm]) { 
                            $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                            If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                                $Protocol = Switch ($Pool.Protocol) { 
                                    "ethproxy"    { "stratum1"; Break }
                                    "ethstratum1" { "stratum2"; Break }
                                    "ethstratum2" { "stratum2"; Break }
                                    Default       { "stratum" }
                                }
                                $Protocol += If ($Pool.PoolPorts[1]) { "+ssl" } Else { "+tcp" }

                                [PSCustomObject]@{ 
                                    API         = "EthMiner"
                                    Arguments   = " --pool $($Protocol)://$([System.Web.HttpUtility]::UrlEncode($Pool.User)):$([System.Web.HttpUtility]::UrlEncode($Pool.Pass))@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --farm-recheck 10000 --farm-retries 40 --work-timeout 100000 --response-timeout 720 --api-bind 127.0.0.1:-$($MinerAPIPort)$($_.Arguments) $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                    DeviceNames = $AvailableMinerDevices.Name
                                    EnvVars     = @("SSL_NOVERIFY=TRUE")
                                    Fee         = @(0) # Dev fee
                                    MinerSet    = $_.MinerSet
                                    Name        = $MinerName
                                    Path        = $Path
                                    Port        = $MinerAPIPort
                                    Type        = $Type
                                    URI         = $Uri
                                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
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