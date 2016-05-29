# ---
# doit: 
#   cmd: | 
#     coffee -cp #{file} | osascript -l JavaScript - #{bundle_id}
#   args:
#     bundle_id:
#       - com.apple.Safari
#       
# test:
#   args:
#     bundle_id:
#       - com.apple.Safari
#       - com.apple.Finder
#       - com.google.Chrome.canary
#       - com.torusknot.SourceTreeNotMAS
#       - com.apple.spotlight
#       - com.apple.dt.Xcode
#       - com.apple.iWork.Keynote
#       - com.apple.iWork.Numbers
# ---

### jshint strict: true, asi: true, newcap: false ###
### jshint -W087 ###


@run = (argv) ->
  # read window info using the app's applescript dictionary.

  read_windows1 = (app_name, filter_window_id) ->
    application = Application(app_name)
    # array of windows containing elements (window_id, url, name).
    elementsArray = application.windows().map(read_window_info)
    # convert into a map.
    windows = elementsArray.map((elements) ->
      # console.log(JSON.stringify(Object.getOwnPropertyNames(e)))
      # return 1
      anchor = undefined
      if elements.length > 1
        anchor = elements.find((e) ->
          if e and e.current
            e.current
          else
            # FIXME why would elem end up being null?
            false
        )
      else
        anchor = elements[0]
      {
        elements: elements
        anchor: anchor
      }
    )
    if filter_window_id
      windows = windows.filter((w) ->
        w.elements[0].window_id == filter_window_id
      )
    # result
    JSON.stringify windows: windows

  read_window_info = (w) ->
    try
      elements = returnFirstSuccessful([
        ->
          [ w.target() ]
        ->
          # return w.tabs().map(function(e) {
          #     var isCurrent = (visibleTabIndex == e.index())
          #     return {
          #         name: e.name(),
          #         url: e.url(),
          #         window_id: w.id(),
          #         current: isCurrent,
          #         tab_index: e.index(),
          #     }
          # })
          w.tabs()
        ->
          [ w.document() ]
      ])
      element_data = returnFirstSuccessful([
        ->
          visibleTabIndex = undefined
          try
            if w.currentTab
              visibleTabIndex = w.currentTab().index()
            else if w.activeTab
              # for chrome, use activeTab instead.
              visibleTabIndex = w.activeTab().index()
          catch e
            # finder ends up here, among other things.
          elements.map (element) ->
            index = undefined
            isCurrent = undefined
            if element.index
              index = element.index()
              isCurrent = visibleTabIndex == index
            {
              name: element.name()
              url: element.url()
              window_id: w.id()
              current: isCurrent
              tab_index: index
            }
        ->
          elements.map (element) ->
            {
              url: element.file().toString()
              name: element.name()
              window_id: w.id()
            }
        ->
          elements.map (element) ->
            {
              name: element.fileReference.name()[0]
              url: element.fileReference.fullPath()[0]
              window_id: w.id()
            }
      ])
      # debugger
      return element_data
    catch e
      debugger
      return [ {
        err: e.toString()
        window_id: w.id()
        window_name: w.name()
      } ]
    return

  # read using system events.
  # adapted from https://forum.keyboardmaestro.com/t/path-of-front-document-in-named-application/1468
  # NOTE this will scope windows to current space only!

  read_windows2 = (bundle_id) ->
    app_name = Application(bundle_id).name()

    ### jshint newcap:false ###

    appSE = Application('System Events')
    appNamed = null
    lstWins = null
    strPath = ''
    lngPrefix = undefined
    strURL = undefined
    appNamed = appSE.applicationProcesses[app_name]
    # IS THERE AN OPEN WINDOW IN AN APPLICATION OF THIS NAME ?
    try
      lstWins = appNamed.windows()
    catch f
      return JSON.stringify(err: 'e1: No open documents found in ' + app_name)
    if lstWins
      # DOES THE WINDOW CONTAIN A SAVED DOCUMENT ?
      try
        strURL = lstWins[0].attributes['AXDocument'].value()
      catch g
        return JSON.stringify(err: 'e2: No open documents found in ' + app_name)
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
    throw 'no calls were successful.'
    return

  'use strict'
  app = argv[0]
  filter_window_id = argv[1]
  # TEST VALUES uncomment lines and run without any params to test the script on a specific app.
  if argv.length == 0 or !app or app == ''
    throw "no args"
  try
    return read_windows1(app, filter_window_id)
  catch e
    debugger
    # try the fallback using system events.
    return read_windows2(app)
  return
