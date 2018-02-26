### close windows of an app. ###


DEBUG = false

@run = (argv) ->
  args = argsHash(argv)

  bundleId = args.bundleId || (throw "bundle id is required")
  windowIds = JSON.parse(args.windowIds || "[]")
  urls = JSON.parse(args.urls || "[]")
  titles = JSON.parse(args.titles || "[]")

  # first try parsing into a number.
  windowIds = windowIds?.map (id) ->
    parsedId = parseInt(id)
    if isNaN(parsedId)
      id
    else
      parsedId

  app = Application(bundleId)

  try
    if !(windowIds?) or windowIds.length < 1
      throw Error("no windowIds")

    results = windowIds.map (windowId) ->
      closeWindow(app, windowId)
    return JSON.stringify(results)

  catch e
    console.log "error closing window using default impl: #{e}"

    if DEBUG
      debugger

    appProcess = Application('System Events').applicationProcesses[app.name()]

    windowSpecifiers =
      if windowIds?.length > 0
        windowIds.map (windowId) -> {windowId}
      else if urls?.length > 0
        urls.map (url) -> {url}
      else if titles?.length > 0
        titles.map (title) -> {title}
      else
        throw "could not create window specifiers."

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
    throw Error("IMPL matches don't conform: #{matches}.")

  return matches[0]



# ### util

argsHash = (argv) ->
  # for each bit, split to <key>=<value>, to return a k-v pair.
  # reduce it down to a pojo and return.

  argsObj = argv.reduce (acc, token) ->
    [k, v] = token.split("=")
    acc[k] = v
    acc
  , {}

  return argsObj