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
      getbot = new Getbot(options);
      bar = null;
      getbot.on('noresume', function() {
        return log("Resume not supported, using only one connection...");
      }).on('downloadStart', function(statusCode) {
        this.readableSize = makeReadable(getbot.fileSize);
        log("" + getbot.filename + " (" + (makeReadable(getbot.fileSize)) + ")", statusCode);
        return bar = new progressbar('getbot '.green + '    Downloading: [:bar] :percent :size @ :rate', {
          complete: "--".green,
          incomplete: '  ',
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
        return log("Download finished...");
      }).on('error', function(error) {
        return err(error);
      });
    } else {
      return log(program.helpInformation());
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

  log = function(message, status) {
    var state;
    state = status ? colors.inverse(("" + status).green) : "   ";
    return process.stdout.write('\ngetbot '.green + state + (" " + message + "\n"));
  };

  err = function(error, status) {
    err = status ? status : "ERR";
    return process.stdout.write('\ngetbot '.green + colors.inverse(("" + err).red) + (" " + error + "\n"));
  };

  clearLine = function() {
    return process.stdout.write('\r\033[2K');
  };

  clearLines = function() {
    return process.stdout.write('\r\033[2K\r\033[1A\r\033[2K');
  };

}).call(this);
