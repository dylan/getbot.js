util  = require 'util'
fs    = require 'fs'
http  = require 'http'
url   = require 'url'
request = require 'request'

class Getbot
  constructor: (address, user, pass) ->

    options =
      uri: address
      
    options.auth = "#{user}:#{pass}" if !options.auth
      
    req = request.head options, (error, response, body) ->
      if !error
        switch response.statusCode
          when 200 then console.log makeReadable(response.headers['content-length'])
          when 401 then console.log "401 Unauthorized"
          else console.log "#{response.statusCode}"
      else
        console.log "#{error}"
    
    req.end()
    
  status: (status) ->
    console.log("#{status}")

  save: (buffer) ->
    console.log("Writing file...")

makeReadable = (bytes) ->
  units= ['Bytes','KB','MB','GB','TB']
  unit = 0
  while bytes >= 1024
    unit++
    bytes = bytes/1024
    precision = if unit > 2 then 2 else 1
  return "#{bytes.toFixed(precision)} #{units[unit]}"


module.exports = Getbot
    