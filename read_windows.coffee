# ---
# doit: 
#   cmd: | 
#     coffee -cp #{file} | osascript -l JavaScript - #{bundleId}
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


# BEGIN extractable interface
# NOTE This the skeleton upon which customisers can return appropriate values to record context.
# The skeleton implementation works with 'typical' applescriptable document-based apps, and some common browsers.
# 
# We still need to find a good way to allow for an extension of this class in another file, without dragging in a complicated requiring mechanism.
# A tempting option is to just concatenate the scripts files in the right order, and rely on documentation to 'expose' the extensible prototype.


class WindowAccessor

  # ## most customisation-relevant

  # return a url or posix path for a window's element.
  getUrl: (element) ->
    returnFirstSuccessful [
      ->
        element.url()
      ->
        # keynote
        element.file().toString()
      ->
        # preview
        element.path()
    ]

  # return one of the elements of a window which url is bookmarked.
  # the default implementation returns either the single element or the first element marked as 'current'.
  getAnchor: (elements) ->
    if elements.length == 1
      elements[0]
 
    else
      # for multiple elements, return the one marked as current.
      if currentElem = elements.find((e) ->
          if e and e.current
            e.current
          else
            false
          )
        currentElem
      else
        throw toString {
          msg: "cx-jxa: no element marked as current"
          data: elements
        }

  # return elements of a window.
  # elements can be anything that participates in a focus order, such as tabs, folder or mailbox.
  # if returning only one element for a window (simplest implementation), make sure it's in an array.
  getElements: (window) ->
    returnFirstSuccessful [
      ->
        # finder-style script vocabulary
        [ window.target() ]
      ->
        # browser-style script vocabulary
        window.tabs()
      ->
        # vocabulary for doc windows
        [ window.document() ]
    ]


  # ## window-level accessors

  getId: (window) ->
    window.id()

  getName: (window) ->
    window.name()

  # return index of the window's element which is frontmost.
  getCurrentElementIndex: (window, elements) ->
    returnFirstSuccessful [
      -> 
        window.currentTab().index() - 1
      ->
        # for chrome, use activeTab instead.
        window.activeTabIndex() - 1 # chrome Version 56.0.2913.3 canary (64-bit)
      ->
        null
    ]

  # ## element-level accessors

  getElementName: (element) ->
    element.name()


  # ## app-level accessors

  getWindows: (application) ->
    application.windows()

    # DEV uncomment below to reduce probe volume to the frontmost window of the app.
    # [ application.windows()[0] ]

      

# END


# ## JXA entry point -- will be invoked by `osascript`.
@run = (argv) ->
  'use strict'
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
readWindows = (bundleId, filterWindowId, accessor) ->
  application = Application(bundleId)
  # NOTE this will launch the app, if it's not running. This was an occasional headache during development where there were different versions of the same app.

  windows =
    # array of windows containing elements (windowId, url, name).
    accessor
      .getWindows(application)

      .map (window) ->
        elementsFrom window, accessor

      .filter (window) ->
        if filterWindowId
          window.elements[0].windowId == filterWindowId
        else
          true

      .map (elements) ->
        elements: elements
        anchor: accessor.getAnchor(elements)

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
        name: windowAccessor.getElementName(element)
        url: windowAccessor.getUrl(element)
        tabId: element.tabId
        tab_index: index
        current: isCurrent
        frame: "{{#{bounds.x}, #{bounds.y}}, {#{bounds.width}, #{bounds.height}}}"

        windowId: String(windowAccessor.getId(window))
      }

  catch e
    debugger

    [
      err: e.toString()
      name: windowAccessor.getName(window)

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
  lstWins = null
  try
    lstWins = app.windows()
  catch f
    return {
      err: 'e1: No windows found for ' + bundleId
    }
  if lstWins
    # DOES THE WINDOW CONTAIN A SAVED DOCUMENT ?
    try
      strURL = lstWins[0].attributes['AXDocument'].value()
    catch g
      return {
        err: 'e2: No open documents found for ' + bundleId
      }

  windows = lstWins.map((w0) ->
    windowId = 
      if w0.attributes.name().indexOf('AXIdentifier') > -1 
        w0.attributes['AXIdentifier'].value()
      else
        ""
    {
      url: w0.attributes['AXDocument'].value()
      name: w0.attributes['AXTitle'].value(),
      frame: "{{" + w0.position() + "}, {" + w0.size() + "}}",
      windowId: String(windowId)
    }
  )

  return {
    windows: windows.map (window) ->
      elements: [ window ]
      anchor: window
  }



##
## helper functions
##

trace = (out) ->
  # DEV uncomment to see logging statements.
  # console.log out


returnFirstSuccessful = (fns) ->
  i = 0
  exceptions = []
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
      exceptions.push(e)
    i++
  debugger
  throw Error("cx-jxa: no calls were successful. exceptions: #{toString(exceptions)}")
  # TODO collect the exceptions for better debuggability.


toString = (obj) ->
  JSON.stringify obj, null, '  '


# merge the object provided by bundle-specific script to the base accessor instance.
# if a global property `windowAccessor` exists, its accessors will be merged into a WindowAccessor instance.
windowAccessor = (app) ->
  baseAccessor = new WindowAccessor()

  if @windowAccessor and @windowAccessor.bundleId == app
    Object.getOwnPropertyNames(@windowAccessor).forEach (propertyName) ->
      propertyVal = @windowAccessor[propertyName]
      baseAccessor[propertyName] = propertyVal
      trace "copied #{propertyName} to #{JSON.stringify(baseAccessor)}"
    
  return baseAccessor


# expose some functions to the global context so included scripts can use them.
@returnFirstSuccessful = returnFirstSuccessful
