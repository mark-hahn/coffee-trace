
# lib/coffee-trace.coffee

compCodeLen = 20

fs     = require 'fs'
path   = require 'path'
coffee = require 'coffee-script'

class CoffeeTrace

  activate: ->
    console.log 'coffee-trace activated'
    traceFuncCS  = fs.readFileSync(__dirname + '/trace-func.coffee').toString()
    @traceFuncJS = '\n\n`' + coffee.compile(traceFuncCS, {bare:yes}) + '`\n'
    atom.workspaceView.command "coffee-trace:toggle", => @toggle()

  toggle: ->
    if not (@editorView = atom.workspaceView.getActiveView())       or
	     not (@editor = @editorView.getEditor?())                     or
  	   not (selRange = @editor.getSelectedBufferRange())            or 
       not selRange.isSingleLine()                                  or
       path.extname(@editor.getUri()).toLowerCase() isnt '.coffee'
      return
    
    cursBufPos  = selRange.end
    rowIdx      = cursBufPos.row
    topLine     = @editorView.getFirstVisibleScreenRow()
    @pixelTop   = @editorView.pixelPositionForScreenPosition([topLine, 0]).top
    @cursScrPos = @editor.getCursorScreenPosition()
    @buffer     = @editor.getBuffer()
    @text       = @buffer.getText()
    line        = @buffer.lineForRow rowIdx
    @lineBufPos = @buffer.characterIndexForPosition [rowIdx, 0]
    lineOfs     = selRange.start.column

    if @chkRemove(@lineBufPos, cursBufPos.column, line) then return
    
    ofs  = null
    test = line.replace /(-|=)>/g, '~!'
    
    switch
      when test[lineOfs-3..lineOfs-1] is  '~! ' then ofs = lineOfs - 3
      when test[lineOfs-2..lineOfs-1] is  '~!'  then ofs = lineOfs - 2
      when test[lineOfs-1..lineOfs+0] is  '~!'  then ofs = lineOfs - 1
      when test[lineOfs+0..lineOfs+1] is  '~!'  then ofs = lineOfs + 0
      when test[lineOfs+0..lineOfs+2] is ' ~!'  then ofs = lineOfs + 1
      
    if ofs?
      @addTraceFunc()
      compCode  = @compressedText line, compCodeLen, ofs+2
      bufInsOfs = @lineBufPos + ofs
      if (parts = /\([^\(]*\)\s*$/.exec line[...ofs]) then bufInsOfs -= parts[0].length
      @text = @text[...bufInsOfs] + ' cT("' +
              compCode + '~' + (rowIdx+1) + 'fcT") ' +
              @text[bufInsOfs...]
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
      @text  = @text[...bufOfs] + ' cT("' +
              compCode + '~' + (rowIdx+1) + 'acT") ' +
              @text[bufOfs...]
      @done()
      return
      
    console.log 'coffee-trace: no cursor match found for trace'
    
  compressedText: (text, len, pos) ->
    compText = text[...pos].replace(/[\s'"~\(\)]/g, '')[-len...]
    while compText.length < len then compText += ' '
    compText
    
  chkRemove: (lineBufPos, cursOfs, line) ->
    if (parts = /\s*cT\("[^\)]*cT"\)/.exec line)
      bufOfsStart =   @lineBufPos + parts.index
      bufOfsEnd   = bufOfsStart + parts[0].length
      if not (bufOfsStart <= (lineBufPos + cursOfs) < bufOfsEnd) then return
      @text =  @text[...bufOfsStart] + @text[bufOfsEnd...]
      if not /\s*cT\("[^\)]*cT"\)/.test @text
        @removeTraceFunc()
      @done()
      return yes
    
    if (parts = /\s*\`[^`]*automatically\sinserted\scoffee-trace[^\`]*\`\s*/.exec @text)
      bufOfsStart = parts.index
      bufOfsEnd   = bufOfsStart + parts[0].length
      if not (bufOfsStart <= (lineBufPos + cursOfs) < bufOfsEnd) then return
      @text = @text[...bufOfsStart] + @text[bufOfsEnd...] + '\n'
      if (matches = @text.match /\s*cT\("[^\)]*cT"\)/g)
    	   for match in matches then @text = @text.replace match, ''
      @done()
      return yes
  
  addTraceFunc: -> 
    if not /function\scT\(/.test @text
      @text += @traceFuncJS
  
  removeTraceFunc: ->
    if (parts = /\s*\`[^`]*automatically\sinserted\scoffee-trace[^\`]*\`\s*/.exec @text)
      idx   = parts.index
      len   =  parts[0].length
      @text = @text[...idx] + '\n' + @text[idx+len...] + '\n'
      
  done: -> 
    @buffer.setText @text
    process.nextTick => 
      @editorView.scrollTop @pixelTop
      @editor.setCursorScreenPosition @cursScrPos
  
  deactivate: ->

module.exports = new CoffeeTrace
