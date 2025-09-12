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
Version:        6.5.12
Version date:   2025/09/12
#>

# Performance improvement on Qubitcoin for Pascal/30xx/40xx series (~40%)

If (-not ($Devices = $Session.EnabledDevices.Where({ $_.Type -eq "AMD" -or ($_.Type -eq "NVIDIA" -and $_.OpenCL.ComputeCapability -ge "6.0" -and $_.OpenCL.DriverVersion -ge [System.Version]"450.80.02") }))) { Return }

$URI = "https://github.com/OneZeroMiner/onezerominer/releases/download/v1.5.9/onezerominer-win64-1.5.9.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\onezerominer.exe"
$DeviceEnumerator = "Type_Slot"

$Algorithms = @( 
    @{ Algorithm = "QHash";       Type = "AMD"; Fee = @(0.03); MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(180, 10); ExcludePools = @(); Arguments = @(" --algo qhash") }
    @{ Algorithm = "XelisHashV2"; Type = "AMD"; Fee = @(0.02); MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(180, 10); ExcludePools = @(); Arguments = @(" --algo xelis") }

    @{ Algorithm = "DynexSolve";  Type = "NVIDIA"; Fee = @(0.02); MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(180, 120); ExcludePools = @(); Arguments = @(" --algo dynex") }
    @{ Algorithm = "QHash";       Type = "NVIDIA"; Fee = @(0.03); MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(180, 10);  ExcludePools = @(); Arguments = @(" --algo xelis") }
    @{ Algorithm = "XelisHashV2"; Type = "NVIDIA"; Fee = @(0.01); MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(180, 10);  ExcludePools = @(); Arguments = @(" --algo xelis") }
)

# $Algorithms = $Algorithms.Where({ $_.MinerSet -le $Session.ConfigRunning.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Session.ConfigRunning.APIport + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $MinMemGiB = $_.MinMemGiB

                    If ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($_.Algorithm)"

                        $ExcludePools = $_.ExcludePools
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 

                            [PSCustomObject]@{ 
                                API         = "OneZero"
                                Arguments   = "$($_.Arguments) --pool $(If ($Pool.PoolPorts[1]) { "ssl://" })$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --wallet $($Pool.User) --pass $($Pool.Pass)$(If ($Pool.PoolPorts[1] -and $Session.ConfigRunning.SSLallowSelfSignedCertificate) { " --no-cert-validation" }) --api-port $MinerAPIPort --hashrate-avg 5 --disable-telemetry --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = $_.Fee # Dev fee
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
            )
        }
    )
}