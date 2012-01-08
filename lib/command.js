(function() {
  var Getbot, cluster, colors, http, program, url, util;

  colors = require('colors');

  program = require('commander');

  cluster = require('cluster');

  http = require('http');

  url = require('url');

  util = require('util');

  Getbot = require('../lib/getbot');

  exports.run = function() {
    var getbot, _ref;
    program.version('0.0.2').usage('[options] <URL>').option('-d, --destination [path]', 'the destination for the downloaded file', '.').option('-c, --connections [number]', 'max connections to try', parseInt, 3).option('-u, --user [string]', 'username used for basic auth').option('-p, --pass [string]', 'password used for basic auth').parse(process.argv);
    if (((_ref = program.args) != null ? _ref.length : void 0) === 1) {
      return getbot = new Getbot(program.args[0], program.user, program.pass);
    } else {
      return console.log(program.helpInformation());
    }
  };

}).call(this);
