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

sessions={}

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

io.of('/cmds')
.on 'connection', (socket)->
  console.log socket.id
  
  socket.on 'index', (data,fn)-> #index
    socket.set 'session', uuid.v4()
    socket.get 'session', (e,d)->
      socket.join(d)
      fn(d)
      console.log 'creator connected::',d
  
  socket.on 'view', (data,fn)-> #view
    socket.set 'session', data['sid']
    socket.join(data['sid'])
    fn('ok')
    console.log 'listener connected::',data['sid']
  
  socket.on 'update', (data,fn)-> #index
    try
      socket.get 'session',(e,d)->
        socket.broadcast.to(d).emit('update',data)
      #console.log data
    fn('ok')
.on 'disconnect', (socket)->
  socket.get 'session', (e,d)->
    socket.leave(d)

server.listen(process.argv[2])