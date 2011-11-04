fs       = require 'fs'
path     = require 'path'
showdown = require('./../node_modules/showdown/src/showdown').Showdown
{spawn, exec} = require 'child_process'

module.exports = 
  generate_documentation: (source, callback) ->
    fs.readFile source, "utf-8", (error, code) ->
      throw error if error
      sections = parse source, code
      highlight source, sections, ->
        generate_html source, sections
        callback?()


  parse: (source, code) ->
    lines    = code.split '\n'
    sections = []
    language = get_language source
    has_code = docs_text = code_text = ''

    save = (docs, code) ->
      sections.push docs_text: docs, code_text: code

    for line in lines
      if line.match(language.comment_matcher) and not line.match(language.comment_filter)
        if has_code
          save docs_text, code_text
          has_code = docs_text = code_text = ''
        docs_text += line.replace(language.comment_matcher, '') + '\n'
      else
        has_code = yes
        code_text += line + '\n'
    save docs_text, code_text
    sections

  highlight: (source, sections, callback) ->
    language = get_language source
    pygments = spawn 'pygmentize', ['-l', language.name, '-f', 'html', '-O', 'encoding=utf-8,tabsize=2']
    output   = ''

    pygments.stderr.addListener 'data',  (error)  ->
      console.error error.toString() if error
  
    pygments.stdin.addListener 'error',  (error)  ->
      console.error "Could not use Pygments to highlight the source."
      process.exit 1
  
    pygments.stdout.addListener 'data', (result) ->
      output += result if result
  
    pygments.addListener 'exit', ->
      output = output.replace(highlight_start, '').replace(highlight_end, '')
      fragments = output.split language.divider_html
      for section, i in sections
        section.code_html = highlight_start + fragments[i] + highlight_end
        section.docs_html = showdown.makeHtml section.docs_text
      callback()
  
    if pygments.stdin.writable
      pygments.stdin.write((section.code_text for section in sections).join(language.divider_text))
      pygments.stdin.end()

  generate_html: (source, sections) ->
    title = path.basename source
    dest  = destination source
    html  = docco_template {
      title: title, sections: sections, sources: sources, path: path, destination: destination
    }
    console.log "docco: #{source} -> #{dest}"
    fs.writeFile dest, html

  # #### Helpers & Setup
  # 
  # # Require our external dependencies, including **Showdown.js**
  # # (the JavaScript implementation of Markdown).
  # fs       = require 'fs'
  # path     = require 'path'
  # showdown = require('./../vendor/showdown').Showdown
  # {spawn, exec} = require 'child_process'
  # 
  # # A list of the languages that Docco supports, mapping the file extension to
  # # the name of the Pygments lexer and the symbol that indicates a comment. To
  # # add another language to Docco's repertoire, add it here.
  # languages:
  #   '.coffee':
  #     name: 'coffee-script', symbol: '#'
  #   '.js':
  #     name: 'javascript', symbol: '//'
  #   '.rb':
  #     name: 'ruby', symbol: '#'
  #   '.py':
  #     name: 'python', symbol: '#'
  # 
  # # Build out the appropriate matchers and delimiters for each language.
  # for ext, l of languages
  # 
  #   # Does the line begin with a comment?
  #   l.comment_matcher = new RegExp('^\\s*' + l.symbol + '\\s?')
  # 
  #   # Ignore [hashbangs](http://en.wikipedia.org/wiki/Shebang_(Unix))
  #   # and interpolations...
  #   l.comment_filter = new RegExp('(^#![/]|^\\s*#\\{)')
  # 
  #   # The dividing token we feed into Pygments, to delimit the boundaries between
  #   # sections.
  #   l.divider_text = '\n' + l.symbol + 'DIVIDER\n'
  # 
  #   # The mirror of `divider_text` that we expect Pygments to return. We can split
  #   # on this to recover the original sections.
  #   # Note: the class is "c" for Python and "c1" for the other languages
  #   l.divider_html = new RegExp('\\n*<span class="c1?">' + l.symbol + 'DIVIDER<\\/span>\\n*')

  # Get the current language we're documenting, based on the extension.
  get_language: (source) -> languages[path.extname(source)]

  # Compute the destination HTML path for an input source file path. If the source
  # is `lib/example.coffee`, the HTML will be at `docs/example.html`
  destination: (filepath) ->
    'docs/' + path.basename(filepath, path.extname(filepath)) + '.html'

  # Ensure that the destination directory exists.
  ensure_directory: (dir, callback) ->
    exec "mkdir -p #{dir}", -> callback()

  # Micro-templating, originally by John Resig, borrowed by way of
  # [Underscore.js](http://documentcloud.github.com/underscore/).
  template: (str) ->
    new Function 'obj',
      'var p=[],print=function(){p.push.apply(p,arguments);};' +
      'with(obj){p.push(\'' +
      str.replace(/[\r\t\n]/g, " ")
         .replace(/'(?=[^<]*%>)/g,"\t")
         .split("'").join("\\'")
         .split("\t").join("'")
         .replace(/<%=(.+?)%>/g, "',$1,'")
         .split('<%').join("');")
         .split('%>').join("p.push('") +
         "');}return p.join('');"

  # # Create the template that we will use to generate the Docco HTML page.
  #   docco_template  = template fs.readFileSync(__dirname + '/../resources/docco.jst').toString()
  # 
  #   # The CSS styles we'd like to apply to the documentation.
  #   docco_styles    = fs.readFileSync(__dirname + '/../resources/docco.css').toString()
  # 
  #   # The start of each Pygments highlight block.
  #   highlight_start = '<div class="highlight"><pre>'
  # 
  #   # The end of each Pygments highlight block.
  #   highlight_end   = '</pre></div>'
  # 
  #   # Run the script.
  #   # For each source file passed in as an argument, generate the documentation.
  #   sources = process.ARGV.sort()
  #   if sources.length
  #     ensure_directory 'docs', ->
  #       fs.writeFile 'docs/docco.css', docco_styles
  #       files = sources.slice(0)
  #       next_file = -> generate_documentation files.shift(), next_file if files.length
  #       next_file()
  