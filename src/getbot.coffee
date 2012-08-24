util           = require 'util'
fs             = require 'fs'
path           = require 'path'
http           = require 'http'
url            = require 'url'
os             = require 'os'
request        = require 'request'
nodeFS         = require 'node-fs'
{EventEmitter} = require 'events'

class Getbot extends EventEmitter
  constructor: (opts) ->
    
    @destination    = opts.destination
    @forceOverwrite = opts.force
    @maxConnections = opts.connections
    @listDownload   = opts.listDownload

    reqOptions =
      uri: opts.address
      auth: "#{opts.user}:#{opts.pass}" if opts.pass

    @partsCompleted = 0
    @origFilename = @newFilename = @fileExt = @fileBasename = @filename = @path = null

    if @destination
      # Is this supposed to be a folder?
      if @destination.charAt(@destination.length-1) is '/'
        # grab the filename from the url
        @filename     = decodeURI(url.parse(opts.address).pathname.split("/").pop())
        @fileExt      = path.extname(@filename)
        @fileBasename = path.basename(@filename, @fileExt)
      else
        @fileExt      = path.extname(@destination)
        @fileBasename = path.basename(@destination, @fileExt)

      # See if path already exists
      fs.exists @destination, (exists) =>
        if exists
          if @destination.charAt(@destination.length-1) is '/'
            # Remember where we started
            @startPath = process.cwd()

            # Change to new path
            process.chdir @destination

            if !@forceOverwrite
              # Check to see if the file exists
              fs.exists process.cwd()+'/'+@fileBasename+@fileExt, (exists) =>
                if exists
                  @emit 'fileExists', "#{@destination+@fileBasename+@fileExt}"
          else
            if !@forceOverwrite
              @emit 'fileExists', "#{@destination}"
            process.chdir path.dirname(@destination)
        else
          # Is the destination meant to be a folder?
          if @destination.charAt(@destination.length-1) is '/'
            # Remember where we started
            @startPath = process.cwd()

            # Recursively make folders until the path exists
            nodeFS.mkdir @destination, 0o777, true, () =>
              # Change to new path
              process.chdir @destination

          else
            if path.dirname(@destination) isnt '.'
              # Remember where we started
              @startPath = process.cwd()

              @path = path.dirname(@destination)

              # Recursively make folders until the path exists
              nodeFS.mkdir @path, 0o777, true, () =>
                # Change to new path
                process.chdir @path

        @filename = @origFilename = "#{@fileBasename}#{@fileExt}"
        @newFilename  = "#{@origFilename}.getbot"

    else
      @filename     = decodeURI(url.parse(opts.address).pathname.split("/").pop())

      @fileExt      = path.extname(@filename)
      @fileBasename = path.basename(@filename, @fileExt)

      @origFilename = "#{@fileBasename}#{@fileExt}"
      @newFilename  = "#{@origFilename}.getbot"

    req = request.head reqOptions, (error, response, body) =>
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
                  @startParts reqOptions, @fileSize, @maxConnections, @download
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

    options.method = 'GET'
    options.headers = {}
    options.headers["range"] = "bytes=#{offset}-#{end}"
    options.headers['user-agent'] = "Getbot.js/#{options.version} (#{os.type()}/#{os.release()};#{os.arch()} like wget);"
    options.onResponse = true
    options.pool = {}
    options.pool['maxSockets'] = @maxConnections

    partNumber = number
    fops =
      flags: 'r+'
      start: offset
    
    file = fs.createWriteStream(@newFilename,fops)

    req = request.get options, (error, response) ->
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
