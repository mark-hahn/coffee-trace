
# lib/coffee-trace.coffee

compCodeLen = 20

fs     = require 'fs'
coffee = require 'coffee-script'

class CoffeeTrace

  activate: ->
    console.log 'coffee-trace activated'
    traceFuncCS  = fs.readFileSync(__dirname + '/trace-func.coffee').toString()
    @traceFuncJS = '\n\n`' + coffee.compile(traceFuncCS, {bare:yes}) + '`\n'
    atom.workspaceView.command "coffee-trace:toggle", => @toggle()

  toggle: ->
    @editorView = atom.workspaceView.getActiveView()
    @editor     = @editorView.getEditor()
    @cursScrPos = @editor.getCursorScreenPosition()
    selRange    = @editor.getSelectedBufferRange()
    if not selRange.isSingleLine() then return
    
    topLine     = @editorView.getFirstVisibleScreenRow()
    @pixelTop   = @editorView.pixelPositionForScreenPosition([topLine, 0]).top
    @buffer     = @editor.getBuffer()
    @text       = @buffer.getText()
    rowIdx      = selRange.end.row
    line        = @buffer.lineForRow rowIdx
    @lineBufPos = @buffer.characterIndexForPosition [rowIdx, 0]
    console.log 'toggle', {@pixelTop, rowIdx, @lineBufPos, line} 
    
    if (parts = /(\([^\)]*\))?\s*(-|=)>/.exec line)
      @addTraceFunc()
      console.log parts
      funcOfs  = /(-|=)>/.exec(line).index
      compCode = @compressedText line, funcOfs+2, compCodeLen
      defOfs = @lineBufPos + parts.index
      @text = @text[...defOfs] + ' cT("' +
              compCode + '~' + (rowIdx+1) + 'fcT") ' +
              @text[defOfs...]
      @done()
      return
      
    console.log 'coffee-trace: no position found for trace call'
    
  compressedText: (text, pos, len) ->
    compText = text[...pos].replace /[\s'"~]/g, ''
    if (txtLen = compText.length) > len
      halfLen = len/2 - 1
      return compText[...halfLen] + '..' + compText[txtLen-halfLen...]
    while compText.length < len then compText = compText + ' '
    text
  
  addTraceFunc: ->
    if not /function\scT\(/.test @text
      @text += @traceFuncJS
  
  removeTraceFunc: ->
    if (parts = /\s*\`[^`]*automatically\sinserted\scoffee-trace[^\`]*\`\s*/g.exec @text)
      idx  = parts.index
      len  = parts[0].length
      @text = @text[...idx] + '\n' + @text[idx+len...]
      
  done: -> 
    process.nextTick => 
      @editorView.scrollTop @pixelTop
      @editor.setCursorScreenPosition @cursScrPos
    @buffer.setText @text
  
  deactivate: ->

module.exports = new CoffeeTrace
