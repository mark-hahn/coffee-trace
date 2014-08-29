
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
    # console.log 'toggle', {@pixelTop, rowIdx, @lineBufPos, line} 
    
    if (parts = /(\([^\)]*\))?\s*(-|=)>/.exec line)
      @addTraceFunc()
      # console.log parts
      funcOfs  = /(-|=)>/.exec(line).index
      compCode = @compressedText line, compCodeLen, funcOfs+2
      defOfs = @lineBufPos + parts.index
      @text = @text[...defOfs] + ' cT("' +
              compCode + '~' + (rowIdx+1) + 'fcT") ' +
              @text[defOfs...]
      @done()
      return
      
    console.log 'coffee-trace: no position found for trace call'
    
  compressedText: (text, len, pos) ->
    console.log @done
    compText = (if pos then text[...pos].replace(/[\s'"~]/g, '')[-len...]
    else text.replace(/[\s'"~]/g, '')[...len])
    while compText.length < len then compText += ' '
    compText
  
  addTraceFunc: ->
    if not /function\scT\(/.test @text
      @text += @traceFuncJS
  
  removeTraceFunc: ->
    if (parts = /\s*\`[^`]*automatically\sinserted\scoffee-trace[^\`]*\`\s*/g.exec @text)
      idx  = parts.index
      len  = parts[0].length
      @text = @text[...idx] + '\n' + @text[idx+len...]
      
  done: -> 
    @buffer.setText @text
    process.nextTick => 
      @editorView.scrollTop @pixelTop
      @editor.setCursorScreenPosition @cursScrPos
  
  deactivate: ->

module.exports = new CoffeeTrace


`
/*
  automatically inserted coffee-trace function
 */
function cT(info) {//;
var file, fileParts, infoParts, line, lineArr,
  __slice = [].slice;

fileParts = /(\\|\/)([^\\/]*)\.[^\.]*$/.exec(__filename);

file = (fileParts ? fileParts[2] : '');

infoParts = info.split('~');

line = ':' + infoParts[1].slice(0, -3);

file = file.slice(0, 15 - line.length) + line;

while (file.length < 15) {
  file += ' ';
}

lineArr = [file, infoParts[0]];

return function(funcIn) {
  return function() {
    var args, date, s100, secs;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    date = new Date();
    secs = date.getSeconds();
    secs = '' + (secs < 10 ? '0' + secs : secs);
    s100 = Math.floor(date.getMilliseconds() / 10);
    s100 = '' + (s100 < 10 ? '0' + s100 : s100);
    console.log.apply(console, [secs + '.' + s100].concat(__slice.call(lineArr), [args]));
    return funcIn.call.apply(funcIn, [this].concat(__slice.call(args)));
  };
};

};
`
