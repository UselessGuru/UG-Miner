<#
Copyright (c) 2018-2026 UselessGuru

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
Version:        6.9.0
Version date:   2026/10/24
#>

# minor pearlhash improvements to NVIDIA Ampere, Ada and BlackwellA100/CMP170HX gpu's
# improved pearlhash for NVIDIA A100/CMP170HX
# improved pearlhash for AMD RDNA2 and RDNA3

if (-not ($Devices = $Session.EnabledDevices.Where{ ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -match "OpenCL C [1.2|2\.\d+]" -and $_.Architecture -notmatch "^GCN?$") -or $_.Type -eq "INTEL" -or ($_.OpenCL.ComputeCapability -ge "7.0" -and $_.OpenCL.DriverVersion -ge [System.Version]"452.39.00" -and $_.Model -notmatch "^MX\d.+") })) { return }

$URL = "https://github.com/andru-kun/wildrig-ng/releases/download/1.0.0o/wildrig-ng-windows-1.0.0o.zip"
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\wildrig-ng.exe"
$DeviceEnumerator = "Type_Slot"


$Algorithms = @(
    @{ Algorithm = "Autolykos2";  Type = "AMD"; Fee = @(0);    MinMemGiBfree = 1.24; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo autolykos2" }
    @{ Algorithm = "KawPow";      Type = "AMD"; Fee = @(0.01); MinMemGiBfree = 1.24; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo kawpow" }
    @{ Algorithm = "NexaPow";     Type = "AMD"; Fee = @(0.01); MinMemGiBfree = 3;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo nexapow" }
    @{ Algorithm = "Parano1d";    Type = "AMD"; Fee = @(0.02); MinMemGiBfree = 1;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = "RDNA1"; ExcludePools = @(); Arguments = " --algo noid" }
#   @{ Algorithm = "PearlHash";   Type = "AMD"; Fee = @(0);    MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo pearlhash" } # https://github.com/andru-kun/wildrig-ng/issues/6, only supports pool pearlhash.xyz
    @{ Algorithm = "ProgPowZ";    Type = "AMD"; Fee = @(0.01); MinMemGiBfree = 1.24; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo progpowz" }
    @{ Algorithm = "QHash";       Type = "AMD"; Fee = @(0.02); MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo qhash" }
    @{ Algorithm = "Quantus";     Type = "AMD"; Fee = @(0.01); MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo quantus" }
#   @{ Algorithm = "Sha256d";     Type = "AMD"; Fee = @(0);    MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo sha256d" } # ASIC
    @{ Algorithm = "XelisHashV3"; Type = "AMD"; Fee = @(0.01); MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo xelishashv3" }

    @{ Algorithm = "Autolykos2";  Type = "INTEL"; Fee = @(0);    MinMemGiBfree = 1.24; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " --algo autolykos2" }
    @{ Algorithm = "KawPow";      Type = "INTEL"; Fee = @(0.01); MinMemGiBfree = 1.24; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " --algo kawpow" }
    @{ Algorithm = "NexaPow";     Type = "INTEL"; Fee = @(0.01); MinMemGiBfree = 3;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " --algo nexapow" }
#   @{ Algorithm = "PearlHash";   Type = "INTEL"; Fee = @(0);    MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " --algo pearlhash" } # https://github.com/andru-kun/wildrig-ng/issues/6, only supports pool pearlhash.xyz
    @{ Algorithm = "ProgPowZ";    Type = "INTEL"; Fee = @(0.01); MinMemGiBfree = 1.24; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " --algo progpowz" }
    @{ Algorithm = "QHash";       Type = "INTEL"; Fee = @(0.01); MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " --algo qhash" }
    @{ Algorithm = "Quantus";     Type = "INTEL"; Fee = @(0.01); MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " --algo quantus" }
#   @{ Algorithm = "Sha256d";     Type = "INTEL"; Fee = @(0);    MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " --algo sha256d" } # ASIC
    @{ Algorithm = "XelisHashV3"; Type = "INTEL"; Fee = @(0.01); MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " "; ExcludePools = @(); Arguments = " --algo xelishashv3" }

    @{ Algorithm = "Autolykos2";  Type = "NVIDIA"; Fee = @(0);    MinMemGiBfree = 1.24; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo autolykos2" }
    @{ Algorithm = "KawPow";      Type = "NVIDIA"; Fee = @(0.01); MinMemGiBfree = 1.24; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo kawpow" }
    @{ Algorithm = "NexaPow";     Type = "NVIDIA"; Fee = @(0.01); MinMemGiBfree = 3;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo nexapow" }
    @{ Algorithm = "Parano1d";    Type = "NVIDIA"; Fee = @(0.02); MinMemGiBfree = 1;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = "VOLTA"; ExcludePools = @(); Arguments = " --algo noid" }
#   @{ Algorithm = "PearlHash";   Type = "NVIDIA"; Fee = @(0);    MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo pearlhash" } # https://github.com/andru-kun/wildrig-ng/issues/6, only supports pool pearlhash.xyz
    @{ Algorithm = "ProgPowZ";    Type = "NVIDIA"; Fee = @(0.01); MinMemGiBfree = 1.24; WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo progpowz" }
    @{ Algorithm = "QHash";       Type = "NVIDIA"; Fee = @(0.01); MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo qhash" }
    @{ Algorithm = "Quantus";     Type = "NVIDIA"; Fee = @(0.01); MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo quantus" }
#   @{ Algorithm = "Sha256d";     Type = "NVIDIA"; Fee = @(0);    MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo sha256d" } # ASIC
    @{ Algorithm = "XelisHashV3"; Type = "NVIDIA"; Fee = @(0.01); MinMemGiBfree = 2;    WarmupTimes = @(30, 15);  ExcludeGPUarchitectures = " ";     ExcludePools = @(); Arguments = " --algo xelishashv3" }
)

$Algorithms = $Algorithms.Where{ $MinerPools[0][$_.Algorithm] }

if ($Algorithms) { 

    ($Devices | Group-Object -Property Type, Model).ForEach{ 
        $MinerDevices = $_.Group
        $Model = $MinerDevices[0].Model
        $Type = $MinerDevices[0].Type

        $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Bottom 1)

        $Algorithms.Where{ $_.Type -eq $Type }.ForEach{ 
            $ExcludeGPUarchitectures = $_.ExcludeGPUarchitectures
            if ($SupportedMinerDevices = $MinerDevices.Where{ $_.Architecture -notmatch $ExcludeGPUarchitectures }) { 

                foreach ($Pool in $MinerPools[0][$_.Algorithm]) { 
                # $ExcludePools = $_.ExcludePools
                # foreach ($Pool in $MinerPools[0][$_.Algorithm].Where{ $ExcludePools -notcontains $_.Name }) { 

                    $MinMemGiBfree = $_.MinMemGiBfree + $Pool.DAGsizeGiB
                    if ($AvailableMinerDevices = $SupportedMinerDevices.Where{ $_.MemoryGiBfree -ge $MinMemGiBfree }) { 

                        $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                        # Allow more time to build larger DAGs, must use type cast to keep values in $_
                        $WarmupTimes = [UInt16[]]$_.WarmupTimes
                        $WarmupTimes[0] += [UInt16]($Pool.DAGsizeGiB * 2)

                        @{ 
                            API         = "XmRig"
                            Arguments   = "$($_.Arguments) --api-port $MinerAPIPort --url $(if ($Pool.PoolPorts[1]) { "stratum+tcps://$($Pool.Host):$($Pool.PoolPorts[1])" } else { "stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0])" }) --user $($Pool.User) --pass $($Pool.Pass) --no-watchdog --gpu-list $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach{ '{0:x}' -f $_ } -join ',')"
                            DeviceNames = $AvailableMinerDevices.Name
                            DownloadURL = $URL
                            Fee         = $_.Fee # Dev fee
                            MinerURL    = "http://127.0.0.1:$($MinerAPIPort)"
                            Name        = $MinerName
                            Path        = $Path
                            Port        = $MinerAPIPort
                            Type        = $Type
                            WarmupTimes = $WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                            Workers     = @(@{ Pool = $Pool })
                        }
                    }
                }
            }
        }
    }
}