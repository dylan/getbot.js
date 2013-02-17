http           = require 'http-get'
nodeFS         = require 'node-fs'
fs             = require 'fs'
path           = require 'path'
os             = require 'os'
Util           = require 'util'
{EventEmitter} = require 'events'

{divmod}          = require('./utils')
{toReadableSize}  = require('./utils')

class Getbot extends EventEmitter
  constructor: (options)->
    @parts           = name:'', parts:[]
    @maxPartSize     = 1<<27 #128mb
    @maxConnections  = 4
    @completed = @active = @totalDownloaded = @fileSize = 0

    @destination     = options.destination
    @forceOverwrite  = options.force
    @debug           = options.debug
    @version         = options.version
    @resumeParts     = {}
    @queue           = []
    @startPath       = {}

    @fileName = @fileExt = @fileBasename = @statusFile = @cycle = @statusFileFD = null
    auth = "#{options.username}:#{options.password}" if options.password

    if auth
      auth = "Basic #{new Buffer(auth).toString('base64')}"

    @url =
      url: options.url
      headers:
        'Authorization': auth

    @.once 'headDone', ()=>
      # console.log 'head done'
      @defineParts(@fileSize)
    .once 'partsReady',()=>
      # console.log 'parts ready'
      @prepareFile(@destination)
    .once 'destinationReady',()=>
      # console.log 'File Ready'
      @readStatusFile()
    .once 'noStatusFile',()=>
      @emit 'startParts'
    .once 'resuming',()=>
      # console.log 'resuming'
      @emit 'startParts'
    .once 'startParts', ()=>
      for part,meta of @parts.parts
        @queue.push({meta,part})
      @startPart(@queue.shift())
    .on 'partAlreadyCompleted', (partNumber)=>
      # console.log "part already completed #{partNumber}"
      @totalDownloaded += @parts.parts[partNumber].last
      @emit 'partEnded', partNumber
    .on 'partStarted', (num)=>
      # console.log "part started #{num}"
      @active++
      if @active isnt @maxConnections and @queue.length != 0
        @startPart(@queue.shift())
    .on 'partEnded', (num)=>
      # console.log "part ended #{num}"
      @active--
      @completed++
      # console.log "#{@completed}/#{@parts.parts.length} completed. #{@totalDownloaded}/#{@fileSize}"
      if @completed == @parts.parts.length
        # console.log "/nDone"
        @stopWriteCycle()
        @removeStatusFile()
        @renameFile()
        @emit 'partsFinished'
      if @active isnt @maxConnections and @queue.length != 0
        @startPart(@queue.shift())


  start: ()->
    @emit 'start'
    http.head @url, (error, response)=>
      if error
        @emit 'error', error

      if 200 <= response.code < 300
        if response.headers['content-length'] isnt undefined and response.headers['content-length'] isnt 0
          if !response.headers['accept-ranges'] or response.headers['accept-ranges'] isnt "bytes"
            @emit 'noresume', response.code
            @maxConnections = 1

        url = if response.url then response.url else @url.url

        @fileName = decodeURI(url.split("/").pop())
        @fileSize = response.headers['content-length']
        @parts.name = @fileName

      switch response.code
        when 200 then @emit 'success',  '\x1b[32m200 OK'
        when 230 then @emit 'success',  '\x1b[32m230 Authentication Succesful'
        when 400 then @emit 'error',    '\x1b[31m400 Bad Request', response.headers
        when 401 then @emit 'error',    '\x1b[31m401 Unauthorized'
        when 403 then @emit 'error',    '\x1b[31m403 Forbidden'
        when 404 then @emit 'error',    '\x1b[31m404 Not Found'
        when 408 then @emit 'error',    '\x1b[31m408 Request Timeout'
        else
          @emit 'error', response.code, response.headers
      @emit 'headDone'


  startPart: (part)=>
    partNumber = parseInt(part.meta.number)
    @emit 'partStarted', partNumber
    meta = part.meta
    if meta.last > 0
      offset = meta.last+meta.start
    else
      offset = meta.start

    end = meta.end

    if offset is end
      @emit 'partAlreadyCompleted', partNumber
    else
      options =
        url : @url.url
        headers :
          'range' : "bytes=#{offset}-#{end}"
          'user-agent' : "Getbot.js/#{@version} (#{os.type()}/#{os.release()};#{os.arch()} like wget);"
          'Authorization': @url.headers.authorization
        stream : true
        debug: true

      fops =
        flags: 'r+'
        start: offset

      file = fs.createWriteStream(@newFilename, fops)

      http.get options, (error, result)=>
        if error
          @emit 'error', error

        result.stream.on 'data', (data)=>
          file.write(data)
          @parts.parts[partNumber].last = file.bytesWritten
          @totalDownloaded += data.length
          @emit 'progress'

        result.stream.on 'end', ()=>
          file.end()
          @parts.parts[partNumber].last = file.bytesWritten
          # console.log partNumber+" ended"
          @emit 'partEnded', partNumber

        # result.stream.on 'close',()=>
          # console.log 'closed'

        result.stream.on 'error',(error)=>
          @emit 'error', error

        result.stream.resume()

      file
      .on 'end', ()=>
        console.log "#{partNumber} stream closed"
        @parts.parts[partNumber].last = @parts.parts[partNumber].end-@parts.parts[partNumber].start





  defineParts: (bytes)->
    # if @debug then console.log "totalSize: #{bytes}"

    # find out how many parts we need
    [count,remainder] = divmod(bytes, @maxPartSize)
    partCount = count+Boolean(remainder)

    # figure out how big they need to be
    [size,r] = divmod(bytes, partCount)

    i = 0
    while i < partCount
      @parts.parts.push number: i, start: size*i, end: Math.min(size*(i+1)-1), last: 0
      i++

    @emit 'partsReady'


  prepareFile: ()->
    if @destination
      #Is this supposed to be a folder?
      isFolder = true if @destination.charAt(@destination.length-1) is '/'
      @startPath = process.cwd()
      @destPath = null

      target = if !isFolder then @destination else @fileName

      @fileExt = path.extname(target)
      @fileBasename = path.basename(target, @fileExt)

      fs.exists @destination, (exists)=>
        if exists and isFolder
          # Change to new path
          @openFile(@destination)
        else if isFolder
          # Recursively make folders until the path exists
          nodeFS.mkdir @destination, 0o777, true, () =>
            @openFile(@destination)
        else
          @destPath = path.dirname @destination
          if @path isnt @startPath
            nodeFS.mkdir @destPath, 0o777, true, ()=>
              @openFile(@destPath)
          else
            @openFile(@destPath)
    else
      @fileExt = path.extname(@fileName)
      @fileBasename = path.basename(@fileName, @fileExt)
      @openFile(process.cwd())


  openFile: (fileName)=>
    try
      process.chdir fileName
    catch error
      @emit 'error', error

    @fileName = @origFilename = "#{@fileBasename}#{@fileExt}"
    @newFilename = "#{@origFilename}.getbot"
    @statusFile = "#{@newFilename}.json"
    fs.exists @newFilename, (exists)=>
      if exists
        if !@forceOverwrite
          msg = if @destination then "#{@destination}#{@fileName}" else "#{@fileName}"
          @emit 'fileExists', msg
        # Smack 'at pig!
        fs.open @newFilename,'r+', (err, fd) =>
          @emit 'destinationReady'
          fs.close(fd)
      else
        # Smack 'at pig!
        fs.open @newFilename,'w+', (err, fd) =>
          fs.truncate fd, @fileSize,()=>
            @emit 'destinationReady'
            fs.close(fd)

  renameFile: ()=>
    fs.rename @newFilename, @origFilename, ()=>
      if @startPath
        process.chdir @startPath
        return

  readStatusFile: (callback)=>
    fs.exists(@statusFile, (exists)=>
      if exists
        fs.readFile @statusFile,(error, data)=>
          if error
            @emit 'error', error
          try
            @resumeParts = JSON.parse(data)
            if @parts.parts.length is @resumeParts.parts.length
              @parts = @resumeParts
              @emit 'resuming'
          catch error
            @emit 'noStatusFile'
            # @emit 'error', error
      else
        @emit 'noStatusFile'
      @startWriteCycle()
    )

  removeStatusFile:()->
    try
      fs.unlink @statusFile
    catch e
      @emit 'error', e

  startWriteCycle: ()=>
    @cycle = setInterval ()=>
      fs.open @statusFile, 'wx+',0o0666,(e,id)=>
        buffer = new Buffer(JSON.stringify(@parts,true,1))
        fs.write(id,buffer,()->
          fs.close(id)
        )
    ,1000

  stopWriteCycle: ()=>
    clearInterval(@cycle)

module.exports = Getbot
