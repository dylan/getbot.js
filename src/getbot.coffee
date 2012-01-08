util  = require 'util'
fs    = require 'fs'
http  = require 'http'
url   = require 'url'

class Getbot
  constructor: (address, user, pass) ->
    # console.log("#{url},#{user},#{pass}")
    path = url.parse address
    @contentLength = 0
    options =
      host: path.host
      port: path.port
      path: path.pathname
      auth: path.auth
      method: 'HEAD'
      
    options.auth = "#{user}:#{pass}" if !options.auth
      
    req = http.request options, (response) ->
      switch response.statusCode
        when 401 then console.log "401 Unauthorized"
        when 200 then console.log exports.makeReadable(response.headers['content-length'])
        else console.log "#{response.statusCode}"
    
    req.end()
    
  status: (status) ->
    console.log("#{status}")

  save: (buffer) ->
    console.log("Writing file...")
  
exports.makeReadable = (bytes) ->
  units= ['Bytes','KB','MB','GB','TB']
  unit = 0
  while bytes >= 1024
    unit++
    bytes = bytes/1024
  return "#{bytes.toFixed(1)} #{units[unit]}"
    
module.exports = Getbot
    