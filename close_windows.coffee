### close windows of an app. ###


DEBUG = false

@run = (argv) ->
  bundleId = argv[0]
  windowIds = JSON.parse(argv[1])
  urls = JSON.parse(argv[2])
  titles = JSON.parse(argv[3])

  # first try parsing into a number.
  windowIds = windowIds.map (id) ->
    parsedId = parseInt(id)
    if isNaN(parsedId)
      id 
    else 
      parsedId

  app = Application(bundleId)

  try
    if windowIds.length < 1
      throw "no windowIds"

    results = windowIds.map (windowId) ->
      closeWindow(app, windowId)
    return JSON.stringify(results)

  catch e
    console.log "error closing window using default impl: #{e}"

    if DEBUG
      debugger

    appProcess = Application('System Events').applicationProcesses[app.name()]

    windowSpecifiers = 
      if windowIds.length != 0
        windowIds.map (windowId) -> {windowId}
      else if urls.length != 0
        urls.map (url) -> {url}
      else if titles.length != 0
        titles.map (title) -> {title}

    results = windowSpecifiers.map (e) ->
      closeWindowWithSystemEvents(appProcess, e)

    return JSON.stringify(results)

closeWindow = (app, windowId) ->
  window = app.windows.byId(windowId)()
  unless window?
    throw {
      msg: "e1: no window found",
      data: [ app, windowId ]
    }

  window.close()

  return {
    result: 0
    id: windowId
  }

closeWindowWithSystemEvents = (appProcess, windowSpecifier) ->
  window = findWindow(appProcess, windowSpecifier)
    
  closeButton = window.buttons().find (b) ->
    b.attributes["AXSubrole"].value() == "AXCloseButton"

  closeButton.actions["AXPress"].perform()

  return {
    result: 0
    id: windowSpecifier.windowId
    specifier: windowSpecifier
  }


findWindow = (appProcess, windowSpecifier) -> 
  matches = appProcess.windows().filter (w) ->

    windowId = windowSpecifier.windowId
    if windowId?
      return w.id() is windowId
    
    url = windowSpecifier.url
    if url?
      return w.url() is url

    title = windowSpecifier.title
    if title?
      return w.title() is title

    return false

  if matches.length != 1
    # TODO
    throw "IMPL matches don't conform: #{matches}."

  return matches[0]