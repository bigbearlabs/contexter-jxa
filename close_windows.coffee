### close windows of an app. ###


shouldDebug = false

@run = (argv) ->
  bundleId = argv[0]
  windowIds = JSON.parse(argv[1])

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
    console.log { msg: "error closing window ", err: e }
    if shouldDebug
      debugger

    app = Application('System Events').applicationProcesses[app.name()]
    windowIds.forEach (windowId) ->
      closeWindowWithSystemEvents(app, windowId)


closeWindow = (app, windowId) ->
  window = app.windows.byId(windowId)()
  if window
    window.close()
  else
    console.log("ugh!")
    # TODO raise.

closeWindowWithSystemEvents = (app, windowId) ->
  window = app.windows().find (w) ->
    w.attributes["AXIdentifier"].value() == windowId
  if !window  
    return JSON.stringify({
      err: "e3: window not found",
      id: windowId
    })
  closeButton = window.buttons().find (e) ->
    e.attributes["AXSubrole"].value() == "AXCloseButton"

  closeButton.actions["AXPress"].perform()
