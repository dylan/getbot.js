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
      this.contentLength = 0;
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
            return console.log(exports.makeReadable(response.headers['content-length']));
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

    return Getbot;

  })();

  exports.makeReadable = function(bytes) {
    var unit, units;
    units = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    unit = 0;
    while (bytes >= 1024) {
      unit++;
      bytes = bytes / 1024;
    }
    return "" + (bytes.toFixed(1)) + " " + units[unit];
  };

  module.exports = Getbot;

}).call(this);
