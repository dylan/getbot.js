stream          = require 'stream'
{EventEmitter}  = require 'EventEmitter'

class File extends stream.Writable
  constructor: (arguments) ->
    @size = 0
    @path = @name = null

  open: ()->
    @_writeStream = new Writable @path

  write: (buffer, callback)->
    @_writeStream.write buffer, ()=>
      @size += buffer.length
      @emit 'progress', @size
      callback()

  end: (callback)->
    @_writeStream.end ()=>
      @emit 'end'
      callback()


module.exports = File
