util  = require 'util'
fs    = require 'fs'
path  = require 'path'
http  = require 'http'
url   = require 'url'
request = require 'request'
{EventEmitter} = require 'events'

class Getbot extends EventEmitter
  @lastDownloaded = @downloadStart = @fileSize = 0
  @bar = @fileExt = @fileBasename = @newFilename = null
  constructor: (opts) ->
    options =
      uri: opts.address
      headers: {}
      method: 'HEAD'
    options.auth = "#{opts.user}:#{opts.pass}" if !options.auth
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
            @fileSize = response.headers['content-length']

            @downloadStart = new Date
            @totalDownloaded = 0
            #Try and alloc hdd space (not sure if necessary)
            try
              @emit 'downloadStart', @downloadStart

              fs.open @newFilename,'w', (err, fd) =>
                fs.truncate fd, @fileSize
                @startParts options, @fileSize, opts.connections, @download
            catch error
              @emit 'error', 'Not enough space.'
              return
          when 401 then @emit 'error', "401 Unauthorized"
          else @emit 'error', "#{response.statusCode}"
      else
        @emit 'error', "#{error}"
    
    req.end()
  
  download: (options, offset, end) =>
    
    options.headers = {}
    options.method = 'GET'
    options.headers["range"]= "bytes=#{offset}-#{end}"
    options.onResponse = true

    fops =
      flags: 'r+'
      start: offset
    #console.log @newFilename
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
      file.end()
      fs.rename(@newFilename,@filename)
      @emit 'part completed', "#{}"
  
  downloadRate: (start) ->
    @totalDownloaded / (new Date - start) * 1024

  startParts: (options, bytes, parts, callback) ->
    partSize = Math.ceil(1 * bytes/parts)
    i = 0
    while i < parts
      callback options, partSize*i, Math.min(partSize*(i+1)-1,bytes-1)
      i++

      @emit 'startPart', i
      
  status: (status) ->
    process.stdout.write '\r\033[2K' + status

module.exports = Getbot
