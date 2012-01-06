{print}       = require 'util'
{spawn, exec} = require 'child_process'

task 'watch', 'watch project and build on changes', ->
  options = ['-c', '-w', '-o', 'lib', 'src']
  coffee = spawn 'coffee', options
  coffee.stdout.on 'data', (data) -> print data.toString()
  coffee.stderr.on 'data', (data) -> print data.toString()
  coffee.on 'exit', (status) -> callback?() if status is 0

task 'build', 'Build project', ->
  options = ['-c', '-o', 'lib', 'src']
  coffee = spawn 'coffee', options
  coffee.stdout.on 'data', (data) -> print data.toString()
  coffee.stderr.on 'data', (data) -> print data.toString()
  coffee.on 'exit', (status) -> callback?() if status is 0