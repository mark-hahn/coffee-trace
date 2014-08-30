
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
    lineOfs     = selRange.start.column
    
    ofs = null
    test = line.replace /(-|=)>/g, '~!'
    
    switch
      when test[lineOfs-3..lineOfs-1] is  '~! ' then ofs = lineOfs - 3
      when test[lineOfs-2..lineOfs-1] is  '~!'  then ofs = lineOfs - 2
      when test[lineOfs-1..lineOfs+0] is  '~!'  then ofs = lineOfs - 1
      when test[lineOfs+0..lineOfs+1] is  '~!'  then ofs = lineOfs + 0
      when test[lineOfs+0..lineOfs+2] is ' ~!'  then ofs = lineOfs + 1
      
    if ofs?
      if (parts = /\([^\(]*\)\s*$/.exec line[...ofs]) then ofs -= parts[0].length
      compCode = @compressedText line, compCodeLen, ofs
      bufOfs   = @lineBufPos + ofs
      @text = @text[...bufOfs] + ' cT("' +
              compCode + '~' + (rowIdx+1) + 'fcT") ' +
              @text[bufOfs...]
      @done()
      return
    
    switch
      when line[lineOfs-2..lineOfs-1] is  '= ' then ofs = lineOfs - 1
      when line[lineOfs-1]            is  '='  then ofs = lineOfs + 0
      when line[lineOfs]              is  '='  then ofs = lineOfs + 1
      when line[lineOfs..lineOfs+1]   is ' ='  then ofs = lineOfs + 2
      
    if ofs?
      @addTraceFunc()
      compCode = @compressedText line, compCodeLen, ofs
      bufOfs = @lineBufPos + ofs
      @text = @text[...bufOfs] + ' cT("' +
              compCode + '~' + (rowIdx+1) + 'acT") ' +
              @text[bufOfs...]
      @done()
      return
      
    console.log 'coffee-trace: no position found for trace call'
    
  compressedText: (text, len, pos) ->
    compText = text[...pos].replace(/[\s'"~]/g, '')[-len...]
    while compText.length < len then compText += ' '
    compText
  
  addTraceFunc: -> 
    if not /function\scT\(/.test @text
      @text += @traceFuncJS
  
  removeTraceFunc: ->
    if (parts = /\s*\`[^`]*automatically\sinserted\scoffee-trace[^\`]*\`\s*/g.exec @text)
      idx   = parts.index
      len   = parts[0].length
      @text = @text[...idx] + '\n' + @text[idx+len...]
      
  done: -> 
    @buffer.setText @text
    process.nextTick => 
      @editorView.scrollTop @pixelTop
      @editor.setCursorScreenPosition @cursScrPos
  
  deactivate: ->

module.exports = new CoffeeTrace
