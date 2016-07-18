# ---
# doit:
#   cmd: |
#     coffee -cp #{file} | osascript -l JavaScript - com.googlecode.iTerm2
#   args:
#
# test:
# ---

@windowAccessor =

  bundleId: 'com.googlecode.iterm2'

  skipSystemEventsProbe: true


  # return path of the current session. this is sluggish!
  getUrl: (element) ->
    try
      ttyName = element.tty()
      # console.log(ttyName)
      if ttyName
        # run a command that finds the working directory of a tty.
        # FIXME this command is very brittle.
        cmd = """
          short_tty=`basename #{ttyName}`
          tty_ps=`ps -f | grep $short_tty | head -n 1 | awk '{print $2}'`
          /usr/sbin/lsof -a -p $tty_ps -d cwd -n | tail -n +2 | awk '{print $NF}'
        """

        cmdOut = @runCmd(cmd).trim()

        if cmdOut.length > 1
          return "file://#{cmdOut}"
        else
          return cmdOut
      else
        throw 'e1: no ttyName for window'
      return
    catch e
      debugger

  # for now, just the frontmost tab of an iterm window, since returning all elements will potentially be too slow.
  getElements: (window) ->
    [ window.currentSession() ]


  #= pvt

  runCmd: (cmd) ->
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
