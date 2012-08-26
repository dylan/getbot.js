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
    @statusCode = null
    @reqOptions =
      uri: opts.address
      auth: "#{opts.user}:#{opts.pass}" if opts.pass
    @started= false

    @partsCompleted = 0

    req = request.head @reqOptions, (error, response, body) =>
      if !error
        switch response.statusCode
          when 200
            @statusCode = response.statusCode
            if response.headers['content-length'] isnt undefined and response.headers['content-length'] isnt 0
              if !response.headers['accept-ranges'] or response.headers['accept-ranges'] isnt "bytes"
                @emit 'noresume', response.statusCode
                @maxConnections = 1

              # Grab the potential filename from the response if possible
              @fileName = decodeURI(response.request.uri.pathname.split("/").pop())
              @fileSize = response.headers['content-length']
              @downloadStart = new Date
              @totalDownloaded = 0

              @prepareFile(@fileName)

            else
              @emit 'error', "content-length is #{response.headers['content-length']}, aborting..."
          when 400 then @emit 'error', "400 Bad Request"
          when 401 then @emit 'error', "401 Unauthorized"
          else @emit 'error', "#{response.statusCode}"
      else
        @emit 'error', "#{error}"
    
    req.end()



  prepareFile: (fileName) =>
    if @destination
      #Is this supposed to be a folder?
      isFolder = true if @destination.charAt(@destination.length-1) is '/'
      @startPath = process.cwd()
      @path = null

      if !isFolder
        @fileExt = path.extname(@destination)
        @fileBasename = path.basename(@destination, @fileExt)
      else
        @fileExt = path.extname(fileName)
        @fileBasename = path.basename(fileName, @fileExt)

      fs.exists @destination, (exists)=>
        if exists and isFolder
          # Change to new path
          @openFile(@destination)
        else if isFolder
          # Recursively make folders until the path exists
          nodeFS.mkdir @destination, 0o777, true, () =>
            @openFile(@destination)
        else
          @path = path.dirname @destination
          if @path isnt @startPath
            nodeFS.mkdir @path, 0o777, true, ()=>
              @openFile(@path)
          else
            @openFile(@path)
    else
      @fileExt = path.extname(fileName)
      @fileBasename = path.basename(fileName, @fileExt)
      @openFile(process.cwd())

  openFile: (path) =>
    try
      process.chdir path
    catch error
      @emit 'error', error
    
    @fileName = @origFilename = "#{@fileBasename}#{@fileExt}"
    @newFilename = "#{@origFilename}.getbot"
    fs.exists @fileName, (exists)=>
      if exists
        if !@forceOverwrite
          msg = if @destination then "#{@destination}#{@fileName}" else "#{@fileName}"
          @emit 'fileExists', msg
      # Smack 'at pig!
      fs.open @newFilename,'w', (err, fd) =>
        fs.truncate fd, @fileSize,()=>
          @startParts @reqOptions, @fileSize, @maxConnections, @download


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
      @emit 'downloadStart', @statusCode
    .on 'data', (data) =>
      @totalDownloaded += data.length
      @rate = @downloadRate @downloadStart
      file.write data
      if !@started
        @emit 'downloadStart', @statusCode
        @started = true if @started is false
      @emit 'data', data, @rate
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
