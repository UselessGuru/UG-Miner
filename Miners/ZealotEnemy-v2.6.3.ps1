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
Version:        6.5.2
Version date:   2025/07/27
#>

If (-not ($Devices = $Session.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = Switch ($Session.DriverVersion.CUDA) { 
    { $_ -ge [System.Version]"11.1" } { "https://github.com/UselessGuru/UG-Miner-Binaries/releases/download/Z-Enemy/z-enemy-2.6.3-win-cuda11.1.zip"; Break }
    Default                           { Return }
}
$Name = [String](Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "Bin\$Name\z-enemy.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    @{ Algorithm = "Aergo";      MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @(); Arguments = " --algo aergo --statsavg 5 --intensity 23" }
#   @{ Algorithm = "BCD";        MinMemGiB = 3;    MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo bcd --statsavg 5" } # ASIC
#   @{ Algorithm = "Bitcore";    MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(90, 0);  ExcludePools = @(); Arguments = " --algo bitcore --statsavg 5 --intensity 22" } # Bitcore is using MegaBtx
    @{ Algorithm = "C11";        MinMemGiB = 3;    MinerSet = 2; WarmupTimes = @(60, 0);  ExcludePools = @(); Arguments = " --algo c11 --statsavg 5 --intensity 24" }
    @{ Algorithm = "Hex";        MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(30, 0);  ExcludePools = @(); Arguments = " --algo hex --statsavg 5 --intensity 24" }
    @{ Algorithm = "KawPow";     MinMemGiB = 0.77; MinerSet = 2; WarmupTimes = @(180, 0); ExcludePools = @(); Arguments = " --algo kawpow --statsavg 1 --intensity 24" }
#   @{ Algorithm = "Phi";        MinMemGiB = 3;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo phi --statsavg 5" } # ASIC
    @{ Algorithm = "Phi2";       MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(60, 0);  ExcludePools = @(); Arguments = " --algo phi2 --statsavg 5" }
    @{ Algorithm = "Polytimos";  MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo poly --statsavg 5" }
    @{ Algorithm = "SkunkHash";  MinMemGiB = 3;    MinerSet = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo skunk --statsavg 1" } # No hashrate in time for old cards
#   @{ Algorithm = "Sonoa";      MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --algo sonoa --statsavg 1" } # No hashrate in time
    @{ Algorithm = "Timetravel"; MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo timetravel --statsavg 5" }
#   @{ Algorithm = "Tribus";     MinMemGiB = 3;    MinerSet = 0; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --algo tribus --statsavg 1" } # ASIC
#   @{ Algorithm = "X16r";       MinMemGiB = 3;    MinerSet = 3; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = " --algo x16r --statsavg 1" } # ASIC
    @{ Algorithm = "X16rv2";     MinMemGiB = 3;    MinerSet = 0; WarmupTimes = @(60, 0);  ExcludePools = @(); Arguments = " --algo x16rv2 --statsavg 5" }
    @{ Algorithm = "X16s";       MinMemGiB = 3;    MinerSet = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo x16s --statsavg 5" } # FPGA
    @{ Algorithm = "X17";        MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(120, 0); ExcludePools = @(); Arguments = " --algo x17 --statsavg 1" }
#   @{ Algorithm = "Xevan";      MinMemGiB = 2;    MinerSet = 2; WarmupTimes = @(90, 0);  ExcludePools = @(); Arguments = " --algo xevan --diff-factor 1 --statsavg 1 --intensity 26" } # No hashrate in time
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })

If ($Algorithms) { 

    ($Devices | Sort-Object -Property Model -Unique).ForEach(
        { 
            $Model = $_.Model
            $MinerDevices = $Devices.Where({ $_.Model -eq $Model })
            $MinerAPIPort = $Config.APIport + ($MinerDevices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    # $ExcludePools = $_.ExcludePools
                    # ForEach ($Pool in $MinerPools[0][$_.Algorithm].Where({ $ExcludePools -notcontains $_.Name })) { 
                    ForEach ($Pool in $MinerPools[0][$_.Algorithm]) { 

                        $MinMemGiB = $_.MinMemGiB + $Pool.DAGsizeGiB
                        If ($_.Algorithm -eq "KawPow" -and $MinMemGB -lt 2) { $MinMemGiB = 4 } # No hash rates in time for GPUs with 2GB
                        If ($AvailableMinerDevices = $MinerDevices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                            $MinerName = "$Name-$($AvailableMinerDevices.Count)x$Model-$($Pool.AlgorithmVariant)"

                            $Arguments = $_.Arguments
                            If ($AvailableMinerDevices.Where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace " --intensity [0-9]+" }

                            [PSCustomObject]@{ 
                                API         = "Trex"
                                Arguments   = "$Arguments $(If ($Pool.PoolPorts[1]) { "$(If ($Config.SSLallowSelfSignedCertificate) { "--no-cert-verify " })--url stratum+ssl" } Else { "--url stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --pass $($Pool.Pass) --api-bind 0 --api-bind-http $MinerAPIPort --retry-pause 1 --quiet --devices $(($AvailableMinerDevices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMinerDevices.Name
                                Fee         = @(0.01) # Dev fee
                                MinerSet    = $_.MinerSet
                                MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                Name        = $MinerName
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = "NVIDIA"
                                URI         = $URI
                                WarmupTimes = @($_.WarmupTimes) # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; second value: seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers      = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}