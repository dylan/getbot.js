colors    = require 'colors'
program = require 'commander'
Getbot = require '../lib/getbot'
progressbar = require 'progress'

exports.run = ->
  
  program
    .version('0.0.2')
    .usage('[options] <URL>')
    .option('-d, --destination [path]', 'the destination for the downloaded file')
    .option('-c, --connections [number]', 'max connections to try', parseInt, 5)
    .option('-u, --user [string]', 'username used for basic auth')
    .option('-p, --pass [string]', 'password used for basic auth')
    .parse(process.argv)
  
    if program.args?.length is 1
      options = 
        address     : program.args[0]
        connections : program.connections
        destination : program.destination
        user        : program.user
        pass        : program.pass

      try
        getbot = new Getbot options          
      catch error
        err error

      bar = null

      getbot.on 'noresume', (statusCode) ->
        log "Resume not supported, using only one connection...", statusCode, '\n'
      .on 'downloadStart', (statusCode) ->
        log "#{getbot.filename} (#{makeReadable getbot.fileSize})", statusCode, '\n'
        @readableSize = makeReadable(getbot.fileSize)
        bar = new progressbar 'getbot '.green+'    ‹:bar› :percent :size @ :rate',
          complete: "—".green,
          incomplete: '—'.red,
          width: 20,
          total: parseInt getbot.fileSize, 10
        return
      .on 'data', (data, rate) ->
        rate = "#{makeReadable rate}/s"
        bar.tick(data.length, {'rate': rate, 'size': @readableSize})
      .on 'allPartsComplete', () ->
        log "Download finished...\n",null, '\n'
      .on 'error', (error) ->
        err error,null,'\n'
      return
    else
      return log program.helpInformation(), off

makeReadable = (bytes) ->
  units= ['Bytes','KB','MB','GB','TB']
  unit = 0
  while bytes >= 1024
    unit++
    bytes = bytes/1024
    precision = if unit > 2 then 2 else 1
  return "#{bytes.toFixed(precision)} #{units[unit]}"

log = (message, status, prefix) ->
  prefix = if prefix then prefix else ""
  state = if status then colors.inverse("#{status}".green) else "   "
  process.stdout.write prefix+'getbot '.green+state+" #{message}\n"

err = (error, status, prefix) ->
  prefix = if prefix then prefix else ""
  err = if status then status else "ERR"
  process.stdout.write prefix+'getbot '.green+colors.inverse("#{err}".red)+" #{error.toString().replace("Error: ","")}\n\n"
  process.exit(1)

clearLine = () ->
  process.stdout.write '\r\033[2K'

clearLines = () ->
  process.stdout.write '\r\033[2K\r\033[1A\r\033[2K'