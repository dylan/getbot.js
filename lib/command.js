(function() {
  var Getbot, clearLine, clearLines, colors, err, fs, loadList, log, makeReadable, program, progressbar, startBot, util;

  colors = require('colors');

  program = require('commander');

  Getbot = require('../lib/getbot');

  progressbar = require('progress');

  fs = require('fs');

  util = require('util');

  exports.run = function() {
    var list, options, _ref;
    program.version('0.0.6').usage('[options] <URL>').option('-d, --destination [path]', 'the destination for the downloaded file').option('-c, --connections [number]', 'max connections to try', parseInt, 5).option('-u, --user [string]', 'username used for basic http auth').option('-p, --pass [string]', 'password used for basic http auth').option('-l, --list [string]', 'a list of urls (one on each line) to read in and download from').parse(process.argv);
    if (((_ref = program.args) != null ? _ref.length : void 0) === 1) {
      list = [program.args[0]];
    } else {
      if (program.list) {
        list = loadList(program.list);
        list.reverse();
      } else {
        return log(program.helpInformation(), false);
      }
    }
    options = {
      connections: program.connections,
      destination: program.destination,
      user: program.user,
      pass: program.pass
    };
    if (list.length > 1) options.list = true;
    try {
      startBot(options, list);
    } catch (error) {
      err(error);
    }
  };

  startBot = function(options, list) {
    var bar, getbot,
      _this = this;
    options.address = list.pop();
    getbot = new Getbot(options);
    bar = null;
    return getbot.on('noresume', function(statusCode) {
      return log("Resume not supported, using only one connection...", statusCode, '\n');
    }).on('downloadStart', function(statusCode) {
      log("" + getbot.filename + " (" + (makeReadable(getbot.fileSize)) + ")", statusCode, '\n');
      this.readableSize = makeReadable(getbot.fileSize);
      bar = new progressbar('getbot '.green + '    ‹:bar› :percent :size @ :rate', {
        complete: "—".green,
        incomplete: '—'.red,
        width: 20,
        total: parseInt(getbot.fileSize, 10)
      });
    }).on('data', function(data, rate) {
      rate = "" + (makeReadable(rate)) + "/s";
      return bar.tick(data.length, {
        'rate': rate,
        'size': this.readableSize
      });
    }).on('allPartsComplete', function() {
      log("Download finished.\n", null, '\n');
      if (list.length > 0) return startBot(options, list);
    }).on('error', function(error) {
      return err(error, null, '\n');
    });
  };

  loadList = function(filename) {
    var downloadList;
    downloadList = [];
    fs.readFileSync(filename).toString().split('\n').forEach(function(line) {
      if (line !== '') return downloadList.push(line);
    });
    return downloadList;
  };

  makeReadable = function(bytes) {
    var precision, unit, units;
    units = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    unit = 0;
    while (bytes >= 1024) {
      unit++;
      bytes = bytes / 1024;
      precision = unit > 2 ? 2 : 1;
    }
    return "" + (bytes.toFixed(precision)) + " " + units[unit];
  };

  log = function(message, status, prefix) {
    var state;
    prefix = prefix ? prefix : "";
    state = status ? colors.inverse(("" + status).green) : "   ";
    return process.stdout.write(prefix + 'getbot '.green + state + (" " + message + "\n"));
  };

  err = function(error, status, prefix) {
    prefix = prefix ? prefix : "";
    err = status ? status : "ERR";
    process.stdout.write(prefix + 'getbot '.green + colors.inverse(("" + err).red) + (" " + (error.toString().replace("Error: ", "")) + "\n\n"));
    return process.exit(1);
  };

  clearLine = function() {
    return process.stdout.write('\r\033[2K');
  };

  clearLines = function() {
    return process.stdout.write('\r\033[2K\r\033[1A\r\033[2K');
  };

}).call(this);
