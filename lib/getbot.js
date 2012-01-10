(function() {
  var Getbot, fs, http, makeReadable, path, progressbar, request, url, util;

  util = require('util');

  fs = require('fs');

  path = require('path');

  http = require('http');

  url = require('url');

  request = require('request');

  progressbar = require('progress');

  Getbot = (function() {

    Getbot.totalDownloaded = Getbot.lastDownloaded = 0;

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
              try {
                fs.open(newFilename, 'w', function(err, fd) {
                  return fs.truncate(fd, size);
                });
              } catch (error) {
                console.log("Not enough space.");
                return;
              }
              return Getbot.startParts(options, size, 5, Getbot.download);
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
      var downloadStart, file, fileBasename, fileExt, filename, fops, newFilename, req,
        _this = this;
      filename = decodeURI(url.parse(options.uri).pathname.split("/").pop());
      fileExt = path.extname(filename);
      fileBasename = path.basename(filename, fileExt);
      newFilename = "" + fileBasename + ".getbot";
      console.log("Downloading " + filename + " range " + offset + " - " + end + " (" + (makeReadable(end - offset)) + ")...");
      downloadStart = new Date;
      fops = {
        flags: 'r+',
        start: offset
      };
      file = fs.createWriteStream(newFilename, fops);
      options.headers = {};
      options.method = 'GET';
      options.headers["range"] = "bytes=" + offset + "-" + end;
      req = request(options, function(error, response, body) {
        if (error) return console.log(error);
      });
      return req.on('data', function(data) {
        return file.write(data);
      }).on('end', function() {
        file.end();
        fs.rename(newFilename, filename);
        return console.log("Done!");
      });
    };

    Getbot.downloadRate = function(start) {
      return makeReadable(this.totalDownloaded / (new Date - start) * 1024) + '/s';
    };

    Getbot.startParts = function(options, bytes, parts, callback) {
      var i, partSize, _results;
      partSize = Math.ceil(1 * bytes / parts);
      i = 0;
      _results = [];
      while (i < parts) {
        console.log("Starting part " + i);
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

  module.exports = Getbot;

}).call(this);
