express = require 'express.io'
winston = require 'winston'
pjson = require '../package.json'
emitter = require './node-emitter'
utils = require './utils'

# Check for a config file two levels up
try
  config = require '../../../config.json'
  winston.info 'Found user-defined config file'
catch
  winston.info 'Could not find user-defined config file, using valet default config'
  config = require '../config.json'

# Which valet?
winston.info '--------'
winston.info "#{pjson.name} version #{pjson.version}"
winston.info '--------'

# Setup the express app
app = express()
app.http().io()

cors = (req, res, next) ->
  res.header 'Access-Control-Allow-Origin', config.allowedDomains
  res.header 'Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS'
  res.header 'Access-Control-Allow-Headers', 'Content-Type'
  next()

# Use the express body parser (for JSONs)
app.use express.bodyParser()
# Use the emitter library
app.configure ->
  app.use emitter(app.io,true)
  app.use cors

# Add the console transport to winston + file
winston.remove winston.transports.Console
winston.add winston.transports.Console,
  colorize: true
  timstamp: true
#winston.add winston.transports.File,
#  filename: 'winston.log'
#  json: false
#  colorize: true


# Set the port to use, based on the platform list in config.json
found = false
idx = 0
while not found  and config.platforms[idx]
  platform = config.platforms[idx]
  if platform.trigger.equals # key and value specified
    if process.env[platform.trigger.property] is platform.trigger.equals
      deployment = platform
      found = true
  else # key only specified
    if process.env[platform.trigger.property]
      deployment = platform
      found = true
  idx++

if deployment
  winston.info "#{deployment.name} deployment detected."
  port = deployment.port
else
  port = config.default_port
  winston.info "could not detect deployment. using default port: #{port}"



# HTTP ROUTES
# ---

# Respond to get requests to '/' to handle aws health checks
app.get '/', (req, res) ->
  res.send "#{pjson.name} version #{pjson.version}"


# This handler won't be called if there is an error in the socket responder layer.
# If we get here, respond with a 200
app.post '/*', (req, res) ->
  res.send 200



# SOCKET EVENTS
# ---

# Catch incoming socket connections
app.io.on 'connection', (socket) ->
  winston.info 'new socket connected'

# TODO - currently, this only catches events that come in on the root namespace. Need to find a way to emit events on any namespace.
app.io.route 'post', (req) ->
  # Check for valid data
  if req.data.namespace and req.data.event and req.data.data
    # Split into namespaces
    split = utils.splitter req.data.namespace
    # Data to re-emit
    data = req.data.data
    # Add the socket_namespace from the splitter
    data.socket_namespace = split.socketspace
    # Emit to each namespace
    for namespace in split.emit_to
      winston.info "emitting '#{req.data.event}' to members of #{namespace}"
      app.io.of(namespace).emit req.data.event,data
  else
    winston.error "missing params. you sent:"
    winston.error req.data

winston.info "listening on port #{port}"

# Start the app
app.listen port

