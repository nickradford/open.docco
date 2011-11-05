fs = require 'fs'
global._ = require 'underscore'
_.mixin require 'underscore.string'

### OpenDocco
- Bullet 1
- Bullet 2

**Bold**

_Underlined_

(google)[http://google.com]
###
module.exports = class OpenDocco 
  @output    = null
  @maintain  = null
  @recursive = null
  
  constructor: (options) -> 
    @output = if options.output? then options.output else 'docs'
  
  generateHtml: (filePath) ->
    source = @getFileContents filePath
    sections = @parseSource source
  
  ### parseSource 
  
  ###    
  parseSource: (source) ->
    inComment = false
    commentString = ""
    codeString = ""
    sections = []
    for line in source.split '\n'
      line = _(line).trim()
      if _(line).startsWith('###') or inComment
        # console.log 'line', line
        if not inComment and _(line).startsWith('###')
          # console.log 'not inComment line', line
          # store current commentString and codeString
          unless commentString is "" and codeString is ""
            sections.push
              comment: commentString
              code: codeString
            commentString = ""
            codeString = ""
          inComment = true
        else if _(line).startsWith('###')
          inComment = false
          commentString += line + '\n'
        
        if inComment
          commentString += line + '\n'
      else
          codeString += line + '\n'
    sections.push
      comment: commentString
      code: codeString
    commentString = ""
    codeString = ""
    
    return sections
  
  ### getFileContents
  - filePath: path to the file which will be parsed.
  ###    
  getFileContents: (filePath) -> 
    filePath = fs.realpathSync(filePath)
    fs.readFileSync filePath, 'utf-8'