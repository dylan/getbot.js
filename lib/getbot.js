(function() {
  var Getbot, fs, http, url, util;

  util = require('util');

  fs = require('fs');

  http = require('http');

  url = require('url');

  Getbot = (function() {

    function Getbot(address, user, pass) {
      var options, path, req;
      path = url.parse(address);
      options = {
        host: path.host,
        port: path.port,
        path: path.pathname,
        auth: path.auth,
        method: 'HEAD'
      };
      if (!options.auth) options.auth = "" + user + ":" + pass;
      req = http.request(options, function(response) {
        switch (response.statusCode) {
          case 401:
            return console.log("401 Unauthorized");
          case 200:
            return console.log(Getbot.makeReadable(response.headers['content-length']));
          default:
            return console.log("" + response.statusCode);
        }
      });
      req.end();
    }

    Getbot.prototype.status = function(status) {
      return console.log("" + status);
    };

    Getbot.prototype.save = function(buffer) {
      return console.log("Writing file...");
    };

    Getbot.makeReadable = function(bytes) {
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

    return Getbot;

  })();

  module.exports = Getbot;

}).call(this);
