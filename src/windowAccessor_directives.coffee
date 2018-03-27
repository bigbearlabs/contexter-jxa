returnFirstSuccessful = require('./lib/returnFirstSuccessful')


# directives for app-specific operations to override those defined in `baseAccessor`.
module.exports = directives =

  "com.apple.dt.Xcode":

    skipSystemEventsProbe: true

    getUrl: (element) =>
      returnFirstSuccessful [
        -> element.file().toString()  # xcode 8
        -> element.fileReference.fullPath()[0]  # xcode 7.*
      ]

    getElementName: (element) =>
      returnFirstSuccessful [
        -> element.name()  # # xcode 8
        -> element.fileReference.name()[0]  # # xcode 7.*
      ]

    getWindows: (application) =>
      application.windows()
        .filter (w) =>
          # since xcode9, we can end up with a bunch of hidden windows that can cause a lot of errors.
          (w.id() || "-1").toString() != "-1"


  'com.googlecode.iterm2':

    skipSystemEventsProbe: true

    # return path of the current session. this is sluggish on old machines!
    getUrl: (element) ->
      try
        ttyName = element.tty()
        # console.log(ttyName)
        if ttyName
          # run a command that finds the working directory of a tty.
          # FIXME this command is very brittle.
          cmd = """
            short_tty=`basename #{ttyName}`
            tty_pid=`ps -f -o pid,etime,command | grep $short_tty | sort -k 9 | head -n 1 | awk '{print $2}'`
            /usr/sbin/lsof -a -p $tty_pid -d cwd -n -F n | grep '^n' | sed 's/^n//'
          """

          cmdOut = runCmd(cmd).trim()

          return cmdOut
        else
          throw Error('cx-jxa: no ttyName for window')

      catch e
        debugger

    getElements: (window) ->
      # for now, just the frontmost tab of an iterm window, since returning all elements will potentially be too slow.
      window
        .tabs()
        .map (t) -> t.currentSession()
        .map (s) -> 
          id: s.id,
          tabId: s.id(),
          name: s.name,
          tty: s.tty

    getCurrentElementIndex: (window, elements) ->
      currentId = window.currentSession().id()
      return elements.map((e)-> e.id()).indexOf(currentId)


#= pvt, util

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
