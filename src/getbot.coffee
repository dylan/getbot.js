util  = require 'util'
fs    = require 'fs'
path  = require 'path'
http  = require 'http'
url   = require 'url'
request = require 'request'
{EventEmitter} = require 'events'
#profiler = require 'v8-profile

class Getbot extends EventEmitter
  @lastDownloaded = @downloadStart = @size = 0
  @bar

  constructor: (address, user, pass) ->
    options =
      uri: address
      headers: {}
      method: 'HEAD'
    options.auth = "#{user}:#{pass}" if !options.auth
    
    req = request options, (error, response, body) =>
      if !error
        switch response.statusCode
          when 200
            @size = response.headers['content-length']
            filename = decodeURI(url.parse(address).pathname.split("/").pop())
            fileExt = path.extname filename
            fileBasename = path.basename(filename, fileExt)
            newFilename = "#{fileBasename}.getbot"
            @downloadStart = new Date
            @totalDownloaded = 0
            #Try and alloc hdd space (not sure if necessary)
            try
              @emit 'downloadStart', @downloadStart

              fs.open newFilename,'w', (err, fd) =>
                fs.truncate fd, @size
                @startParts options, @size, 5, @download
            catch error
              @emit 'error', 'Not enough space.'
              return
          when 401 then @emit 'error', "401 Unauthorized"
          else @emit 'error', "#{response.statusCode}"
      else
        @emit 'error', "#{error}"
    
    req.end()
  
  download: (options, offset, end) =>
    filename = decodeURI(url.parse(options.uri).pathname.split("/").pop())
    fileExt = path.extname filename
    fileBasename = path.basename(filename, fileExt)
    newFilename = "#{fileBasename}.getbot"
    
    options.headers = {}
    options.method = 'GET'
    options.headers["range"]= "bytes=#{offset}-#{end}"
    options.onResponse = true

    fops =
      flags: 'r+'
      start: offset
    file = fs.createWriteStream(newFilename,fops)

    req = request options, (error, response) ->
      if error
        @emit 'error', error

    req.on 'data', (data) =>
      @totalDownloaded += data.length
      rate = @downloadRate @downloadStart
      file.write data
      @emit 'data', data, rate
      return
    
    req.on 'end', () ->
      file.end()
      fs.rename(newFilename,filename)
  
  downloadRate: (start) =>
    @totalDownloaded / (new Date - start) * 1024

  startParts: (options, bytes, parts,callback) =>
    partSize = Math.ceil(1 * bytes/parts)
    i = 0
    while i < parts
      callback options, partSize*i, Math.min(partSize*(i+1)-1,bytes-1)
      i++

      @emit 'startPart', i
      
  status: (status) =>
    process.stdout.write '\r\033[2K' + status

module.exports = Getbot
