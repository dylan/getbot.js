util  = require 'util'
fs    = require 'fs'
path  = require 'path'
http  = require 'http'
url   = require 'url'
request = require 'request'
progressbar = require 'progress'

class Getbot
  @totalDownloaded = @lastDownloaded = @downloadStart= 0
  @bar

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

            Getbot.bar = new progressbar 'Downloading: [:bar] :percent :eta | :rate', {
              complete: '=',
              incomplete: ' ',
              width: 20,
              total: parseInt size, 10
            }
            
            Getbot.downloadStart = new Date
            #Try and alloc hdd space (not sure if necessary)
            try
              fs.open newFilename,'w', (err, fd) ->
                fs.truncate fd, size
                Getbot.startParts(options, size, 5, Getbot.download)
            catch error
              console.log "Not enough space."
              return
            
          when 401 then console.log "401 Unauthorized"
          else console.log "#{response.statusCode}"
      else
        console.log "#{error}"
    
    req.end()
  
  @download: (options, offset, end) ->
    
    filename = decodeURI(url.parse(options.uri).pathname.split("/").pop())
    fileExt = path.extname filename
    fileBasename = path.basename(filename, fileExt)
    newFilename = "#{fileBasename}.getbot"
    
    options.headers = {}
    options.method = 'GET'
    options.headers["range"]= "bytes=#{offset}-#{end}"

    fops =
      flags: 'r+'
      start: offset
    file = fs.createWriteStream(newFilename,fops)

    req = request options, (error, response, body) ->
      if error
        console.log error

    req.on 'data', (data) ->
      Getbot.totalDownloaded += data.length
      Getbot.bar.tick(data.length, {'rate': Getbot.downloadRate Getbot.downloadStart})
      file.write data
    
    req.on 'end', () ->
      file.end()
      fs.rename(newFilename,filename)
  
  @downloadRate: (start) ->
    makeReadable(Getbot.totalDownloaded / (new Date - start) * 1024) + '/s'

  @startParts: (options, bytes, parts,callback) ->
    partSize = Math.ceil(1 * bytes/parts)
    i = 0
    while i < parts
      console.log "Starting part #{i+1}"
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
    