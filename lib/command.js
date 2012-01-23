(function() {
  var Getbot, clearLine, clearLines, colors, err, log, makeReadable, program, progressbar;

  colors = require('colors');

  program = require('commander');

  Getbot = require('../lib/getbot');

  progressbar = require('progress');

  exports.run = function() {
    var bar, getbot, options, _ref;
    program.version('0.0.2').usage('[options] <URL>').option('-d, --destination [path]', 'the destination for the downloaded file').option('-c, --connections [number]', 'max connections to try', parseInt, 5).option('-u, --user [string]', 'username used for basic auth').option('-p, --pass [string]', 'password used for basic auth').parse(process.argv);
    if (((_ref = program.args) != null ? _ref.length : void 0) === 1) {
      options = {
        address: program.args[0],
        connections: program.connections,
        destination: program.destination,
        user: program.user,
        pass: program.pass
      };
      try {
        getbot = new Getbot(options);
      } catch (error) {
        err(error);
      }
      bar = null;
      getbot.on('noresume', function(statusCode) {
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
        return log("Download finished...", null, '\n');
      }).on('error', function(error) {
        return err(error, null, '\n');
      });
    } else {
      return log(program.helpInformation(), false);
    }
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
    process.stdout.write(prefix + 'getbot '.green + colors.inverse(("" + err).red) + (" " + (error.toString().replace("Error: ", "")) + "\n"));
    return process.exit(1);
  };

  clearLine = function() {
    return process.stdout.write('\r\033[2K');
  };

  clearLines = function() {
    return process.stdout.write('\r\033[2K\r\033[1A\r\033[2K');
  };

}).call(this);
