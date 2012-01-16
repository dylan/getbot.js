colors    = require 'colors'
program = require 'commander'
cluster = require 'cluster'
http = require 'http'
url = require 'url'
util = require 'util'
Getbot = require '../lib/getbot'
progressbar = require 'progress'

exports.run = ->
  
  program
    .version('0.0.2')
    .usage('[options] <URL>')
    .option('-d, --destination [path]', 'the destination for the downloaded file','.')
    .option('-c, --connections [number]', 'max connections to try', parseInt, 3)
    .option('-u, --user [string]', 'username used for basic auth')
    .option('-p, --pass [string]', 'password used for basic auth')
    .parse(process.argv)
  
    if program.args?.length is 1
      getbot = new Getbot program.args[0], program.user, program.pass
      bar = null

      getbot.on 'downloadStart', () ->
        bar = new progressbar 'Downloading: [:bar] :percent :eta | :rate',
          complete: '=',
          incomplete: ' ',
          width: 20,
          total: parseInt getbot.size, 10

      getbot.on 'data', (data, rate) ->
        rate = "#{makeReadable rate}/s"
        bar.tick(data.length, {'rate': rate})
      return
    else
      return console.log program.helpInformation()

makeReadable = (bytes) ->
  units= ['Bytes','KB','MB','GB','TB']
  unit = 0
  while bytes >= 1024
    unit++
    bytes = bytes/1024
    precision = if unit > 2 then 2 else 1
  return "#{bytes.toFixed(precision)} #{units[unit]}"
