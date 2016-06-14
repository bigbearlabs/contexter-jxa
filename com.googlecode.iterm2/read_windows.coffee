# ---
# doit: 
#   cmd: | 
#     coffee -cp #{file} | osascript -l JavaScript -
#   args:
#       
# test:
# ---

### js source

ObjC.import('Foundation')


var app = Application('com.googlecode.iTerm2');

var windows = app.windows()
var window_hs = windows.map(function(w) {
  return {
    elements: [
      {
        name: w.name(),
        window_id: w.id(),
    //    anchor: getAnchor(w)
      }
    ]
  }
})

try {
  window_hs[0]['anchor'] = {
    name: windows[0].name(),
    window_id: windows[0].id(),
    url: getAnchor(windows[0])
  }
}
catch (e) {
  window_hs[0]['anchor'] = {
    name: windows[0].name(),
    err: e.toString()
  }
}

JSON.stringify({
  windows: window_hs
})



function runCmd(cmd) {
  NSUTF8StringEncoding = 4

  var pipe = $.NSPipe.pipe
  var file = pipe.fileHandleForReading  // NSFileHandle
  var task = $.NSTask.alloc.init

  task.launchPath = '/bin/bash'
  task.arguments = ["-c", cmd]
  // console.log(cmd)
  task.standardOutput = pipe  // if not specified, literally writes to file handles 1 and 2

  task.launch // Run the command `ps aux`

  var data = file.readDataToEndOfFile  // NSData
  file.closeFile

  // Call -[[NSString alloc] initWithData:encoding:]
  data = $.NSString.alloc.initWithDataEncoding(data, NSUTF8StringEncoding)

  return ObjC.unwrap(data) // Note we have to unwrap the NSString instance
}



// pwd of terminal tab.
function getAnchor(window) {
  var app = Application.currentApplication()
  app.includeStandardAdditions = true

  var ttyProducer = window.currentSession()

  var ttyName = ttyProducer.tty()
  // console.log(ttyName)
  if (ttyName) {
    var cmd = "/usr/sbin/lsof -a -p `/usr/sbin/lsof -a -u $USER -d 0 -n | tail -n +2 | awk '{if($NF==\"" + ttyName + "\"){print $2}}' | head -1` -d cwd -n | tail -n +2 | awk '{print $NF}'"
    // FIXME this command is very brittle.

    return runCmd(cmd).trim()
  }
  else {
    throw "e1: no ttyName for window"
  }
}

###

ObjC.import('Foundation')

app = Application('com.googlecode.iTerm2')



class ItermWindowAccessor extends WindowAccessor

  getAnchor = (element) ->
    app = Application.currentApplication()
    app.includeStandardAdditions = true

    ttyProducer = element
    ttyName = ttyProducer.tty()
    # console.log(ttyName)
    if ttyName
      cmd = '/usr/sbin/lsof -a -p `/usr/sbin/lsof -a -u $USER -d 0 -n | tail -n +2 | awk \'{if($NF=="' + ttyName + '"){print $2}}\' | head -1` -d cwd -n | tail -n +2 | awk \'{print $NF}\''
      # FIXME this command is very brittle.
      cmdOut = runCmd(cmd).trim()
      element.url = cmdOut
      return element
    else
      throw 'e1: no ttyName for window'
    return


  getElements: (window) ->
    returnFirstSuccessful [
      ->
        [ window.currentSession() ]
      ->
        [ window.target() ]
      ->
        window.tabs()
      ->
        [ window.document() ]
    ]



runCmd = (cmd) ->
  NSUTF8StringEncoding = 4
  pipe = $.NSPipe.pipe
  file = pipe.fileHandleForReading
  # NSFileHandle
  task = $.NSTask.alloc.init
  task.launchPath = '/bin/bash'
  task.arguments = [
    '-c'
    cmd
  ]
  # console.log(cmd)
  task.standardOutput = pipe
  # if not specified, literally writes to file handles 1 and 2
  task.launch
  # Run the command `ps aux`
  data = file.readDataToEndOfFile
  # NSData
  file.closeFile
  # Call -[[NSString alloc] initWithData:encoding:]
  data = $.NSString.alloc.initWithDataEncoding(data, NSUTF8StringEncoding)
  ObjC.unwrap data
  # Note we have to unwrap the NSString instance

