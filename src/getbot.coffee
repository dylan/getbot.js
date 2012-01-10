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
      headers: {}
      method: 'HEAD'
    options.auth = "#{user}:#{pass}" if !options.auth
    
    downloads = 2
    req = request options, (error, response, body) ->
      if !error
        switch response.statusCode
          when 200
            size = response.headers['content-length']
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
            Getbot.startParts(options, size, 5, Getbot.download)
          when 401 then console.log "401 Unauthorized"
          else console.log "#{response.statusCode}"
      else
        console.log "#{error}"
    
    req.end()
  
  @download: (options, offset, end) ->
    # console.log ""
    filename = decodeURI(url.parse(options.uri).pathname.split("/").pop())
    fileExt = path.extname filename
    fileBasename = path.basename(filename, fileExt)
    newFilename = "#{fileBasename}.getbot"
    console.log "Downloading #{filename} range #{offset} - #{end} (#{makeReadable(end-offset)})..."
    
    downloadStart = new Date
    fops =
      flags: 'r+'
      start: offset
    file = fs.createWriteStream(newFilename,fops)
    options.headers = {}
    options.method = 'GET'
    options.headers["range"]= "bytes=#{offset}-#{end}"
    # console.log "#{util.inspect options}"
    req = request options, (error, response, body) =>
      
      if error
        console.log error

      # bar = new progressbar 'Downloading: [:bar] :percent :eta | :rate', {
      #   complete: '=',
      #   incomplete: ' ',
      #   width: 20,
      #   total: parseInt end, 10
      # }

    req.on 'data', (data) ->
      # Getbot.totalDownloaded += data.length
      # bar.tick(data.length, {'rate': Getbot.downloadRate downloadStart})
      file.write data
    .on 'end', () ->
      file.end()
      # duration = Date.now() - downloadStart
      fs.rename(newFilename,filename)
      # console.log "\nDownload completed.\nIt took #{(duration/1000).toFixed(1)} seconds."
      console.log "Done!"
  
  @downloadRate: (start) ->
    makeReadable(@totalDownloaded / (new Date - start) * 1024) + '/s'

  @startParts: (options, bytes, parts,callback) ->
    partSize = Math.ceil(1 * bytes/parts)
    i = 0
    while i < parts
      console.log "Starting part #{i}"
      callback options, partSize*i, Math.min(partSize*(i+1)-1,bytes-1)
      i++
      
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
    