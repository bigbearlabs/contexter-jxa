### close windows of an app. ###


DEBUG = false

@run = (argv) ->
  bundleId = argv[0]
  windowIds = JSON.parse(argv[1])
  urls = JSON.parse(argv[2])

  # first try parsing into a number.
  windowIds = windowIds.map (id) ->
    parsedId = parseInt(id)
    return (if isNaN(parsedId) then id else parsedId)

  try
    app = Application(bundleId)
    windowIds.forEach (windowId) ->
      closeWindow(app, windowId)
  catch e
    console.log "error closing window using default impl: #{e}"

    if DEBUG
      debugger

    appProcess = Application('System Events').applicationProcesses[app.name()]
    try
      windowIds.forEach (windowId) ->
        closeWindowWithSystemEvents(appProcess, windowId)
    catch e
      console.log "error closing window using fallback impl: #{e}"
      urls.forEach (url) ->
        closeWindowWithSystemEvents(appProcess, null, url)


closeWindow = (app, windowId) ->
  window = app.windows.byId(windowId)()
  if window?
    window.close()
  else
    throw {
      msg: "e1: no window found",
      data: [ app, windowId ]
    }

closeWindowWithSystemEvents = (appProcess, windowId, url) ->
  window = appProcess.windows().find (w) ->
    if windowId?
      w.attributes["AXIdentifier"].value() == windowId
    else
      w.attributes["AXDocument"].value() == url

  if !window?
    throw {
      msg: "e3: window not found",
      data: [appProcess, windowId, url]
    }
    
  closeButton = window.buttons().find (b) ->
    b.attributes["AXSubrole"].value() == "AXCloseButton"

  closeButton.actions["AXPress"].perform()
