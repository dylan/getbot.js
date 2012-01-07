colors    = require 'colors'
program = require 'commander'
cluster = require 'cluster'
http = require 'http'
url = require 'url'
util = require 'util'

exports.run = ->
  program
    .version('0.0.2')
    .usage('[options] <URL>')
    .option('-d, --destination [path]', 'the destination for the downloaded file','.')
    .option('-c, --connections [number]', 'max connections to try', parseInt, 3)
    .option('-u, --user [string]', 'username used for basic auth')
    .option('-p, --pass [string]', 'password used for basic auth')
    .parse(process.argv)
  
    if program.args?.length is 1
      init "#{program.args[0]}"
    else
      return console.log program.helpInformation()

    path = url.parse program.args[0]
    req = http.request
      host: path.host
      port: 80
      path: path.pathname
      auth: path.auth

    req.on 'response', (response) ->
      if response.headers['www-authenticate']
        if !program.user or !program.pass 
          util.log "#{program.user} : #{program.pass}"
          console.log 'ERROR: You must provided a username and password for basic auth requests.'
          process.exit(0)
        else
          auth = program.user + ':' + program.pass
        

      options = 
        host: path.host
        port: 80
        path: path.name

      if (auth)
        options.auth = auth

      _req = http.request options

      _req.on 'response', (response) ->
        response.on 'data', (data) ->
          console.log 'Chunk size: ' + (data.length).toFixed(2) + ' kilobytes'
          process.exit(0)

      _req.on 'error', (err) ->
        console.log err

      _req.end()
                
    req.on 'error', (err) ->
      console.log err

    req.end()

init = (path) ->
    console.log "getbot: #{path} max-connections: #{program.connections}"