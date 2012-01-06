colors    = require 'colors'
program = require 'commander'

exports.run = ->
  program
    .version('0.0.1')
    .usage('[options] <URL>')
    .option('-d, --destination [path]', 'the destination for the downloaded file','.')
    .option('-c, --connections [number]', 'max connections to try', parseInt, 3)
    .parse(process.argv)
  
  
    if program.args?.length is 1
      console.log "#{program.args[0]}"
    else
      console.log program.helpInformation()

init = (path) ->
  try
    growl = require 'growl'
    growl "gobot: downloading #{path} max-connections: #{program.connections}"
  catch error
    console.log "gobot: #{path} max-connections: #{program.connections}"
      
