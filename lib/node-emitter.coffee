winston = require "winston"
utils = require './utils'

module.exports = (io, debug = false) ->

  winston.error('must pass in socket.io') if not io

  # Set logLevel based on debug
  logLevel = if debug then 'info' else 'warn'

  # Add the console transport to winston
  winston.remove winston.transports.Console
  winston.add winston.transports.Console,
    colorize: true
    timstamp: true
    level: logLevel

  winston.info 'emitter middleware initialized'

  (req, res, next) ->

    if req.method is "POST"
      # Check the input for errors
      req.namespace = req.path.substr(1,req.path.length)

#      winston.info req.namespace
#      winston.info req.body
#      winston.info req.body.value

      # Services that can't POST JSONs natively can POST a JSON in the "value" field
      if req.body.value
        try
          toAdd = JSON.parse req.body.value
          for key, value of toAdd
            req.body[key] = value
        catch error
          winston.error "could not parse JSON :("
          winston.error error


      if not req.namespace
        res.json 400,
          error: 'Must POST to a /namespace'
      else if not req.body.event
        res.json 400,
          error: 'Missing parameter: event'
      else if not req.body.data
        res.json 400,
          error: 'Missing parameter: data'
      else
        # Parse the data
        split = utils.splitter req.namespace
        # Emit to the proper clients
        utils.emitter split.emit_to, split.socketspace, req.body.event, req.body.data, io
        # Call next handler
        next()
    else if req.method is "OPTIONS"
      res.send 200
    else
      winston.info "Method was #{req.method} -- ignoring"
      next()
