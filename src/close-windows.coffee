### close windows of an app. ###


DEBUG = false

global.main = (argv) ->
  args = argsHash(argv)

  bundleId = args.bundleId || (throw Error("bundle id is required"))
  windowIds = JSON.parse(args.windowIds || "[]")
  urls = JSON.parse(args.urls || "[]")
  documents = JSON.parse(args.documents || "[]")
  titles = JSON.parse(args.titles || "[]")

  app = Application(bundleId)

  try
    # try closing by window id.
    
    # first try parsing into a number to meet contract with scripting / GUI scripting API.
    windowIds = windowIds?.map (id) ->
      parsedId = parseInt(id)
      if isNaN(parsedId)
        id
      else
        parsedId

    if windowIds?.length > 0
      results = windowIds.map (windowId) ->
        closeWindowId(app, windowId)

    else if documents?.length > 0
      paths = documents.map (url) ->
        toPath(url)
      results = paths.map (path) ->
        closePath(app, path)

    else
      throw Error("did not find arguments suitable for closing using scripting API.")

    return JSON.stringify({results})

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
      else if documents?.length > 0
        documents.map (document) -> {document}
      else if titles?.length > 0
        titles.map (title) -> {title}
      else
        throw Error("could not create window specifiers.")

    results = windowSpecifiers.map (e) ->
      closeWindowWithSystemEvents(appProcess, e)

    return JSON.stringify({results})


closeWindowId = (app, windowId) ->
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


closePath = (app, path) ->
  document = app.workspaceDocuments().find (doc) ->
    doc.path() is path
  document.close()


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
      return w.attributes['AXIdentifier'].value() is windowId
    
    url = windowSpecifier.url
    if url?
      return w.url() is url

    document = windowSpecifier.document
    if document?
      return w.attributes["AXDocument"].value() is document

    title = windowSpecifier.title
    if title?
      return w.title() is title

    return false

  if matches.length != 1
    throw Error("IMPL matches don't meet expectations. windowSpecifier: #{windowSpecifier} matches: #{matches}.")

    # TODO handle 0, >1 cases.

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


toPath = (url) ->
  decodeURI(url).replace(/file:\/\//, "")
  