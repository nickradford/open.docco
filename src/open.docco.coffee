### Open.Docco

Require certain libraries
###

fs       = require 'fs'
path     = require 'path'
global._ = require 'underscore'
_.mixin require 'underscore.string'

### Exports

Exports a class which handles generating html documentation.

Documentation is written in a literary-programming style, where
comments preceding a block of code directly relate to the code
which follows.
###
module.exports = class OpenDocco 
  constructor: (options) -> 
    @output    = options.output
    @maintain  = options.maintain
    @recursive = options.recursive
    @args      = options.args
    
  build: -> 
    filePaths = []
    for filePath in @args
      filePath = fs.realpathSync filePath
      console.log 'filePath', filePath
      if fs.statSync(filePath).isDirectory()
        if @recursive
          readDirRecursive filePath, (fileArr) -> 
            files = fileArr
        else
          files = fs.readDirSync filePath
        filePaths.concat _(files).endsWith 'coffee'
    
    console.log 'filePaths', filePaths
        
      
      
  
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
    
readDirRecursive = (start, callback) -> 
  fs.stat start, (err, stat) -> 
    return callback? err if err
    
    console.log 'start', start
  
    found =
      dirs: []
      files: []
    total = 0
    processed = 0
  
    isDir = (abspath) -> 
      fs.stat abspath, (err, stat) -> 
        if stat.isDirectory()
          found.dirs.push abspath
          readDirRecursive abspath, (err, data) -> 
            found.dirs = found.dirs.concat data.dirs
            found.files = found.files.concat data.files
            processed += 1
            if processed is total
              console.log 'found', found
              callback? null, found
        else
          found.files.push abspath
          processed += 1
          if processed is total
            console.log 'found', found
            callback? null, found
    if stat.isDirectory()
      fs.readdir start, (err, files) -> 
        total = files.length
        isDir path.join(start, file) for file in files
    else
      return callback? new Error "Path: #{start} is not a directory"