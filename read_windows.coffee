# ---
# doit: 
#   cmd: | 
#     coffee -cp #{file} | osascript -l JavaScript - #{bundle_id}
#   args:
#     bundle_id:
#       - com.torusknot.SourceTreeNotMAS
#       
# test:
#   args:
#     bundle_id:
#       - com.apple.Safari
#       - com.apple.finder
#       - com.google.Chrome.canary
#       - com.torusknot.SourceTreeNotMAS
#       - com.apple.spotlight
#       - com.apple.dt.Xcode
#       - com.apple.iWork.Keynote
#       - com.apple.iWork.Numbers
# ---


# BEGIN extractable interface
# NOTE This the skeleton upon which customisers can return appropriate values to record context.
# The skeleton implementation works with 'typical' applescriptable document-based apps, and some common browsers.
# 
# We still need to find a good way to allow for an extension of this class in another file, without dragging in a complicated requiring mechanism.
# A tempting option is to just concatenate the scripts files in the right order, and rely on documentation to 'expose' the extensible prototype.

class WindowAccessor

  # most customisation-relevant

  getUrl: (element) ->
    returnFirstSuccessful [
      ->
        element.url()
      ->
        # keynote
        element.file().toString()
    ]


  getAnchor: (elements) ->
    if elements.length == 1
      @getUrl elements[0]

    else
      # for multiple elements, return the one marked as current.
      if current_elem = elements.find((e) ->
          if e and e.current
            e.current
          else
            false
          )
        @getUrl current_elem


  # elements can be anything that participates in a focus order, such as tabs, folder or mailbox.
  # if returning only one element for a window (simplest implementation), make sure it's in an array.
  getElements: (window) ->
    returnFirstSuccessful [
      ->
        [ window.target() ]
      ->
        window.tabs()
      ->
        [ window.document() ]
    ]


  # window-level accessors

  getId: (window) ->
    window.id()

  getName: (window) ->
    window.name()



  getFrontTabIndex: (window) ->
    try
      if window.currentTab
        return window.currentTab().index()
      else if window.activeTab
        # for chrome, use activeTab instead.
        return window.activeTab().index()
    catch e
      # finder ends up here, among other things.
      return null

  # element-level accessors

  getElementName: (element) ->
    element.name()


class XcodeWindowAccessor extends WindowAccessor

  getUrl: (element) ->
    element.fileReference.fullPath()[0]

  getElementName: (element) ->
    element.fileReference.name()[0]


class SafariWindowAccessor extends WindowAccessor


# a quick-dirty signature-based factory.
windowAccessor = (app) ->
  if app == 'com.apple.dt.Xcode'
    new XcodeWindowAccessor()
  else if ['com.google.Chrome.canary', 'com.apple.Safari'].includes(app)
    new SafariWindowAccessor()
  # else if path = bundle_path_exists(app)
  #   require(path)
  esle if app == 'com.googlecode.iterm2'
    new ItermWindowAccessor()
  else
    new WindowAccessor()


# END


@run = (argv) ->
  'use strict'
  app = argv[0]
  filterWindowId = argv[1]

  # TEST VALUES uncomment lines and run without any params to test the script on a specific app.
  if argv.length == 0 or !app or app == ''
    throw "no args"

  returnFirstSuccessful [
    ->
      readWindows1 app, filterWindowId
    ->
      readWindows2 app, filterWindowId
  ]


# read window info using the app's applescript dictionary.
readWindows1 = (bundleId, filterWindowId) ->
  application = Application(bundleId)
  accessor = windowAccessor(bundleId)

  JSON.stringify 
    windows: 
      # array of windows containing elements (window_id, url, name).
      application
        .windows()
        .map (window) ->
          elementsFrom window, accessor
        .filter (window) ->
          if filterWindowId
            window.elements[0].window_id == filterWindowId
          else
            true
        .map (elements) ->
          return {
            elements: elements
            anchor: accessor.getAnchor(elements)
          }

elementsFrom = (window, windowAccessor) ->
  try
    visibleTabIndex = windowAccessor.getFrontTabIndex(window)
    elements = windowAccessor.getElements(window)

    elements.map (element) ->
      index = elements.indexOf(element)
      isCurrent = if visibleTabIndex then visibleTabIndex - 1 == index else null
      
      {
        name: windowAccessor.getElementName(element)
        url: windowAccessor.getUrl(element)
        current: isCurrent
        tab_index: index

        window_id: windowAccessor.getId(window)
      }

  catch e
    debugger

    [ 
      err: e.toString()
      name: windowAccessor.getName(window)

      window_id: windowAccessor.getId(window)
    ]


# read using system events.
# adapted from https://forum.keyboardmaestro.com/t/path-of-front-document-in-named-application/1468
# NOTE this will scope windows to current space only!

readWindows2 = (bundleId, filterWindowId) ->
  appName = Application(bundleId).name()
  app = Application('System Events').applicationProcesses[appName]

  
  # IS THERE AN OPEN WINDOW IN AN APPLICATION OF THIS NAME ?
  lstWins = null
  try
    lstWins = app.windows()
  catch f
    return JSON.stringify(err: 'e1: No open documents found in ' + appName)
  if lstWins
    # DOES THE WINDOW CONTAIN A SAVED DOCUMENT ?
    try
      strURL = lstWins[0].attributes['AXDocument'].value()
    catch g
      return JSON.stringify(err: 'e2: No open documents found in ' + appName)
  windows = lstWins.map((w0) ->
    {
      url: w0.attributes['AXDocument'].value()
      name: w0.attributes['AXTitle'].value()
    }
  )
  JSON.stringify windows: [ {
    elements: windows
    anchor: windows[0]
  } ]


##
## { item_description }
##

returnFirstSuccessful = (fns) ->
  i = 0
  while i < fns.length
    fn = fns[i]
    try
      if fn.callAsFunction
        return fn.callAsFunction()
      else
        # debugger
        return fn.apply()
    catch e
      # this function threw -- move on to the next one.
    i++
  debugger
  throw 'no calls were successful.'
  return


##
## { item_description }
##

bundle_path_exists = (bundle_id) ->
  # working a 'requires' could solve this, but potentially make running quite slow.
  # ...
  


#= iterm (dupe)



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
