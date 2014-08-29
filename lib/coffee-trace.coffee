
# lib/coffee-trace.coffee

{Subscriber} = require 'emissary'

class CoffeeTrace
  Subscriber.includeInto @

  activate: ->
    console.log 'coffee-trace activated'
    atom.workspaceView.command "'coffee-trace:toggle", => @toggle()
    
  toggle: ->
    

  deactivate: ->
    @unsubscribe()


module.exports = new CoffeeTrace
