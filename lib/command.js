(function() {
  var colors, init, program;

  colors = require('colors');

  program = require('commander');

  exports.run = function() {
    var _ref;
    program.version('0.0.1').usage('[options] <URL>').option('-d, --destination [path]', 'the destination for the downloaded file', '.').option('-c, --connections [number]', 'max connections to try', parseInt, 3).parse(process.argv);
    if (((_ref = program.args) != null ? _ref.length : void 0) === 1) {
      return console.log("" + program.args[0]);
    } else {
      return console.log(program.helpInformation());
    }
  };

  init = function(path) {
    var growl;
    try {
      growl = require('growl');
      return growl("gobot: downloading " + path + " max-connections: " + program.connections);
    } catch (error) {
      return console.log("gobot: " + path + " max-connections: " + program.connections);
    }
  };

}).call(this);
