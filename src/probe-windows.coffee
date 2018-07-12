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
          trace e.stack
          throw e
      ->
        readWindowsWithSystemEvents(bundleId, filterWindowId)
    ]

  return toString(windowProbeResult)



# read window info using the app's applescript dictionary.
readWindows = (bundleId, filterWindowId, windowAccessor) ->
  application = Application(bundleId)
  # NOTE this will launch the app, if it's not running. This was an occasional headache during development where there were different versions of the same app.

  windows =
    # array of windows containing elements (windowId, url, name).
    windowAccessor
      .getWindows(application)

      .map (window) ->
        elementsFrom window, windowAccessor

      .filter (window) ->
        if filterWindowId
          window.elements[0].windowId == filterWindowId
        else
          true

      .map (elements) ->
        elements: elements
        anchor: windowAccessor.getAnchor(elements)

  return { windows }

elementsFrom = (window, windowAccessor) ->
  try
    elements = windowAccessor.getElements(window)
    currentTabIndex = windowAccessor.getCurrentElementIndex(window, elements)

    return elements.map (element) ->
      index = elements.indexOf(element)
      isCurrent = 
        if currentTabIndex? 
          currentTabIndex == index
        else
          null
      bounds = window.bounds()

      {
        title: windowAccessor.getElementName(element)
        url: windowAccessor.getUrl(element)
        tabId: element.tabId
        tabIndex: index
        current: isCurrent
        frame: "{{#{bounds.x}, #{bounds.y}}, {#{bounds.width}, #{bounds.height}}}"

        windowId: String(windowAccessor.getId(window))
      }

  catch e
    debugger

    [
      err: e
      title: windowAccessor.getName(window)

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
        if w.attributes.name().indexOf('AXIdentifier') > -1 
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
##

trace = (out) ->
  # DEV uncomment to see logging statements.
  # console.log out

toString = (obj) ->
  JSON.stringify obj, null, '  '


# # FIXME replace with a require graph: probe -> <app-bundle-id>/window-accessor.coffee -> window-accessor.coffee
# # or #windowAccessor -> WindowAccessor -> <app-bundle-id>/window-accessor.coffee
# # 
# # merge the object provided by bundle-specific script to the base accessor instance.
# # if a global property `windowAccessor` exists, its accessors will be merged into a WindowAccessor instance.
# windowAccessor = (app) ->
#   baseAccessor = new WindowAccessor()

#   if @windowAccessor and @windowAccessor.bundleId == app
#     Object.getOwnPropertyNames(@windowAccessor).forEach (propertyName) ->
#       propertyVal = @windowAccessor[propertyName]
#       baseAccessor[propertyName] = propertyVal
#       trace "copied #{propertyName} to #{JSON.stringify(baseAccessor)}"
    
#   return baseAccessor
