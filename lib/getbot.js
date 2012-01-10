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
      var options, req;
      options = {
        uri: address
      };
      if (!options.auth) options.auth = "" + user + ":" + pass;
      req = request.head(options, function(error, response, body) {
        var size;
        if (!error) {
          switch (response.statusCode) {
            case 200:
              size = response.headers['content-length'];
              return Getbot.download(address, user, pass, size);
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

    Getbot.download = function(address, user, pass, size) {
      var bar, downloadStart, file, fileBasename, fileExt, filename, newFilename, options, req,
        _this = this;
      options = {
        uri: address
      };
      if (!options.auth) options.auth = "" + user + ":" + pass;
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
      console.log("Downloading " + filename + "(" + (makeReadable(size)) + ")...");
      downloadStart = new Date;
      file = fs.createWriteStream(newFilename);
      req = request.get(options, function(error, response, body) {
        if (error) return console.log(error);
      });
      bar = new progressbar('   downloading [:bar] :percent :eta | :rate', {
        complete: '=',
        incomplete: ' ',
        width: 20,
        total: parseInt(size, 10)
      });
      return req.on('data', function(data) {
        Getbot.totalDownloaded += data.length;
        bar.tick(data.length, {
          'rate': Getbot.downloadRate(downloadStart)
        });
        return file.write(data);
      }).on('end', function() {
        var duration;
        file.end();
        duration = Date.now() - start;
        fs.rename(newFilename, filename);
        return console.log("Download completed. It took " + ((duration / 1000).toFixed(1)) + " seconds.");
      });
    };

    Getbot.downloadRate = function(start) {
      return makeReadable(this.totalDownloaded / (new Date - start) * 1024) + '/s';
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
