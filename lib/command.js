(function() {
  var cluster, colors, http, init, program, url;

  colors = require('colors');

  program = require('commander');

  cluster = require('cluster');

  http = require('http');

  url = require('url');

  exports.run = function() {
    var path, req, _ref;
    program.version('0.0.2').usage('[options] <URL>').option('-d, --destination [path]', 'the destination for the downloaded file', '.').option('-c, --connections [number]', 'max connections to try', parseInt, 3).option('-u, --username [user]', 'username used for basic auth').option('-p, --password [password', 'password used for basic auth').parse(process.argv);
    if (((_ref = program.args) != null ? _ref.length : void 0) === 1) {
      console.log("" + program.args[0]);
    } else {
      return console.log(program.helpInformation());
    }
    path = url.parse(program.args[0]);
    req = http.request({
      host: path.host,
      port: 80,
      path: path.pathname
    });
    req.on('response', function(response) {
      var auth, options, _req;
      if (response.headers['www-authenticate']) {
        if (!program.username || !program.password) {
          if (!program.auth) {
            console.log('ERROR: You must provided a username and password for basic auth requests.');
          } else {
            auth = program.auth;
          }
        } else {
          auth = program.username + ':' + program.password;
        }
      }
      options = {
        host: path.host,
        port: 80,
        path: path.name
      };
      if (auth) options.auth = auth;
      _req = http.request(options);
      _req.on('response', function(response) {
        return response.on('data', function(data) {
          return console.log('Chunk size: ' + (data.length / 1000).toFixed(2) + ' kilobytes');
        });
      });
      _req.on('error', function(err) {
        return console.log(err);
      });
      return _req.end();
    });
    req.on('error', function(err) {
      return console.log(err);
    });
    return req.end();
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
