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

      getbot = new Getbot options
      bar = null

      getbot.on 'noresume', () ->
        log "Resume not supported, using only one connection..."
      .on 'downloadStart', (statusCode) ->
        @readableSize = makeReadable(getbot.fileSize)
        log "#{getbot.filename} (#{makeReadable getbot.fileSize})", statusCode
        bar = new progressbar 'getbot '.green+'    Downloading: [:bar] :percent :size @ :rate',
          complete: "--".green,
          incomplete: '  ',
          width: 20,
          total: parseInt getbot.fileSize, 10,
      .on 'data', (data, rate) ->
        rate = "#{makeReadable rate}/s"
        bar.tick(data.length, {'rate': rate, 'size': @readableSize})
      # .on 'startPart', (num) ->
      #   log "Starting segment #{num}..."
      # .on 'partComplete', (num) ->
      #   log "Segment #{num} downloaded..."
      .on 'allPartsComplete', () ->
        log "Download finished..."
      .on 'error', (error) ->
        err error

      return
    else
      return log program.helpInformation()

makeReadable = (bytes) ->
  units= ['Bytes','KB','MB','GB','TB']
  unit = 0
  while bytes >= 1024
    unit++
    bytes = bytes/1024
    precision = if unit > 2 then 2 else 1
  return "#{bytes.toFixed(precision)} #{units[unit]}"

log = (message, status) ->
  state = if status then colors.inverse("#{status}".green) else "   "
  process.stdout.write '\ngetbot '.green+state+" #{message}\n"

err = (error, status) ->
  err = if status then status else "ERR"
  process.stdout.write '\ngetbot '.green+colors.inverse("#{err}".red)+" #{error}\n"

clearLine = () ->
  process.stdout.write '\r\033[2K'

clearLines = () ->
  process.stdout.write '\r\033[2K\r\033[1A\r\033[2K'