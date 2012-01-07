colors    = require 'colors'
program = require 'commander'
cluster = require 'cluster'
http = require 'http'
url = require 'url'

exports.run = ->
  program
    .version('0.0.2')
    .usage('[options] <URL>')
    .option('-d, --destination [path]', 'the destination for the downloaded file','.')
    .option('-c, --connections [number]', 'max connections to try', parseInt, 3)
    .option('-u, --username [user]', 'username used for basic auth')
    .option('-p, --password [password', 'password used for basic auth')
    .parse(process.argv)
  
    if program.args?.length is 1
      console.log "#{program.args[0]}"
    else
      return console.log program.helpInformation()

    path = url.parse program.args[0]
    req = http.request
      host: path.host
      port: 80
      path: path.pathname

    req.on 'response', (response) ->
      if response.headers['www-authenticate']
        if (! program.username || ! program.password)
          if (! program.auth)
            console.log 'ERROR: You must provided a username and password for basic auth requests.'
          else
            auth = program.auth
        else
          auth = program.username + ':' + program.password

      options = 
        host: path.host
        port: 80
        path: path.name

      if (auth)
        options.auth = auth

      _req = http.request options

      _req.on 'response', (response) ->
        response.on 'data', (data) ->
          console.log 'Chunk size: ' + (data.length / 1000).toFixed(2) + ' kilobytes'

      _req.on 'error', (err) ->
        console.log err

      _req.end()
                
    req.on 'error', (err) ->
      console.log err

    req.end()

init = (path) ->
  try
    growl = require 'growl'
    growl "gobot: downloading #{path} max-connections: #{program.connections}"
  catch error
    console.log "gobot: #{path} max-connections: #{program.connections}"