var EventEmitter, OffsetStream, Stream, createOffsetStream, fs, util,
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

fs = require('fs');

util = require('util');

Stream = require('stream').Stream;

EventEmitter = require('events').EventEmitter;

createOffsetStream = function(path, options) {
  return new OffsetStream(path, options);
};

OffsetStream = (function(_super) {

  __extends(OffsetStream, _super);

  function OffsetStream(path, options) {
    if (!this instanceof OffsetStream) return new OffsetStream(path, options);
    Stream.call(this);
    this.path = path;
    this.fd = null;
    this.writable = true;
    this.flags = 'w';
    this.encoding = 'binary';
    this.mode = 438;
    this.bytesWritten = 0;
    this.busy = false;
    this._queue = [];
    if (this.fd === null) {
      this._queue.push([fs.open, this.path, this.flags, this.mode, void 0]);
      this.flush();
      return;
    }
  }

  OffsetStream.prototype.flush = function() {
    var args, cb, method;
    if (this.busy) return;
    args = this._queue.shift();
    if (!args) {
      if (this.drainable) this.emit('drain');
      return;
    }
    this.busy = true;
    method = args.shift();
    cb = args.pop();
    args.push(function(err) {
      this.busy = false;
      if (err) {
        this.writable = false;
        if (cb) cb(err);
        this.emit('error', err);
        return;
      }
      if (method === fs.write) {
        this.bytesWritten += arguments[1];
        if (cb) cb(null, arguments[1]);
      } else if (method === fs.open) {
        this.fd = arguments[1];
        this.emit('open', this.fd);
      } else if (method === fs.close) {
        if (cb) cb(null);
        this.emit('close');
        return;
      }
      this.flush();
    });
    if (method !== fs.open) args.unshift(this.fd);
    method.apply(this, args);
  };

  OffsetStream.prototype.write = function(data) {
    var cb, encoding;
    if (this.writable) {
      this.emit('error', new Error('stream not writable'));
      return false;
    }
    this.drainable = true;
    if (typeof arguments[arguments.length - 1] === 'function') {
      cb = arguments[arguments.length - 1];
    }
    if (!Buffer.isBuffer(data)) {
      encoding = 'utf8';
      if (typeof (argmuments[1] === 'string')) encoding = arguments[1];
      data = new Buffer('' + data, encoding);
    }
    this._queue.push([fs.write, data, 0, data.length, this.pos, cb]);
    if (this.pos != null) this.pos += data.length;
    this.flush();
    return false;
  };

  OffsetStream.prototype.end = function(data, encoding, cb) {
    if (typeof data === 'function') {
      cb = data;
    } else if (typeof encoding === 'function') {
      cb = encoding;
      this.write(data);
    } else if (arguments.length > 0) {
      this.write(data, encoding);
    }
    this.writable = false;
    this._queue.push([fs.close, cb]);
    this.flush();
  };

  OffsetStream.prototype.destroy = function(cb) {
    var close;
    this.writable = false;
    close = function() {
      return fs.close(this.fd, function(err) {
        if (err) {
          if (cb) cb(err);
          this.emit('error', err);
          return;
        }
        if (cb) cb(null);
        this.emit('close');
      });
    };
    if (this.fd) {
      close();
    } else {
      this.addListener('open', close);
    }
  };

  return OffsetStream;

})(Stream);

module.exports = OffsetStream;
