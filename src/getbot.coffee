util           = require 'util'
fs             = require 'node-fs'
path           = require 'path'
http           = require 'http'
url            = require 'url'
request        = require 'request'
{EventEmitter} = require 'events'

class Getbot extends EventEmitter
  constructor: (opts) ->
    
    @destination = opts.destination
    @maxConnections = opts.connections

    options =
      uri: opts.address
      headers: {}
      method: 'HEAD'
    options.auth = "#{opts.user}:#{opts.pass}" if !options.auth

    @partsCompleted = 0
    
    if @destination
      @filename = @destination
      @path = path.dirname(@destination)
      if @path
        @startPath = process.cwd()
        fs.mkdir @path, 0o0777, true, () =>
          process.chdir @path
    else
      @filename = decodeURI(url.parse(opts.address).pathname.split("/").pop())
    
    @fileExt      = path.extname @filename
    @fileBasename = path.basename(@filename, @fileExt)
    @fileDirname  = path.dirname(@filename)
    @origFilename = "#{@fileBasename}#{@fileExt}"
    @newFilename  = "#{@origFilename}.getbot"
    
    req = request options, (error, response, body) =>
      if !error
        switch response.statusCode
          when 200
            if response.headers['content-length'] isnt undefined and response.headers['content-length'] isnt 0

              if !response.headers['accept-ranges'] or response.headers['accept-ranges'] isnt "bytes"
                @emit 'noresume', response.statusCode
                @maxConnections = 1

              @fileSize = response.headers['content-length']
              @downloadStart = new Date
              @totalDownloaded = 0

              try
                @emit 'downloadStart', "#{response.statusCode}"
                fs.open @newFilename,'w', (err, fd) =>
                  fs.truncate fd, @fileSize
                  @startParts options, @fileSize, @maxConnections, @download
              catch error
                @emit 'error', error
            else
              @emit 'error', "content-length is #{response.headers['content-length']}, aborting..."
          when 400 then @emit 'error', "400 Bad Request"
          when 401 then @emit 'error', "401 Unauthorized"
          else @emit 'error', "#{response.statusCode}"
      else
        @emit 'error', "#{error}"
    
    req.end()
  
  download: (options, offset, end, number) =>
    options.headers = {}
    options.pool = {}
    options.method = 'GET'
    options.headers["range"] = "bytes=#{offset}-#{end}"
    options.onResponse = true
    options.pool['maxSockets'] = @maxConnections
    partNumber = number
    fops =
      flags: 'r+'
      start: offset
    
    file = fs.createWriteStream(@newFilename,fops)

    req = request options, (error, response) ->
      if error
        @emit 'error', error
    .on 'data', (data) =>
      @totalDownloaded += data.length
      rate = @downloadRate @downloadStart
      file.write data
      @emit 'data', data, rate
      return
    .on 'end', () =>
      @partsCompleted++
      @emit 'partComplete', partNumber
      if @partsCompleted == @maxConnections
        file.end()
        fs.rename @newFilename, @origFilename, ()=>
          if @destination and @listDownload
            process.chdir @startPath
          @emit 'allPartsComplete'
  
  downloadRate: (start) ->
    @totalDownloaded / (new Date - start) * 1024

  startParts: (options, bytes, parts, callback) =>
    partSize = Math.ceil(1 * bytes/parts)
    i = 0
    while i < parts
      callback options, partSize*i, Math.min(partSize*(i+1)-1, bytes-1), i+1
      i++
      @emit 'startPart', i

module.exports = Getbot
