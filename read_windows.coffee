# ---
# doit: 
#   cmd: | 
#     coffee -cp #{file} | osascript -l JavaScript - #{bundle_id} | jq
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

  # ## most customisation-relevant

  # return a url or posix path for a window's element.
  getUrl: (element) ->
    returnFirstSuccessful [
      ->
        element.url()
      ->
        # keynote
        element.file().toString()
    ]

  # return one of the elements of a window which url is bookmarked.
  # the default implementation returns either the single element or the first element marked as 'current'.
  getAnchor: (elements) ->
    if elements.length == 1
      # @getUrl elements[0]  # WIP
      elements[0]
 
    else
      # for multiple elements, return the one marked as current.
      if currentElem = elements.find((e) ->
          if e and e.current
            e.current
          else
            false
          )
        # @getUrl currentElem  # WIP
        currentElem
      else
        throw "no element marked as current"

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


  # window-level accessors

  getId: (window) ->
    window.id()

  getName: (window) ->
    window.name()

  # return index of the window's element which is frontmost.
  getCurrentElementIndex: (window, elements) ->
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


# END


# ## JXA entry point -- will be invoked by `osascript`.
@run = (argv) ->
  'use strict'
  app = argv[0]
  filterWindowId = argv[1]

  # TEST VALUES uncomment lines and run without any params to test the script on a specific app.
  if argv.length == 0 or !app or app == ''
    # app = 'com.googlecode.iterm2'  # DEV
    throw "no args"

  console.log "probing app #{app}"

  accessor = windowAccessor(app)

  if accessor.skipSystemEventsProbe
    readWindows1(app, filterWindowId, accessor)
  else
    returnFirstSuccessful [
      ->
        readWindows1(app, filterWindowId, accessor)
      ->
        readWindows2(app, filterWindowId)
    ]


# read window info using the app's applescript dictionary.
readWindows1 = (bundleId, filterWindowId, accessor) ->
  application = Application(bundleId)
  # NOTE this will launch the app, if it's not running. This was an occasional headache during development where there were different versions of the same app.

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
    visibleTabIndex = windowAccessor.getCurrentElementIndex(window)
    elements = windowAccessor.getElements(window)

    elements.map (element) ->
      index = elements.indexOf(element)
      isCurrent = if visibleTabIndex then visibleTabIndex - 1 == index else null
      
      {
        name: windowAccessor.getElementName(element)
        url: windowAccessor.getUrl(element)
        tab_index: index
        current: isCurrent

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
## helper functions
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


# merge the object provided by bundle-specific to the base accessor instance.
# if a global property `windowAccessor` exists, its accessors will be merged into a WindowAccessor instance.
windowAccessor = (app) ->
  baseAccessor = new WindowAccessor()

  if @windowAccessor and @windowAccessor.bundleId == app
    Object.getOwnPropertyNames(@windowAccessor).forEach (propertyName) ->
      propertyVal = @windowAccessor[propertyName]
      baseAccessor[propertyName] = propertyVal
      console.log "copied #{propertyName} to #{JSON.stringify(baseAccessor)}"
    
  return baseAccessor


