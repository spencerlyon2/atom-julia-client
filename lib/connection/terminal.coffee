child_process = require 'child_process'
comm = require './comm'

module.exports =

  escpath: (p) -> '"' + p + '"'
  escape: (sh) -> sh.replace(/"/g, '\\"')

  exec: (sh) ->
    child_process.exec sh, (err, stdout, stderr) ->
      if err?
        console.log err

  term: (sh) ->
    switch process.platform
      when "darwin"
        @exec "osascript -e 'tell application \"Terminal\" to activate'"
        @exec "osascript -e 'tell application \"Terminal\" to do script \"#{@escape(sh)}\"'"
      else
        @exec "#{@terminal()} \"#{@escape(sh)}\""

  terminal: -> atom.config.get("julia-client.terminal")

  jlpath: () -> atom.config.get("julia-client.juliaPath")
  jlargs: () -> atom.config.get("julia-client.juliaArguments")

  repl: -> @term "#{@escpath @jlpath()} #{@jlargs()}"

  client: (port) ->
    comm.booting()
    @term "#{@escpath @jlpath()} #{@jlargs()} -P \"import Atom; Atom.connect(#{port})\""
