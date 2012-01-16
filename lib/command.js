(function() {
  var Getbot, cluster, colors, http, makeReadable, program, progressbar, url, util;

  colors = require('colors');

  program = require('commander');

  cluster = require('cluster');

  http = require('http');

  url = require('url');

  util = require('util');

  Getbot = require('../lib/getbot');

  progressbar = require('progress');

  exports.run = function() {
    var bar, getbot, _ref;
    program.version('0.0.2').usage('[options] <URL>').option('-d, --destination [path]', 'the destination for the downloaded file', '.').option('-c, --connections [number]', 'max connections to try', parseInt, 3).option('-u, --user [string]', 'username used for basic auth').option('-p, --pass [string]', 'password used for basic auth').parse(process.argv);
    if (((_ref = program.args) != null ? _ref.length : void 0) === 1) {
      getbot = new Getbot(program.args[0], program.user, program.pass);
      bar = null;
      getbot.on('downloadStart', function() {
        return bar = new progressbar('Downloading: [:bar] :percent :eta | :rate', {
          complete: '=',
          incomplete: ' ',
          width: 20,
          total: parseInt(getbot.size, 10)
        });
      });
      getbot.on('data', function(data, rate) {
        rate = "" + (makeReadable(rate)) + "/s";
        return bar.tick(data.length, {
          'rate': rate
        });
      });
    } else {
      return console.log(program.helpInformation());
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

}).call(this);
