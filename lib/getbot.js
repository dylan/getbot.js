(function() {
  var Getbot, convertTime, estimateTime, fs, http, makeReadable, path, progressbar, request, url, util;

  util = require('util');

  fs = require('fs');

  path = require('path');

  http = require('http');

  url = require('url');

  request = require('request');

  progressbar = require('progress');

  Getbot = (function() {

    Getbot.totalDownloaded = Getbot.lastDownloaded = Getbot.downloadStart = 0;

    Getbot.bar;

    function Getbot(address, user, pass) {
      var downloads, options, req;
      options = {
        uri: address,
        headers: {},
        method: 'HEAD'
      };
      if (!options.auth) options.auth = "" + user + ":" + pass;
      downloads = 2;
      req = request(options, function(error, response, body) {
        var fileBasename, fileExt, filename, newFilename, size;
        if (!error) {
          switch (response.statusCode) {
            case 200:
              size = response.headers['content-length'];
              filename = decodeURI(url.parse(address).pathname.split("/").pop());
              fileExt = path.extname(filename);
              fileBasename = path.basename(filename, fileExt);
              newFilename = "" + fileBasename + ".getbot";
              Getbot.bar = new progressbar('Downloading: [:bar] :percent :etaa | :rate', {
                complete: '=',
                incomplete: ' ',
                width: 20,
                total: parseInt(size, 10)
              });
              Getbot.downloadStart = new Date;
              try {
                return fs.open(newFilename, 'w', function(err, fd) {
                  fs.truncate(fd, size);
                  return Getbot.startParts(options, size, 5, Getbot.download);
                });
              } catch (error) {
                console.log("Not enough space.");
              }
              break;
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

    Getbot.download = function(options, offset, end) {
      var file, fileBasename, fileExt, filename, fops, newFilename, req;
      filename = decodeURI(url.parse(options.uri).pathname.split("/").pop());
      fileExt = path.extname(filename);
      fileBasename = path.basename(filename, fileExt);
      newFilename = "" + fileBasename + ".getbot";
      options.headers = {};
      options.method = 'GET';
      options.headers["range"] = "bytes=" + offset + "-" + end;
      options.onResponse = true;
      fops = {
        flags: 'r+',
        start: offset
      };
      file = fs.createWriteStream(newFilename, fops);
      req = request(options, function(error, response) {
        if (error) return console.log(error);
      });
      req.on('data', function(data) {
        var rate;
        Getbot.totalDownloaded += data.length;
        rate = Getbot.downloadRate(Getbot.downloadStart);
        Getbot.bar.tick(data.length, {
          'rate': Getbot.downloadRate(Getbot.downloadStart)
        });
        return file.write(data);
      });
      return req.on('end', function() {
        file.end();
        return fs.rename(newFilename, filename);
      });
    };

    Getbot.downloadRate = function(start) {
      return makeReadable(Getbot.totalDownloaded / (new Date - start) * 1024) + '/s';
    };

    Getbot.startParts = function(options, bytes, parts, callback) {
      var i, partSize, _results;
      partSize = Math.ceil(1 * bytes / parts);
      i = 0;
      _results = [];
      while (i < parts) {
        console.log("Starting part " + (i + 1));
        callback(options, partSize * i, Math.min(partSize * (i + 1) - 1, bytes - 1));
        _results.push(i++);
      }
      return _results;
    };

    Getbot.status = function(status) {
      return process.stdout.write('\r\033[2K' + status);
    };

    Getbot.save = function(buffer) {
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

  estimateTime = function(rate, size) {
    return console.log('estimate time');
  };

  convertTime = function(seconds) {
    return console.log('converted time');
  };

  module.exports = Getbot;

}).call(this);
