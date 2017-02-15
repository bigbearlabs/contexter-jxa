# close windows of an app.

@run = (argv) ->
  bundleId = argv[0]
  windowIds = JSON.parse(argv[1])

  try
    app = Application(bundleId)
    windowIds.forEach (windowId) ->
      closeWindow(app, windowId)
  catch e
    console.log { msg: "error closing window ", err: e }

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
  if window == null 
    return JSON.stringify({
      err: "e3: window not found",
      id: windowId
    })
  closeButton = window.buttons().find (e) ->
    e.attributes["AXSubrole"].value() == "AXCloseButton"

  closeButton.actions["AXPress"].perform()
