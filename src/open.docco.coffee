### Open.Docco

Require certain libraries
###

fs        = require 'fs'
path      = require 'path'
global._  = require 'underscore'
core      = require 'open.core'
coreFs    = core.util.fs
_.mixin require 'underscore.string'

### Exports

Exports a class which handles generating html documentation.

Documentation is written in a literary-programming style, where
comments preceding a block of code directly relate to the code
which follows.
###
module.exports = class OpenDocco 
  constructor: (options) -> 
    @output    = options.output || "./docs/"
    @maintain  = options.maintain
    @recursive = options.recursive
    @args      = options.args
    
  build: -> 
    filePaths = []
    path = @args[0]
    if fs.statSync(path).isDirectory()
      paths = coreFs.readDirSync @args[0], deep:@recursive, hidden:false
    else
      paths = [path]
    paths = _(paths).reject (p) -> _(p).include('node_modules') or fs.statSync(p).isDirectory()
    filePaths = _(paths).filter (p) -> _(p).endsWith '.coffee' 
    
    files = []
    
    _(filePaths).each (path) => 
      parsedSource = @getSource path
      files.push
        path: path
        parsedSource: parsedSource
    
    _(files).each (obj) ->
      console.log 'obj.path', obj.path
  
  getSource: (filePath) ->
    source = @getFileContents filePath
    sections = @parseSource source
    sections
  
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
    
    # _(sections).each (section) -> console.log 'section', section
    
    sections
  
  ### getFileContents
  - filePath: path to the file which will be parsed.
  ###    
  getFileContents: (filePath) -> 
    filePath = fs.realpathSync(filePath)
    fs.readFileSync filePath, 'utf-8'
    