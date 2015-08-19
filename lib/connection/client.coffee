{Emitter} = require 'atom'

module.exports =

  emitter: new Emitter()

  onConnected: (cb) -> @emitter.on('connected', cb)
  onDisconnected: (cb) -> @emitter.on('disconnected', cb)

  handlers: {}
  callbacks: {}
  id: 0

  input: ([type, data]) ->
    if @handlers.hasOwnProperty type
      if data.callback?
        @handlers[type] data, (result) =>
          @msg data.callback, result
      else
        @handlers[type] data
    else if @callbacks.hasOwnProperty type
      @callbacks[type] data
      delete @callbacks[type]
      @loading.done()
    else
      console.log "julia-client: unrecognised message #{type}"
      console.log data

  isConnected: -> false

  booting: ->
    @isBooting = true
    @loading.working()

  notBooting: ->
    if @isBooting
      @isBooting = false
      @loading.done()

  connectedError: ->
    if @isConnected()
      atom.notifications.addError "Can't create a new client.",
        detail: "There is already a Julia client running."
      true
    else
      false

  notConnectedError: ->
    if not @isConnected()
      atom.notifications.addError "Can't do that without a Julia client.",
        detail: "Try connecting a client by evaluating something."
      true
    else
      false

  requireClient: (f) -> @notConnectedError() or f()
  requireNoClient: (f) -> @connectedError() or f()

  msg: (type, data, f) ->
    return unless @sock?
    if f?
      data.callback = @id = @id+1
      @callbacks[@id] = f
      @loading.working()
    @sock.write(JSON.stringify([type, data]))

  handle: (type, f) ->
    @handlers[type] = f

  # TODO: this behaves weirdly because f is evaluated late
  # Should instead evalute f immediately and make sure messages are queued.
  withClient: (f) ->
    return f() if @sock?
    if not @isBooting
      atom.commands.dispatch atom.views.getView(atom.workspace),
                             'julia-client:start-julia'
      listener = @onConnected =>
        listener.dispose()
        f()
      return
    # TODO: Queue commands if booting?