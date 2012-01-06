{exec} = require 'child_process'

task 'build', 'Build project from src/*.coffee to lib/*.js', ->
  exec 'coffee --compile --output lib/ src/', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
    
task 'watch', 'watch project and build on change', ->
  console.log "Waiting for changes..."
  exec 'coffee -c -w -o lib/ src/', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr