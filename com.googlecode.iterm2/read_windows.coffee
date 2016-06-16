# ---
# doit: 
#   cmd: | 
#     coffee -cp #{file} | osascript -l JavaScript - com.googlecode.iTerm2
#   args:
#       
# test:
# ---

# PoC hacky subclassing of base accessor.
@windowAccessor = 

  bundleId: 'com.googlecode.iterm2'

  skipSystemEventsProbe: true


  getUrl: (element) ->
    try
      ttyProducer = element
      ttyName = ttyProducer.tty()
      # console.log(ttyName)
      if ttyName
        cmd = '/usr/sbin/lsof -a -p `/usr/sbin/lsof -a -u $USER -d 0 -n | tail -n +2 | awk \'{if($NF=="' + ttyName + '"){print $2}}\' | head -1` -d cwd -n | tail -n +2 | awk \'{print $NF}\''
        # FIXME this command is very brittle.
        cmdOut = @runCmd(cmd).trim()

        return cmdOut
      else
        throw 'e1: no ttyName for window'
      return
    catch e
      debugger

  getElements: (window) ->
    # just the frontmost tab of an iterm window.
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
