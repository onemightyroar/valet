splitter = (namespace) ->

  # Trim trailing slashes
  while namespace[namespace.length-1] is '/'
    namespace = namespace.substr(0,namespace.length - 1)

  while namespace[0] is '/'
    namespace = namespace.substr(1,namespace.length)

  split = namespace.split '/'

  # Object to store namespace info, to be emitted along with the POSTed data
  socketspace =
    raw: namespace
    last: null
    parsed: {}

  # The namespaces to emit to
  emit_to = []

  # If there are an even number of /items, this is a global POST
  if split.length % 2 > 0

    # Get the last (finest) namespace component
    last = split[split.length - 1]
    socketspace.last = last

    #    winston.info "the namespace is '#{ last }'"
    # Emit on this as a root namespace
    emit_to.push "/#{last}"

  # Emit after every preceding combination of two
  built = ''
  for arg,idx in split
    built += "/#{arg}"
    # If on an odd index, this is the end of a pair - so append the last namespace component
    if idx % 2 > 0 # odd
      if last then emit_to.push("#{built}/#{last}") else emit_to.push(built)
      # Add to the params dictionary
      socketspace.parsed[split[idx-1]] = split[idx]

  {
    emit_to: emit_to
    socketspace: socketspace
  }

emitter = (emit_to, socketspace, event, data, io) ->
  # Attach namespace data to the emitted data
  data.socket_namespace = socketspace
  # Emit to each namespace
  for namespace in emit_to
    console.log "emitting '#{event}' to members of #{namespace}"
    io.of(namespace).emit event,data


module.exports =
  splitter: splitter
  emitter: emitter