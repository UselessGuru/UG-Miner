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
Version:        6.9.2
Version date:   2026/10/30
#>

if (-not ($Devices = $Session.EnabledDevices.Where{ $_.OpenCL.ComputeCapability -ge "5.0" })) { return }

$URL = switch ($Session.DriverVersion.CUDA) { 
    { $_ -ge [System.Version]"11.1" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/Z-Enemy/z-enemy-2.6.3-win-cuda11.1.zip"; break }
    default { return }
}
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\z-enemy.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithm = "Aergo";      MinMemGiBfree = 2;    WarmupTimes = @(30, 0);  ExcludePools = @(); Arguments = " --algo aergo --statsavg 5 --intensity 23" }
#   @{ Algorithm = "BCD";        MinMemGiBfree = 3;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo bcd --statsavg 5" } # ASIC
#   @{ Algorithm = "Bitcore";    MinMemGiBfree = 2;    WarmupTimes = @(90, 0);  ExcludePools = @(); Arguments = " --algo bitcore --statsavg 5 --intensity 22" } # Bitcore is using MegaBtx
    @{ Algorithm = "C11";        MinMemGiBfree = 3;    WarmupTimes = @(60, 0);  ExcludePools = @(); Arguments = " --algo c11 --statsavg 5 --intensity 24" }
    @{ Algorithm = "Hex";        MinMemGiBfree = 2;    WarmupTimes = @(30, 0);  ExcludePools = @(); Arguments = " --algo hex --statsavg 5 --intensity 24" }
#   @{ Algorithm = "KawPow";     MinMemGiBfree = 0.77; WarmupTimes = @(180, 0); ExcludePools = @(); Arguments = " --algo kawpow --statsavg 1 --intensity 24" } # No hashrate in time
#   @{ Algorithm = "Phi";        MinMemGiBfree = 3;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo phi --statsavg 5" } # ASIC
    @{ Algorithm = "Phi2";       MinMemGiBfree = 2;    WarmupTimes = @(60, 0);  ExcludePools = @(); Arguments = " --algo phi2 --statsavg 5" }
    @{ Algorithm = "Polytimos";  MinMemGiBfree = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo poly --statsavg 5" }
    @{ Algorithm = "SkunkHash";  MinMemGiBfree = 3;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo skunk --statsavg 1" } # No hashrate in time for old cards
#   @{ Algorithm = "Sonoa";      MinMemGiBfree = 2;    WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --algo sonoa --statsavg 1" } # No hashrate in time
    @{ Algorithm = "Timetravel"; MinMemGiBfree = 2;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo timetravel --statsavg 5" }
#   @{ Algorithm = "Tribus";     MinMemGiBfree = 3;    WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --algo tribus --statsavg 1" } # ASIC
#   @{ Algorithm = "X16r";       MinMemGiBfree = 3;    WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo x16r --statsavg 1" } # ASIC
    @{ Algorithm = "X16rv2";     MinMemGiBfree = 3;    WarmupTimes = @(60, 0);  ExcludePools = @(); Arguments = " --algo x16rv2 --statsavg 5" }
    @{ Algorithm = "X16s";       MinMemGiBfree = 3;    WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo x16s --statsavg 5" } # FPGA
    @{ Algorithm = "X17";        MinMemGiBfree = 2;    WarmupTimes = @(120, 0); ExcludePools = @(); Arguments = " --algo x17 --statsavg 1" }
#   @{ Algorithm = "Xevan";      MinMemGiBfree = 2;    WarmupTimes = @(90, 0);  ExcludePools = @(); Arguments = " --algo xevan --diff-factor 1 --statsavg 1 --intensity 26" } # No hashrate in time
)

$Algorithms = $Algorithms.Where{ $MinerPools[0][$_.Algorithm] }

if ($Algorithms) { 

    ($Devices | Group-Object -Property Model).ForEach{ 
        $MinerDevices = $_.Group
        $Model = $MinerDevices[0].Model

        $MinerAPIPort = $Session.MinerBaseAPIport + ($MinerDevices.Id | Sort-Object -Bottom 1)

        $Algorithms.ForEach{ 
            # $ExcludePools = $_.ExcludePools
            # foreach ($Pool in $MinerPools[0][$_.Algorithm].Where{ $ExcludePools -notcontains $_.Name }) { 
            foreach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                $MinMemGiBfree = $_.MinMemGiBfree + $Pool.DAGsizeGiB
                if ($_.Algorithm -eq "KawPow" -and $MinMemGiBfree -lt 2) { $MinMemGiBfree = 4 } # No hash rates in time for GPUs with 2GB
                if ($AvailableMinerDevices = $MinerDevices.Where{ $_.MemoryGiBfree -ge $MinMemGiBfree }) { 

                    $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                    $Arguments = $_.Arguments
                    if ($AvailableMinerDevices.Where{ $_.MemoryGiBfree -le 2 }) { $Arguments = $Arguments -replace " -{1,2}intensity [0-9]+[.]*[0-9]+" }

                    # Allow more time to build larger DAGs, must use type cast to keep values in $_
                    $WarmupTimes = [UInt16[]]$_.WarmupTimes
                    $WarmupTimes[0] += [UInt16]($Pool.DAGsizeGiB * 2)

                    @{ 
                        API         = "Trex"
                        Arguments   = "$Arguments $(if ($Pool.PoolPorts[1]) { "$(if ($Session.Config.SSLallowSelfSignedCertificate) { "--no-cert-verify " })--url stratum+ssl://$($Pool.Host):$($Pool.PoolPorts[1])" } else { "--url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0])" }) --user $($Pool.User) --pass $($Pool.Pass) --api-bind 0 --api-bind-http $MinerAPIPort --retry-pause 1 --quiet --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach{ '{0:x}' -f $_ } -join ',')"
                        DeviceNames = $AvailableMinerDevices.Name
                        DownloadURL = $URL
                        Fee         = @(0.01) # Dev fee
                        MinerURL    = "http://127.0.0.1:$($MinerAPIPort)"
                        Name        = $MinerName
                        Path        = $Path
                        Port        = $MinerAPIPort
                        Type        = "NVIDIA"
                        WarmupTimes = $WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                        Workers     = @(@{ Pool = $Pool })
                    }
                }
            }
        }
    }
}