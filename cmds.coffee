_      = require 'lodash'
http   = require 'http'
ex     = require 'express'
app    = ex()
swig   = require 'swig'
server = http.createServer(app)
uuid   = require 'node-uuid'

#app.settings['x-powered-by']=false
app.engine 'html', swig.renderFile
app.set 'view engine', 'html'
app.set 'views', __dirname + '/pages'
app.set 'view cache', false
swig.setDefaults { cache: false }

app.get '/', (req,res)->
  res.render 'index', {}

app.get '/view', (req,res)->
  res.render 'view', {vid:req.query.v}

app.get '/src/*', (req,res)->
  try
    res.sendfile __dirname+'/src/'+req.params[0]
  catch error
    res.send '...'

debug = false
sessions={}

console.log 'debug mode on' if debug

io = require('socket.io').listen(server)

io.configure 'development', ()->
  io.enable 'browser client minification'
  io.enable 'browser client etag'
  io.enable 'browser client gzip'
  io.set 'log level', 1
  io.set 'close timeout', 1260        # 21 minutes
  io.set 'heartbeat timeout', 1260    # 21 minutes
  io.set 'heartbeat interval', 420    #  7 minutes
  io.set 'polling duration', 1260     # 21 minutes
  io.set 'transports', [
    'websocket'
  , 'flashsocket'
  , 'htmlfile'
  , 'xhr-polling'
  , 'jsonp-polling'
  ]

broadcast=(sio,data)->
  console.log 'sio:',sio if debug
  try
    sio.emit('update',data)

sessions={}

io.of('/cmds')
.on 'connection', (socket)->
  console.log socket.id if debug
  
  socket.on 'index', (data,fn)-> #index
    socket.set 'session', uuid.v4()
    socket.get 'session', (e,d)->
      sessions[d]=[socket]
      fn(d)
      console.log 'editer connected::',d if debug
  
  socket.on 'view', (data,fn)-> #view
    socket.set 'session', data.sid
    sessions[data.sid].push(socket)
    fn('ok')
    console.log 'viewer connected::',data.sid if debug
  
  socket.on 'update', (data,fn)-> #index
    console.log 'sessions:',sessions
    try
      socket.get 'session', (e,d)->
        console.log 'data:',data if debug
        broadcast(sio,data) for sio in sessions[d]
    catch e
      console.log 'error',e if debug
    fn('ok')

server.listen(process.argv[2])