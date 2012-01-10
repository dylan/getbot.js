util  = require 'util'
fs    = require 'fs'
path  = require 'path'
http  = require 'http'
url   = require 'url'
request = require 'request'
progressbar = require 'progress'

class Getbot
  @totalDownloaded = @lastDownloaded = 0

  constructor: (address, user, pass) ->
    options =
      uri: address
      
    options.auth = "#{user}:#{pass}" if !options.auth
      
    req = request.head options, (error, response, body) ->
      if !error
        switch response.statusCode
          when 200
            size = response.headers['content-length']
            Getbot.download address, user, pass, size
          when 401 then console.log "401 Unauthorized"
          else console.log "#{response.statusCode}"
      else
        console.log "#{error}"
    
    req.end()
  
  @download: (address, user, pass, size) ->
    options =
      uri: address
      
    options.auth = "#{user}:#{pass}" if !options.auth
    
    filename = decodeURI(url.parse(address).pathname.split("/").pop())
    fileExt = path.extname filename
    fileBasename = path.basename(filename, fileExt)
    newFilename = "#{fileBasename}.getbot"
    #Try and alloc hdd space (not sure if necessary)
    try
      fs.open newFilename,'w', (err, fd) ->
        fs.truncate fd, size
    catch error
      console.log "Not enough space."
      return
    
    console.log "Downloading #{filename}(#{makeReadable(size)})..."
    
    downloadStart = new Date
    file = fs.createWriteStream(newFilename)
    #downloadTimer = setInterval Getbot.downloadRate, 1000

    req = request.get options, (error, response, body) =>
      if error
        console.log error 

    bar = new progressbar '   downloading [:bar] :percent :eta | :rate', {
      complete: '=',
      incomplete: ' ',
      width: 20,
      total: parseInt size, 10
    }

    req.on 'data', (data) ->

      Getbot.totalDownloaded += data.length
      bar.tick(data.length, {'rate': Getbot.downloadRate downloadStart})
      file.write data
    .on 'end', () ->
      file.end()
      duration = Date.now() - downloadStart
      fs.rename(newFilename,filename)
      console.log "Download completed. It took #{(duration/1000).toFixed(1)} seconds."

      #clearInterval downloadTimer
  
  @downloadRate: (start) ->
    makeReadable(@totalDownloaded / (new Date - start) * 1024) + '/s'
    #Getbot.lastDownloaded = Getbot.totalDownloaded
    #rate

    #Getbot.status rate

  @status: (status) ->
    process.stdout.write '\r\033[2K' + status

  @save: (buffer) ->
    console.log("Writing file...")

makeReadable = (bytes) ->
  units= ['Bytes','KB','MB','GB','TB']
  unit = 0
  while bytes >= 1024
    unit++
    bytes = bytes/1024
    precision = if unit > 2 then 2 else 1
  return "#{bytes.toFixed(precision)} #{units[unit]}"


module.exports = Getbot
    