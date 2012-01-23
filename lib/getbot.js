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

    function Getbot(opts) {
      this.startParts = __bind(this.startParts, this);
      this.download = __bind(this.download, this);
      var address, options, req,
        _this = this;
      this.lastDownloaded = this.downloadStart = this.fileSize = this.partsCompleted = this.maxConnections = 0;
      this.bar = this.fileExt = this.fileBasename = this.newFilename = this.fileDescriptor = null;
      options = {
        uri: opts.address,
        headers: {},
        method: 'HEAD'
      };
      if (!options.auth) options.auth = "" + opts.user + ":" + opts.pass;
      this.maxConnections = opts.connections;
      this.partsCompleted = 0;
      address = url.parse(opts.address);
      if (address.protocol !== 'http:' || address.protocol !== 'https:') {
        throw new Error("Getbot only supports HTTP or HTTPs at the moment.");
      }
      if (!opts.destination) {
        this.filename = decodeURI(address.pathname.split("/").pop());
      } else {
        this.filename = opts.destination;
      }
      this.fileExt = path.extname(this.filename);
      this.fileBasename = path.basename(this.filename, this.fileExt);
      this.newFilename = "" + this.fileBasename + ".getbot";
      req = request(options, function(error, response, body) {
        if (!error) {
          switch (response.statusCode) {
            case 200:
              if (!response.headers['accept-ranges'] || response.headers['accept-ranges'] !== "bytes") {
                _this.emit('noresume');
                _this.maxConnections = 1;
              }
              _this.fileSize = response.headers['content-length'];
              _this.downloadStart = new Date;
              _this.totalDownloaded = 0;
              try {
                _this.emit('downloadStart', "" + response.statusCode);
                return fs.open(_this.newFilename, 'w', function(err, fd) {
                  fs.truncate(fd, _this.fileSize);
                  return _this.startParts(options, _this.fileSize, _this.maxConnections, _this.download);
                });
              } catch (error) {
                _this.emit('error', "" + error);
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

    Getbot.prototype.download = function(options, offset, end, number) {
      var file, fops, partNumber, req,
        _this = this;
      options.headers = {};
      options.method = 'GET';
      options.headers["range"] = "bytes=" + offset + "-" + end;
      options.onResponse = true;
      partNumber = number;
      fops = {
        flags: 'r+',
        start: offset
      };
      file = fs.createWriteStream(this.newFilename, fops);
      req = request(options, function(error, response) {
        if (error) return this.emit('error', "" + error);
      });
      return req.on('data', function(data) {
        var rate;
        _this.totalDownloaded += data.length;
        rate = _this.downloadRate(_this.downloadStart);
        file.write(data);
        _this.emit('data', data, rate);
      }).on('end', function() {
        _this.partsCompleted++;
        _this.emit('partComplete', partNumber);
        if (_this.partsCompleted === _this.maxConnections) {
          file.end();
          fs.rename(_this.newFilename, _this.filename);
          return _this.emit('allPartsComplete');
        }
      }).on('error', function(error) {
        return _this.emit('error', "" + error);
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
        callback(options, partSize * i, Math.min(partSize * (i + 1) - 1, bytes - 1), i + 1);
        i++;
        _results.push(this.emit('startPart', i));
      }
      return _results;
    };

    return Getbot;

  })(EventEmitter);

  module.exports = Getbot;

}).call(this);
