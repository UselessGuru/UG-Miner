using module c:\Users\Stephan\Desktop\UG-Miner\Includes\Include.psm1

Set-Location c:\Users\Stephan\Desktop\UG-Miner\



function Get-CoinList { 
    $Data = (Invoke-RestMethod -Uri "https://min-api.cryptocompare.com/data/all/coinlist" -TimeoutSec 5 -ErrorAction Ignore).Data
    $CoinList = [Ordered]@{ }
    ($Data.PSObject.Properties.Name | Sort-Object).ForEach(
        { $CoinList.$_ = $Data.$_.CoinName }
    )
}


$DB = c:\Users\Stephan\Desktop\UG-Miner\Includes\Dev\CoinsDB.json | ConvertFrom-Json

$AlgorithmCurrencies = [Ordered]@{ } # as case insensitive hash table
$CoinList = [Ordered]@{ } # as case insensitive hash table
$CoinDB = [PSCustomObject]@{ }
$CoinDB2 = @{ }
(($DB | Get-Member -MemberType NoteProperty).Name | Sort-Object -Unique).ForEach(
    { 
        $Algorithm = Get-Algorithm $DB.$_.Algo
        $Currency = $_ -replace "-.+$"
        $CoinName = $DB.$_.Name -replace "cash$", "Cash" -replace "gold$", "Gold" -replace "coin$", "Coin" -replace "token$", "Token"
        $CoinList.$Currency = $CoinName
        $Data = [PSCustomObject]@{ 
            "Algorithm" = $Algorithm
            "CoinName"  = $CoinName
            "Currency"  = $Currency
        }
        $CoinDB | Add-Member $_ $Data
    }
)

foreach ($Algorithm in (($CoinDB | Get-Member -MemberType NoteProperty).Name).ForEach({ $CoinDB.$_.Algorithms }) | Sort-Object -Unique) { 

    $Currencies = ($CoinDB | Get-Member -MemberType NoteProperty).Name.Where({ $CoinDB.$_.Algorithms -match $Algorithm })
    if ($Currencies.Count -eq 1) { 
        $AlgorithmCurrencies.$Algorithm = $Currencies
    }
}

$CoinList | ConvertTo-Json > c:\Users\Stephan\Desktop\UG-Miner\Includes\CoinNames.json
$AlgorithmCurrencies | ConvertTo-Json > c:\Users\Stephan\Desktop\UG-Miner\Includes\AlgorithmCurrency.json
