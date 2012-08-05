fs          = require 'fs'
colors      = require 'colors'
program     = require 'commander'
Getbot      = require '../lib/getbot'
progressbar = require 'progress'

exports.run = ->
  
  program
    .version('0.0.7')
    .usage('[options] <URL>')
    .option('-d, --destination [path]', 'the destination for the downloaded file(s)')
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

    options =
      connections : program.connections
      destination : program.destination
      user        : program.user
      pass        : program.pass
      quiet       : program.quiet

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
  getbot.on 'noresume', (statusCode) ->
    log "Resume not supported, using only one connection...", statusCode, '\n'
  .on 'downloadStart', (statusCode) ->
    if !options.quiet
      log "#{getbot.filename} (#{makeReadable getbot.fileSize})", statusCode, '\n'
      @readableSize = makeReadable(getbot.fileSize)
      bar = new progressbar 'getbot '.green+'    ‹:bar› :percent :size @ :rate',
        complete: "—".green,
        incomplete: ' ',
        width: 20,
        total: parseInt getbot.fileSize, 10
    return
  .on 'data', (data, rate) ->
    if !options.quiet
      rate = "#{makeReadable rate}/s"
      bar.tick(data.length, {'rate': rate, 'size': @readableSize})
  .on 'allPartsComplete', () =>
    if !options.quiet
      log "Download finished.\n",null, '\n'
      process.exit(0)
    if list.length >= 1
      startBot(options, list)
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
