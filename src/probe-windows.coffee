# ---
# doit: 
#   cmd: | 
#     sleep 0.3 & `dirname #{file}`/../dist/`basename #{file} .coffee`.js com.apple.dt.Xcode
#   args:
#     bundleId:
#       - com.apple.Safari
#       
# test:
#   args:
#     bundleId:
#       - com.apple.Safari
#       - com.apple.finder
#       - com.google.Chrome.canary
#       - com.torusknot.SourceTreeNotMAS
#       - com.apple.spotlight
#       - com.apple.dt.Xcode
#       - com.apple.iWork.Keynote
#       - com.apple.iWork.Numbers
# ---


windowAccessor = require('./windowAccessor')
returnFirstSuccessful = require('./lib/returnFirstSuccessful')
runningApps = require('./lib/runningApps')



# ## JXA entry point -- will be invoked by `osascript`.
global.main = (argv) ->
  bundleId = argv[0]
  filterWindowId = argv[1]

  # TEST VALUES uncomment lines and run without any params to test the script on a specific bundleId.
  if argv.length == 0 or !bundleId or bundleId == ''
    # bundleId = 'com.googlecode.iterm2'  # DEV
    throw Error("cx-jxa: no args")

  trace "probing app #{bundleId}"

  accessor = windowAccessor(bundleId)

  windowProbeResult =
    if accessor.skipSystemEventsProbe
      readWindows(bundleId, filterWindowId, accessor)
    else
      returnFirstSuccessful [
        ->
          try
            readWindows(bundleId, filterWindowId, accessor)
          catch e
            trace toString({ msg: e.toString(), stack: e.stack })
            throw e
        ->
          readWindowsWithSystemEvents(bundleId, filterWindowId)
      ]

  return toString(windowProbeResult)



# read window info using the app's applescript dictionary.
readWindows = (bundleId, filterWindowId, windowAccessor) ->

  applications = runningApps(bundleId)
  if applications.length == 0
    throw Error("cx-jxa: no process for bundleId: #{bundleId}")

  windows = 
    applications.flatMap (app) ->

      # array of windows containing elements (windowId, url, name).
      windowAccessor
        # get the windows
        .getWindows(app)
  
  windowData =

    # map to elements
    windows.map (window) ->
      elementsFrom window, windowAccessor

    # filter to the window id
    .filter (windowElements) ->
      if filterWindowId?
        return windowElements[0].windowId == filterWindowId  # UGH assuming first element is authoritative
      else
        return true

    # map to results
    .map (elements) ->
      anchorElement = windowAccessor.getAnchor(elements)

      return {
        elements: elements
        anchor: anchorElement
      }

  return { windows: windowData }


elementsFrom = (window, windowAccessor) ->
  try

    windowId = String(windowAccessor.getId(window))

    elements = windowAccessor.getElements(window)

    currentTabIndex = 
      if elements.length > 0
        windowAccessor.getCurrentElementIndex(window, elements)
      else
        -1

    bounds = window.bounds()
    frame = "{{#{bounds.x}, #{bounds.y}}, {#{bounds.width}, #{bounds.height}}}"

    return elements.map (element) ->

      try

        index = elements.indexOf(element)
        isCurrent =
          if currentTabIndex?
            currentTabIndex == index
          else
            null

        return {
          title: windowAccessor.getElementName(element)
          url: windowAccessor.getUrl(element)
          tabId: element.tabId
          tabIndex: index
          current: isCurrent
          frame: frame

          windowId: windowId
        }

      catch e
        debugger

        return {
          err: [e.message, e]
          title: windowAccessor.getTitle(window)

          windowId: String(windowAccessor.getId(window))
        }

  catch e
    return [
      err: [e.message, e]
      title: windowAccessor.getTitle(window)
      windowId: String(windowAccessor.getId(window))
    ]



# read using system events.
# adapted from https://forum.keyboardmaestro.com/t/path-of-front-document-in-named-application/1468
# NOTE this will scope windows to current space only!
readWindowsWithSystemEvents = (bundleId, filterWindowId) ->
  matches = Application('System Events').applicationProcesses.whose({ bundleIdentifier: bundleId })
  if matches.length == 0
    return {
      err: 'e3: System Events did not return app for ' + bundleId
    }

  app = matches[matches.length-1]
  
  # IS THERE AN OPEN WINDOW IN AN APPLICATION OF THIS NAME ?
  windows = null
  try
    windows = app.windows()
  catch f
    return {
      err: 'e1: error obtaining windows for ' + bundleId
    }

  unless windows?
    return {
      err: "e2: error obtaining windows for #{bundleId}"
    }

  windowsData = windows.map (w) ->
    try
      windowId = 
        if w.attributes.name().includes('AXIdentifier')
          String(w.attributes['AXIdentifier'].value())
        else
          ""

      return {
        url: w.attributes['AXDocument'].value()
        title: w.attributes['AXTitle'].value()
        frame: "{{" + w.position() + "}, {" + w.size() + "}}"
        windowId: windowId
      }
      
    catch g
      return {
        err: "e2: error obtaining url for #{[bundleId, w]}"
      }  

  return {
    windows: windowsData.map (window) ->
      elements: [ window ]
      anchor: window
  }



##
## helper functions
## TODO factor out and make more reusable / consistent.
##

trace = (out) ->
  # DEV uncomment to see logging statements. make sure to comment back, since the output to stdout will break parsing in the pipeline.
  # console.log out

toString = (obj) ->
  JSON.stringify obj, null, '  '
