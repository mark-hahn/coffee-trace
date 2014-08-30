###
  automatically inserted coffee-trace function
###
`function cT(info) {//`

fileParts = /(\\|\/)([^\\/]*)\.[^\.]*$/.exec __filename
file = (if fileParts then fileParts[2] else '')

infoParts = info.split '~'
snip = infoParts[0]
line = ':' + infoParts[1][...-3]
type = infoParts[1][-3..-3]
file = file[...(15 - line.length)] + line
while file.length < 15 then file += ' '

return (arg) ->
  date = new Date()
  secs = date.getSeconds()
  secs = '' + (if secs < 10 then '0' + secs else secs)
  s100 = Math.floor date.getMilliseconds() / 10
  s100 = '' + (if s100 < 10 then '0' + s100 else s100)
  pfx = secs + '.' + s100 + ' ' + file + ' (' + snip + ')'
  if type is 'f' 
    (args...) -> 
      console.log pfx, args
      arg.apply @, args
  else 
    console.log pfx, [arg]
    arg
`}`
