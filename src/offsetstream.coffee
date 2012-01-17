#Lets stub this puppy out...
fs = require 'fs'
util = require 'util'
{Stream} = require 'stream'
{EventEmitter} = require 'events'

#Based on fs.writeStream, but with the goal of allowing writing at different offsets in a file...
createOffsetStream = (path, options) ->
  new OffsetStream path, options

class OffsetStream extends Stream
  constructor: (path, options) ->
    if !@ instanceof OffsetStream
      return new OffsetStream path, options
    Stream.call(@)

    @path = path
    @fd = null
    @writable = true

    @flags = 'w'
    @encoding = 'binary'
    @mode = 438
    @bytesWritten = 0
    
    @busy = false
    @_queue = []
    
    if @fd is null
      @_queue.push [fs.open, @path, @flags, @mode, undefined]
      @flush()
      return

  flush: () ->
    if @busy
      return

    args = @_queue.shift()
    if !args
      if @drainable then @emit 'drain'
      return
    
    @busy = true

    method = args.shift()
    cb = args.pop()

    args.push( (err)->
      @busy = false

      if err
        @writable = false
        if cb
          cb err
        @emit 'error', err
        return
      
      if method is fs.write
        @bytesWritten += arguments[1]
        if cb
          cb null, arguments[1]
      else if method is fs.open
        @fd = arguments[1]
        @emit 'open', @fd
      else if method is fs.close
        if cb
          cb null
        @emit 'close'
        return
      
      @flush()
      return
    )

    if method != fs.open
      args.unshift(@fd)
    
    method.apply this, args
    return

  write: (data) ->
    if @writable
      @emit 'error', new Error 'stream not writable'
      return false
    
    @drainable = true
    
    if typeof(arguments[arguments.length-1]) == 'function'
      cb = arguments[arguments.length-1]
    
    if !Buffer.isBuffer data
      encoding = 'utf8'
      if typeof(argmuments[1] == 'string')
        encoding = arguments[1]
      data = new Buffer ''+data, encoding
    
    @_queue.push [fs.write, data, 0, data.length, @pos, cb]

    
    @pos += data.length if @pos?
    
    @flush()
    return false

  end: (data, encoding, cb) ->
    if typeof data is 'function'
      cb = data
    else if typeof encoding is 'function'
      cb = encoding
      @write data
    else if arguments.length > 0
      @write data, encoding
    @writable = false
    @_queue.push [fs.close, cb]
    @flush()
    return

  destroy: (cb) ->
    @writable = false
    close = () ->
      fs.close(@fd, (err)->
        if err
          if cb
            cb err
          @emit 'error', err
          return
        if cb
          cb null
        @emit 'close'
        return
      )
    if @fd
      close()
      return
    else
      @addListener 'open', close
      return

module.exports = OffsetStream
