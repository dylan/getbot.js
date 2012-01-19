util  = require 'util'
fs    = require 'fs'
path  = require 'path'
http  = require 'http'
url   = require 'url'
request = require 'request'
{EventEmitter} = require 'events'

class Getbot extends EventEmitter
  constructor: (opts) ->
    # For reference
    @lastDownloaded = @downloadStart = @fileSize = @partsCompleted = @maxConnections = 0
    @bar = @fileExt = @fileBasename = @newFilename = @fileDescriptor = null

    options =
      uri: opts.address
      headers: {}
      method: 'HEAD'
    options.auth = "#{opts.user}:#{opts.pass}" if !options.auth
    @maxConnections = opts.connections
    @partsCompleted = 0

    if !opts.destination
      @filename = decodeURI(url.parse(opts.address).pathname.split("/").pop())
    else
      @filename = opts.destination
    
    @fileExt = path.extname @filename
    @fileBasename = path.basename(@filename, @fileExt)
    @newFilename = "#{@fileBasename}.getbot"
    
    req = request options, (error, response, body) =>
      if !error
        switch response.statusCode
          when 200
            if !response.headers['accept-ranges'] or response.headers['accept-ranges'] isnt "bytes"
              @emit 'noresume'
              @maxConnections = 1
            @fileSize = response.headers['content-length']

            @downloadStart = new Date
            @totalDownloaded = 0
            
            #TODO Check and see if this is necessary...
            try
              @emit 'downloadStart', "#{response.statusCode}"
              fs.open @newFilename,'w', (err, fd) =>
                fs.truncate fd, @fileSize
                @startParts options, @fileSize, @maxConnections, @download
            catch error
              @emit 'error', 'Not enough space.'
              return
          when 401 then @emit 'error', "401 Unauthorized"
          else @emit 'error', "#{response.statusCode}"
      else
        @emit 'error', "#{error}"
    
    req.end()
  
  download: (options, offset, end, number) =>
    options.headers = {}
    options.method = 'GET'
    options.headers["range"]= "bytes=#{offset}-#{end}"
    options.onResponse = true
    partNumber = number
    fops =
      flags: 'r+'
      start: offset
    
    file = fs.createWriteStream(@newFilename,fops)

    req = request options, (error, response) ->
      if error
        @emit 'error', error

    req.on 'data', (data) =>
      @totalDownloaded += data.length
      rate = @downloadRate @downloadStart
      file.write data
      @emit 'data', data, rate
      return
    
    req.on 'end', () =>
      @partsCompleted++
      @emit 'partComplete', partNumber
      if @partsCompleted == @maxConnections
        file.end()
        fs.rename(@newFilename,@filename)
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
      
  status: (status) ->
    process.stdout.write '\r\033[2K' + status

module.exports = Getbot
