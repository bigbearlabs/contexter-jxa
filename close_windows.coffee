### close windows of an app. ###


shouldDebug = false

@run = (argv) ->
  bundleId = argv[0]
  windowIds = JSON.parse(argv[1])
  urls = JSON.parse(argv[2])

  # first try parsing into a number.
  windowIds = windowIds.map (e) ->
    i = parseInt(e)
    if isNaN(i)
      e
    else 
      i

  try
    app = Application(bundleId)
    windowIds.forEach (windowId) ->
      closeWindow(app, windowId)
  catch e
    console.log "error closing window using default impl: #{e}"

    if shouldDebug
      debugger

    app = Application('System Events').applicationProcesses[app.name()]
    try 
      windowIds.forEach (windowId) ->
        closeWindowWithSystemEvents(app, windowId)
    catch e
      console.log "error closing window using fallback impl: #{e}"
      urls.forEach (url) ->
        closeWindowWithSystemEvents(app, null, url)

closeWindow = (app, windowId) ->
  window = app.windows.byId(windowId)()
  if window
    window.close()
  else
    throw {
      msg: "e1: no window found",
      data: [ app, windowId ]
    }

closeWindowWithSystemEvents = (app, windowId, url) ->
  window = app.windows().find (w) ->
    if windowId 
      w.attributes["AXIdentifier"].value() == windowId
    else
      w.attributes["AXDocument"].value() == url

  if !window  
    throw {
      msg: "e3: window not found",
      data: [app, windowId, url]
    }
    
  closeButton = window.buttons().find (e) ->
    e.attributes["AXSubrole"].value() == "AXCloseButton"

  closeButton.actions["AXPress"].perform()
