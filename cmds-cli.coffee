root = exports ? this
window.onload=->
  
  try
    s=io.connect 'http://'+window.location.hostname+'/cmds' #;root.s=s
  catch error
    console.log error
  
  try2=->
    if typeof s!='undefined' and s.socket.connected!=true
      try
        root.s = s = io.connect 'ws://'+window.location.hostname+'/cmds'
      catch error
        console.log error
  
  setTimeout(try2(),1000)
  
  page=window.location.pathname
  
  if page=="/"
    editor = CodeMirror.fromTextArea document.getElementById("code"),
      {mode:"htmlmixed",
      vimMode:true,
      lineNumbers: true,
      tabMode: "indent",
      matchBrackets:true,
      extraKeys:{
        "F11":(cm)->
          if cm.getOption("fullScreen")
            cm.setOption("fullScreen", false)
          else
            cm.setOption("fullScreen", true)
      },
      theme:'monokai'}
    editor.focus()
    s.emit 'index', {}, (data)->
      console.log data
      root.vid = viewID = data
      $('#viewID')[0].innerHTML = data
    editor.on "change", ()->
      s.emit 'update',{code:editor.getValue()},(data)->data=null
  
  else if page=="/view"
    $('#view').on('submit',(e)->
      e.preventDefault()
      s.emit 'view', {sid:$('#vid').val()}, (data)->
        $('body').html 'connected.'
        console.log data
      )
    s.on 'update', (data)->
      $('body').html(data.code)
      console.log data.code