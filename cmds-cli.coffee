root=exports?this
window.onload=->
  editor = CodeMirror.fromTextArea document.getElementById("code"),{
    mode: "html",
    lineNumbers: true,
    tabMode: "indent"
  }
  url=window.location.protocol+'//'+window.location.hostname+'/cmds'
  root.s = s = io.connect url
  try2=->
    if typeof s!='undefined' and s.socket.connected!=true
      root.s = s = io.connect 'ws://'+window.location.hostname+'/cmds'
  setTimeout(try2(),5000)
  page=window.location.pathname
  if page=="/"
    editor.on "change", ()->
      s.emit 'update',{code:editor.getValue()}
  else if page=="/view"
    s.on 'update', (data)->
      $('body').html = data.code