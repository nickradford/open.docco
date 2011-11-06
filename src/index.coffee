OpenDocco = require(lib + 'open.docco')

output    = if program.output? then program.output else 'docs'
recursive = if program.recursive? then program.recursive else false
maintain  = if program.maintain? then program.maintain else false

# console.log Docco

docco = new OpenDocco output:output, recursive:recursive, maintain:maintain, args:program.args

docco.build()

# console.log 'program.args', program.args

# console.log docco.generateHtml arg for arg in program.args