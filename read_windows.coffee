# ---
# doit: | 
#   `coffee -cp #{file} | osascript -l JavaScript`
# ---



# BEGIN extractable interface

# finder
class WindowAccessor

  # window-level accessors

  getId: (window) ->
    window.id()

  getName: (window) ->
    window.name()

  getElements: (window) ->
    returnFirstSuccessful [
      ->
        [ window.target() ]
      ->
        window.tabs()
      ->
        [ window.document() ]
    ]

  getAnchor: (elements) ->
    if elements.length > 1
      elements.find((e) ->
        if e and e.current
          e.current
        else
          # FIXME why would elem end up being null?
          debugger
          false
      )
    else
      elements[0]

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

  getUrl: (element) ->
    returnFirstSuccessful [
      ->
        element.url()
      ->
        # keynote
        element.file().toString()
    ]

  getElementName: (element) ->
    element.name()


class XcodeStyle extends WindowAccessor

  getUrl: (element) ->
    element.fileReference.fullPath()[0]

  getElementName: (element) ->
    element.fileReference.name()[0]


class SafariStyle extends WindowAccessor



windowAccessor = (app) ->
  if app == 'com.apple.dt.Xcode'
    new XcodeStyle()
  else if ['com.google.Chrome.canary', 'com.apple.Safari'].includes(app)
    new SafariStyle()
  else
    new WindowAccessor()


# END


@run = (argv) ->
  'use strict'
  app = argv[0]
  filterWindowId = argv[1]

  # TEST VALUES uncomment lines and run without any params to test the script on a specific app.
  if argv.length == 0 or !app or app == ''
    app = 'com.apple.Safari'
    # app = 'com.apple.Finder'
    # app = "com.google.Chrome.canary"
    # app = "com.torusknot.SourceTreeNotMAS"
    # app = "com.apple.spotlight"
    app = "com.apple.dt.Xcode"
    # app = "com.apple.iWork.Keynote"
    # app = "com.apple.iWork.Numbers"
    # filterWindowId = 15248

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
      isCurrent = if visibleTabIndex then visibleTabIndex == index else null
      
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

