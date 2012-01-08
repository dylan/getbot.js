(function() {
  var Getbot, fs, http, makeReadable, request, url, util;

  util = require('util');

  fs = require('fs');

  http = require('http');

  url = require('url');

  request = require('request');

  Getbot = (function() {

    function Getbot(address, user, pass) {
      var options, req;
      options = {
        uri: address
      };
      if (!options.auth) options.auth = "" + user + ":" + pass;
      req = request.head(options, function(error, response, body) {
        if (!error) {
          switch (response.statusCode) {
            case 200:
              return console.log(makeReadable(response.headers['content-length']));
            case 401:
              return console.log("401 Unauthorized");
            default:
              return console.log("" + response.statusCode);
          }
        } else {
          return console.log("" + error);
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

  module.exports = Getbot;

}).call(this);
