const enumdevicestatus = ['Enabled', 'Disabled', 'Unsupported'];
const enumminerstatus = ['Disabled', 'DryRun', 'Failed', 'Idle', 'Running', 'Unavailable'];

function formatMiners(data) {
  // This function can alter the returned data before building the table, formatting it in a way
  // that is easier to display and manipulate in a table
  $.each(data, function(index, item) {
    try {
      // Format miner link
      if (item.MinerUri && item.Best && item.Status == 4) { 
        item.BaseName = '<a href="' + item.MinerUri + '" target="_blank">' + item.BaseName + '</a>';
        item.Name = '<a href="' + item.MinerUri + '" target="_blank">' + item.Name + '</a>';
        item.StatusInfo = '<a href="' + item.MinerUri + '" target="_blank">' + item.StatusInfo + '</a>';
      }

      // Format the device(s)
      item.Devices = formatArrayAsSortedString(item.DeviceNames);

      // Format the pool and algorithm data
      item.PrimaryMinerFee = item.Workers[0].Fee;
      item.PrimaryHashrate = item.Workers[0].Hashrate;
      item.PrimaryAlgorithm = item.Workers[0].Pool.Algorithm;
      item.PrimaryAlgorithmVariant = item.Workers[0].Pool.AlgorithmVariant;
      item.PrimaryCurrency = item.Workers[0].Pool.Currency;
      item.PrimaryCoinName = item.Workers[0].Pool.CoinName;
      item.PrimaryPool = item.Workers[0].Pool.Name;
      item.PrimaryPoolVariant = item.Workers[0].Pool.Variant;
      item.PrimaryPoolFee = item.Workers[0].Pool.Fee;
      item.PrimaryPoolUser = item.Workers[0].Pool.User;
      if (item.Workers.length > 1) {
        item.SecondaryMinerFee = item.Workers[1].Fee;
        item.SecondaryHashrate = item.Workers[1].Hashrate;
        item.SecondaryAlgorithm = item.Workers[1].Pool.Algorithm;
        item.SecondaryAlgorithmVariant = item.Workers[1].Pool.AlgorithmVariant;
        item.SecondaryCurrency = item.Workers[1].Pool.Currency;
        item.SecondaryCoinName = item.Workers[1].Pool.CoinName;
        item.SecondaryPool = item.Workers[1].Pool.Name;
        item.SecondaryPoolVariant = item.Workers[1].Pool.Variant;
        item.SecondaryPoolFee = item.Workers[1].Pool.Fee;
        item.SecondaryPoolUser = item.Workers[1].Pool.User;
      }

      // Format margin of error
      if (isNaN(item.Earning_Accuracy)) item.EarningAccuracy = 'n/a'; 
      else item.EarningAccuracy = formatPercent(item.Earning_Accuracy);

      // Format the live speed(s)
      item.PrimaryHashrateLive = item.Hashrates_Live[0];
      item.SecondaryHashrateLive = item.Hashrates_Live[1];
 
      // Format Total Mining Duration (TimeSpan)
      if (item.TotalMiningDuration.Ticks > 0) item.TotalMiningDuration = formatTimeSpan(item.TotalMiningDuration);
      else item.TotalMiningDuration = "n/a";

      // Format Mining Duration (DateTime)
      if (item.BeginTime == "0001-01-01T00:00:00") item.MiningDuration = "n/a";
      else item.MiningDuration = formatTimeSince(item.BeginTime).replace('&nbsp;ago' ,'').replace('just now', 'just started');

      // Format status
      item.Status = enumminerstatus[item.Status];

      // Format warmup times
      item.WarmupTimes0 = item.WarmupTimes[0];
      item.WarmupTimes1 = item.WarmupTimes[1];
    }
    catch (error) { 
      console.error(item);
    }
  });
  return data;
}

function formatPools(data) {
  // This function can alter the returned data before building the table, formatting it in a way
  // that is easier to display and manipulate in a table
  $.each(data, function(index, item) {
    if (config.UsemBTC) factor = 1000;
    else factor = 1;
    item.Price = item.Price * factor;
    item.Price_Bias = item.Price_Bias * factor;
    item.StablePrice = item.StablePrice * factor;
  });
  return data;
}

function formatTimeSpan(timespan) {
  var duration = '';
  if (timespan) {
    if (timespan.Days == 1) duration = timespan.Days + ' day ';
    else duration = timespan.Days + ' days ';
    if (timespan.Hours == 1) duration = duration + timespan.Hours + ' hr ';
    else duration = duration + timespan.Hours + ' hrs ';
    if (timespan.Minutes == 1) duration = duration + timespan.Minutes + ' min ';
    else duration = duration + timespan.Minutes + ' mins ';
    if (timespan.Seconds == 1) duration = duration + timespan.Seconds + ' sec ';
    else duration = duration + timespan.Seconds + ' secs ';
    return duration.trim();
  }
  else return '-';
}

function formatTimeSince(value) {
  var value = (new Date).getTime() - (new Date(value)).getTime();
  if (value == 0) return '-';
  if (value < 1000) return 'just now';
  return formatTime(value / 1000) + '&nbsp;ago';
}

function formatTime(seconds) {
  var formattedtime = '';

  interval = Math.floor(seconds / (24 * 3600));
  if (interval > 1) formattedtime = formattedtime + interval.toString() + ' days ';
  else if (interval == 1) formattedtime = formattedtime + interval.toString() + ' day ';

  if (interval > 0) seconds = seconds - interval * (24 * 3600);
  interval = Math.floor(seconds / 3600);
  if (interval > 1) formattedtime = formattedtime + interval.toString() + ' hours ';
  else if (interval == 1) formattedtime = formattedtime + interval.toString() + ' hour ';

  if (interval > 0) seconds = seconds - interval * 3600;
  interval = Math.floor(seconds / 60);
  if (interval > 1) formattedtime = formattedtime + interval.toString() + ' minutes ';
  else if (interval == 1) formattedtime = formattedtime + interval.toString() + ' minute ';

  if (interval > 0) seconds = seconds - interval * 60;
  interval = parseInt(seconds % 60);
  if (interval > 1) formattedtime = formattedtime + interval.toString() + ' seconds ';
  else if (interval == 1) formattedtime = formattedtime + interval.toString() + ' second ';

  return formattedtime.trim()
}

function formatDuration(value) {
  return formatTime(parseInt(value.split(':')[0] * 3600) + parseInt(value.split(':')[1] * 60) + parseInt(value.split(':')[2]))
}

function formatHashrateValue(value) {
  if (value == undefined) return '';
  if (value === 0) return '0 H/s';
  if (value > 0) {
    var sizes = ['H/s', 'kH/s', 'MH/s', 'GH/s', 'TH/s', 'PH/s', 'EH/s', 'ZH/s', 'YH/s'];
    var i = Math.floor(Math.log(value) / Math.log(1000));
    unitvalue = value / Math.pow(1000, i);
    if (i <= 0) i = 1;
    if (unitvalue < 10) return unitvalue.toLocaleString(navigator.language, { maximumFractionDigits: 3, minimumFractionDigits: 3 }) + '&nbsp;' + sizes[i];
    return unitvalue.toLocaleString(navigator.language, { maximumFractionDigits: 2, minimumFractionDigits: 2 }) + '&nbsp;' + sizes[i];
  }
  return 'n/a';
};

function formatHashrate(value) {
  const values = value.split('<br/>')
  return values.map(formatHashrate).toString();
};

function getDecimalsFromValue(value) {
  var decimals;
  decimals = 1 + config.DecimalsMax - parseInt(value).toString().length
  if (decimals > config.DecimalsMax) decimals = 0;
  return decimals;
};

function formatDecimals(value) {
  if (value == null) return 'n/a';
  if (isNaN(value)) return 'n/a';
  return value.toLocaleString(navigator.language, { maximumFractionDigits: getDecimalsFromValue(value) , minimumFractionDigits: getDecimalsFromValue(value) });
};

function formatDecimalsFromBTC(value) {
  return formatDecimals(value * btc);
};

function formatPrices(value) {
  return (value * Math.pow(1024, 3)).toLocaleString(navigator.language, { minimumFractionDigits: (getDecimalsFromValue(value * Math.pow(1024, 3)) + 4) });
};

function formatDate(value) {
  if (value === '') return 'Unknown';
  if (value == null) return 'Unknown';
  if (Date.parse(value)) return (new Date(value).toLocaleString(navigator.language));
  return value;
};

function formatWatt(value) {
  if (parseFloat(value)) return parseFloat(value).toFixed(2) + '&nbsp;W';
  return 'n/a';
};

function formatPercent(value) {
  if (value == 0) return "0.00&nbsp;%";
  if (parseFloat(value)) return parseFloat(value * 100).toFixed(2) + '&nbsp;%';
  return '';
};

function formatPorts(value) {
  // return value;
  if (!Array.isArray(value)) {
    value = [value];
  }
  if (value[0] < 1) value[0] = "-";
  if (value[1] < 1) value[1] = "-";
  return value.join(' / ');
};

function formatArrayAsSortedString(value) {
  if (value === '' || value == null) return '';
  return value.sort().join(', ');
};

function format0DecimalDigits(value) {
  if (value > 0) return (value).toLocaleString(navigator.language, { minimumFractionDigits: 0, maximumFractionDigits: 0});
  return '';
};

function forma2tDecimalDigits(value) {
  if (value > 0) return (value).toLocaleString(navigator.language, { minimumFractionDigits: 1, maximumFractionDigits: 1});
  return '';
};

function format2DecimalDigits(value) {
  if (value > 0) return (value).toLocaleString(navigator.language, { minimumFractionDigits: 2, maximumFractionDigits: 2});
  return '';
};

function format3DecimalDigits(value) {
  if (value > 0) return (value).toLocaleString(navigator.language, { minimumFractionDigits: 3, maximumFractionDigits: 3});
  return '';
};

function format4DecimalDigits(value) {
  if (value > 0) return (value).toLocaleString(navigator.language, { minimumFractionDigits: 4, maximumFractionDigits: 4});
  return '';
};

function format5DecimalDigits(value) {
  if (value > 0) return (value).toLocaleString(navigator.language, { minimumFractionDigits: 5, maximumFractionDigits: 5});
  return '';
};

function format6DecimalDigits(value) {
  if (value > 0) return (value).toLocaleString(navigator.language, { minimumFractionDigits: 6, maximumFractionDigits: 6});
  return '';
};

function format7DecimalDigits(value) {
  if (value > 0) return (value).toLocaleString(navigator.language, { minimumFractionDigits: 7, maximumFractionDigits: 7});
  return '';
};

function format8DecimalDigits(value) {
  if (value > 0) return (value).toLocaleString(navigator.language, { minimumFractionDigits: 8, maximumFractionDigits: 8});
  return '';
};

function format9DecimalsDigits(value) {
  if (value > 0) return (value).toLocaleString(navigator.language, { minimumFractionDigits: 9, maximumFractionDigits: 9});
  return '';
};

function format10DecimalDigits(value) {
  if (value > 0) return (value).toLocaleString(navigator.language, { minimumFractionDigits: 10, maximumFractionDigits: 10});
  return '';
};

function formatGiBDigits0(value) {
  if (value > 0) return format0DecimalDigits(value) + '&nbsp;GiB';
  return '';
};

function formatGiBDigits1(value) {
  if (value > 0) return format1DecimalDigits(value) + '&nbsp;GiB';
  return '';
};

function formatGiBDigits2(value) {
  if (value > 0) return format2DecimalDigits(value) + '&nbsp;GiB';
  return '';
};

function formatGiBDigits3(value) {
  if (value > 0) return format3DecimalDigits(value) + '&nbsp;GiB';
  return '';
};

function formatGiBDigits4(value) {
  if (value > 0) return format4DecimalDigits(value) + '&nbsp;GiB';
  return '';
};

function formatGiBDigits5(value) {
  if (value > 0) return format5DecimalDigits(value) + '&nbsp;GiB';
  return '';
};

function formatGiBDigits6(value) {
  if (value > 0) return format6DecimalDigits(value) + '&nbsp;GiB';
  return '';
};

function formatGiBDigits7(value) {
  if (value > 0) return format7DecimalDigits(value) + '&nbsp;GiB';
  return '';
};

function formatGiBDigits8(value) {
  if (value > 0) return format8DecimalDigits(value) + '&nbsp;GiB';
  return '';
};

function formatGiBDigits9(value) {
  if (value > 0) return format9DecimalDigits(value) + '&nbsp;GiB';
  return '';
};

function formatGiBDigits10(value) {
  if (value > 0) return format10DecimalDigits(value) + '&nbsp;GiB';
  return '';
};

function detailFormatter(index, row) {
  var html = [];
  $.each(row, function (key, value) {
    if (typeof value === 'string') {
      if (key === 'PoolUri') { 
        var target = JSON.stringify(value).replaceAll('\\\\', '\\').replaceAll('"', '');
        html.push(`<p class="mb-0"><b>${key}:</b> <a href=${target} target="_blank">${target}</a></p>`);
      } else { 
        html.push(`<p class="mb-0"><b>${key}:</b> ${JSON.stringify(value).replaceAll('\\\\', '\\')}</p>`);
      }
    }
    else html.push(`<p class="mb-0"><b>${key}:</b> ${JSON.stringify(value)}</p>`);
  });
  return html.join('');
}

function formatBytes(bytes) {
  if (bytes > 0) {
    decimals = 2;
    var k = 1024;
    dm = decimals || 2;
    sizes = [' Bytes', ' kiB', ' MiB', ' GiB', ' TiB', ' PiB', ' EiB', ' ZiB', ' YiB'];
    i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + sizes[i];
  }
  return '-';
}

function createUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

function headerStyleAlignTop() {
  return { classes: 'align-top' }
};