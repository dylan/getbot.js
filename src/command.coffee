fs          = require 'fs'
colors      = require 'colors'
program     = require 'commander'
Getbot      = require '../lib/getbot'
progressbar = require 'progress'

exports.run = ->
  version = '0.0.7c'
  program
    .version(version)
    .usage('[options] <URL>')
    .option('-d, --destination [path]', 'the destination for the downloaded file(s)')
    .option('-f, --force', 'force getbot to overwrite any existing file or folder')
    .option('-c, --connections [number]', 'max connections to try', parseInt, 5)
    .option('-u, --user [string]', 'username used for basic http auth')
    .option('-p, --pass [string]', 'password used for basic http auth')
    .option('-l, --list [path]', 'a list of urls (one on each line) to read in and download from')
    .option('-q, --quiet', 'run getbot silently')
    .parse(process.argv)
    
    if program.args?.length is 1
      list = [program.args[0]]
    else
      list = loadList(program.list)
      list.reverse()
      listDownload = true

    options =
      connections : program.connections
      destination : program.destination
      force       : program.force
      user        : program.user
      pass        : program.pass
      quiet       : program.quiet
      listDownload: listDownload
      version     : version

    try
      startBot options, list
    catch error
      err error
    return


startBot = (options, list) ->
  options.address = list.pop()
  getbot = new Getbot options
  bar = null
  
  #Setup events
  getbot
  .on 'noresume', (statusCode) ->
    log "Resume not supported, using only one connection...", statusCode, '\n'
  .on 'downloadStart', (statusCode) ->
    if !options.quiet
      log "#{getbot.fileName} (#{makeReadable getbot.fileSize})", statusCode, '\n'
      @readableSize = makeReadable(getbot.fileSize)
      bar = new progressbar 'getbot '.green+'    ‹:bar› :percent :size @ :rate',
        complete: "—".green,
        incomplete: ' ',
        width: 20,
        total: parseInt getbot.fileSize, 10
      update = 0
      updateTick = setInterval(
        ()=>
          rate = "#{makeReadable @rate}/s"
          bar.tick(@tickBuffer, {'rate': rate, 'size': @readableSize})
          @tickBuffer = 0
          if parseInt(getbot.fileSize) is parseInt(getbot.totalDownloaded)
            log "Download finished.\n",null, '\n'
            clearInterval(updateTick)
      ,500)
    return
  .on 'data', (data, rate) ->
    if !options.quiet
      @tickBuffer += data.length
      @totalDL += @tickBuffer
      return
  .on 'allPartsComplete', () =>
    if list.length >= 1
      startBot(options, list)
    else
      if options.quiet
        process.exit(0)
  .on 'fileExists', (filePath) ->
    err filePath + " already exists, aborting...", null, '\n'
  .on 'error', (error) ->
    err error,null,'\n'

loadList = (filename) ->
  downloadList = []
  fs.readFileSync(filename)
  .toString()
  .split('\n')
  .forEach (line) ->
    if line != ''
      downloadList.push line
  downloadList

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
  process.stdout.write '\r\x33[2K'

clearLines = () ->
  process.stdout.write '\r\x33[2K\r\x33[1A\r\x33[2K'
