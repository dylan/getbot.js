# A Util module to keep the other classes clean.

###*
 * Takes two numbers and returns their quotient and remainder.
 * @param  {Number} x
 * @param  {Number} y
 * @return {[Number,Number]} quotient, remainder
###
exports.divmod = (x, y)->
  [(q = Math.floor(x/y)), (r = if x < y then x else x % y)]


###*
 * Takes a number in bytes and converts them to a readable format.
 * @param  {Number} bytes
 * @return {String} amount in bytes/kb/mb/gb/tb
###
exports.toReadableSize = (bytes)->
  units= ['Bytes','KB','MB','GB','TB']
  unit = 0
  while bytes >= 1024
    unit++
    bytes = bytes/1024
    precision = if unit > 2 then 2 else 1
  return "#{bytes.toFixed(precision)} #{units[unit]}"
