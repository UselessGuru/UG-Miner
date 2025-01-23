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
Version:        6.3.22
Version date:   2025/01/23
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2" -and $_.Architecture -notmatch "^GCN1$") -or $_.Type -eq "INTEL" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge [System.Version]"452.39.00") }))) { Return }

$URI = "https://github.com/andru-kun/wildrig-multi/releases/download/0.41.7/wildrig-multi-windows-0.41.7.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\wildrig.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    @{ Algorithm = "Aergo";            Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo aergo" }
    @{ Algorithm = "AstralHash";       Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo glt-astralhash" }
#   @{ Algorithm = "BCD";              Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 3; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo bcd" } # ASIC
    @{ Algorithm = "Blake2bBtcc";      Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo blake2b-btcc" }
    @{ Algorithm = "Blake2bGlt";       Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo blake2b-glt" }
    @{ Algorithm = "Blake3";           Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @("NiceHash"); Arguments = " --algo blake3" }
    @{ Algorithm = "Dedal";            Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo dedal" } # CryptoDredge-v0.27.0 is fastest
    @{ Algorithm = "GlobalHash";       Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo glt-globalhash" }
    @{ Algorithm = "JeongHash";        Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo glt-jeonghash" }
#   @{ Algorithm = "Lyra2RE3";         Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo lyra2v3" } # ASIC
    @{ Algorithm = "Lyra2TDC";         Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo lyra2tdc" }
    @{ Algorithm = "Lyra2vc0ban";      Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo lyra2vc0ban" }
    @{ Algorithm = "PadiHash";         Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo glt-padihash" }
    @{ Algorithm = "PawelHash";        Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo glt-pawelhash" }
#   @{ Algorithm = "Phi5";             Type = "AMD"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo phi5" } # Algorithm is dead
    @{ Algorithm = "RWAHash";          Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo rwahash" }
    @{ Algorithm = "Xevan";            Type = "AMD"; Fee = @(0.0075); MinMemGiB = 3;    MinerSet = 0; WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";       ExcludePools = @();           Arguments = " --algo xevan --gpu-threads 1" } # No hashrate on time for old GPUs

    @{ Algorithm = "Aergo";            Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo aergo --watchdog" }
    @{ Algorithm = "AstralHash";       Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo glt-astralhash --watchdog" }
    @{ Algorithm = "BCD";              Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 3; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo bcd --watchdog" } # ASIC
    @{ Algorithm = "Blake2bBtcc";      Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo blake2b-btcc --watchdog" }
    @{ Algorithm = "Blake2bGlt";       Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo blake2b-glt --watchdog" }
    @{ Algorithm = "Blake3";           Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @("NiceHash"); Arguments = " --algo blake3" }
    @{ Algorithm = "Dedal";            Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo dedal --watchdog" } # CryptoDredge-v0.27.0 is fastest
    @{ Algorithm = "GlobalHash";       Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo glt-globalhash --watchdog" }
    @{ Algorithm = "JeongHash";        Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo glt-jeonghash --watchdog" } # Trex-v0.26.8 is fastest
#   @{ Algorithm = "Lyra2RE3";         Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo lyra2v3 --watchdog" } # ASIC
    @{ Algorithm = "Lyra2TDC";         Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo lyra2tdc --watchdog" }
    @{ Algorithm = "Lyra2vc0ban";      Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo lyra2vc0ban --watchdog" }
    @{ Algorithm = "PadiHash";         Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo glt-padihash --watchdog" }
    @{ Algorithm = "PawelHash";        Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo glt-pawelhash --watchdog" } # Trex-v0.26.8 is fastest
#   @{ Algorithm = "Phi5";             Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo phi5 --watchdog" } # Algorithm is dead
    @{ Algorithm = "RWAHash";          Type = "INTEL"; Fee = @(0.02);   MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo rwahash --watchdog" }
    @{ Algorithm = "Xevan";            Type = "INTEL"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @();           Arguments = " --algo xevan --watchdog" }

    @{ Algorithm = "Aergo";            Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo aergo --watchdog" }
    @{ Algorithm = "AstralHash";       Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo glt-astralhash --watchdog" }
    @{ Algorithm = "BCD";              Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 3; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo bcd --watchdog" } # ASIC
    @{ Algorithm = "Blake2bBtcc";      Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo blake2b-btcc --watchdog" }
    @{ Algorithm = "Blake2bGlt";       Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo blake2b-glt --watchdog" }
    @{ Algorithm = "Blake3";           Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 3;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @("NiceHash"); Arguments = " --algo blake3 --watchdog" }
    @{ Algorithm = "Dedal";            Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo dedal --watchdog" } # CryptoDredge-v0.27.0 is fastest
    @{ Algorithm = "GlobalHash";       Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo glt-globalhash --watchdog" }
    @{ Algorithm = "JeongHash";        Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo glt-jeonghash --watchdog" } # Trex-v0.26.8 is fastest
#   @{ Algorithm = "Lyra2RE3";         Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo lyra2v3 --watchdog" } # ASIC
    @{ Algorithm = "Lyra2TDC";         Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo lyra2tdc --watchdog" }
    @{ Algorithm = "Lyra2vc0ban";      Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo lyra2vc0ban --watchdog" }
    @{ Algorithm = "PadiHash";         Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo glt-padihash --watchdog" }
    @{ Algorithm = "PawelHash";        Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);   ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo glt-pawelhash --watchdog" } # Trex-v0.26.8 is fastest
#   @{ Algorithm = "Phi5";             Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo phi5 --watchdog" } # Algorithm is dead
    @{ Algorithm = "RWAHash";          Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo rwahash --watchdog" }
    @{ Algorithm = "Xevan";            Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(60, 15);  ExcludeGPUarchitectures = " ";                ExcludePools = @();           Arguments = " --algo xevan --watchdog" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Type, Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $Type = $_.Type
            $MinerDevices = $Devices.Where({ $_.Type -eq $Type -and $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIPort + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.Where({ $_.Type -eq $Type }).ForEach(
                { 
                    $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
                    If ($SupportedMinerDevices = $MinerDevices.Where({ $_.Architecture -notmatch $ExcludeGPUarchitectures })) { 

                        $ExcludePools = $_.ExcludePools
                        ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 

                            $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                            If ($AvailableMinerDevices = $SupportedMinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                                $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                                [PSCustomObject]@{ 
                                    API         = "XmRig"
                                    Arguments   = "$($_.Arguments) --api-port $MinerAPIPort --url $(If ($Pool.PoolPorts[1]) { "stratum+tcps" } Else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --pass $($Pool.Pass) --multiple-instance --opencl-platform $($AvailableMinerDevices.PlatformId) --opencl-devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                    DeviceNames = $AvailableMinerDevices.Name
                                    Fee         = $_.Fee # Dev fee
                                    MinerSet    = $_.MinerSet
                                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                    Name        = $MinerName
                                    Path        = $Path
                                    Port        = $MinerAPIPort
                                    Type        = $_.Type
                                    URI         = $URI
                                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
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