(function() {
  var EventEmitter, Getbot, fs, http, path, request, url, util,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  util = require('util');

  fs = require('fs');

  path = require('path');

  http = require('http');

  url = require('url');

  request = require('request');

  EventEmitter = require('events').EventEmitter;

  Getbot = (function(_super) {

    __extends(Getbot, _super);

    Getbot.lastDownloaded = Getbot.downloadStart = Getbot.size = 0;

    Getbot.bar;

    function Getbot(address, user, pass) {
      this.status = __bind(this.status, this);
      this.startParts = __bind(this.startParts, this);
      this.downloadRate = __bind(this.downloadRate, this);
      this.download = __bind(this.download, this);
      var options, req,
        _this = this;
      options = {
        uri: address,
        headers: {},
        method: 'HEAD'
      };
      if (!options.auth) options.auth = "" + user + ":" + pass;
      req = request(options, function(error, response, body) {
        var fileBasename, fileExt, filename, newFilename;
        if (!error) {
          switch (response.statusCode) {
            case 200:
              _this.size = response.headers['content-length'];
              filename = decodeURI(url.parse(address).pathname.split("/").pop());
              fileExt = path.extname(filename);
              fileBasename = path.basename(filename, fileExt);
              newFilename = "" + fileBasename + ".getbot";
              _this.downloadStart = new Date;
              _this.totalDownloaded = 0;
              try {
                _this.emit('downloadStart', _this.downloadStart);
                return fs.open(newFilename, 'w', function(err, fd) {
                  fs.truncate(fd, _this.size);
                  return _this.startParts(options, _this.size, 5, _this.download);
                });
              } catch (error) {
                _this.emit('error', 'Not enough space.');
              }
              break;
            case 401:
              return _this.emit('error', "401 Unauthorized");
            default:
              return _this.emit('error', "" + response.statusCode);
          }
        } else {
          return _this.emit('error', "" + error);
        }
      });
      req.end();
    }

    Getbot.prototype.download = function(options, offset, end) {
      var file, fileBasename, fileExt, filename, fops, newFilename, req,
        _this = this;
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
        if (error) return this.emit('error', error);
      });
      req.on('data', function(data) {
        var rate;
        _this.totalDownloaded += data.length;
        rate = _this.downloadRate(_this.downloadStart);
        file.write(data);
        _this.emit('data', data, rate);
      });
      return req.on('end', function() {
        file.end();
        return fs.rename(newFilename, filename);
      });
    };

    Getbot.prototype.downloadRate = function(start) {
      return this.totalDownloaded / (new Date - start) * 1024;
    };

    Getbot.prototype.startParts = function(options, bytes, parts, callback) {
      var i, partSize, _results;
      partSize = Math.ceil(1 * bytes / parts);
      i = 0;
      _results = [];
      while (i < parts) {
        callback(options, partSize * i, Math.min(partSize * (i + 1) - 1, bytes - 1));
        i++;
        _results.push(this.emit('startPart', i));
      }
      return _results;
    };

    Getbot.prototype.status = function(status) {
      return process.stdout.write('\r\033[2K' + status);
    };

    return Getbot;

  })(EventEmitter);

  module.exports = Getbot;

}).call(this);
