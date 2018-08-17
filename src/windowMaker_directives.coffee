paths = require('./lib/paths')


module.exports = 

directives =
  
  "com.apple.dt.Xcode":
    newWindowWithResources: (app, resourceUrls) ->
      if resourceUrls.length < 1
        throw Error("need at least 1 resourceUrls")

      for url in resourceUrls
        app.open(path(url))

      url = resourceUrls[0]
      newWindow = app.windows()
        .filter (w) ->
          w.document?().path?() == path(url)
        [0]

      if newWindow?
        return newWindow
      else
        throw Error("couldnt' find new window after opeining #{resourceUrls}")

  "com.apple.finder":
    createWindow: (app) -> return app.FinderWindow().make()
    loadResources: -> @loadFirstResourceAsTargetPath(arguments...)


  "com.googlecode.iterm2":
    createWindow: (app) -> return app.createWindowWithDefaultProfile()
    loadResources: (app, window, resourceUrls) ->
      # navigate to resource.
      path = $.NSURL.URLWithString(resourceUrls[0]).path.cString
      session = window.tabs[0].sessions[0]
      cmd = "cd '#{path}'"
      app.write(session,{text: cmd})


  "com.apple.Safari":
    createWindow: (app) ->
      winIdsBefore = app.windows().map((w) -> w.id())
      app.Document().make()
      winIdsAfter = app.windows().map((w) -> w.id())
      newIds = winIdsAfter
        .filter (id) ->
          new Set(winIdsBefore).has(id) == false
      # assert 1 and only 1 new id.
      if newIds.length != 1
        throw Error("expected only 1 new id after making a new window, but got new ids: #{newIds}")

      newWindows = app.windows()
        .filter (w) -> w.id() == newIds[0]
      
      return newWindows[0]

    loadResources: -> @loadResourcesInTabs(arguments...)


  "com.apple.SafariTechnologyPreview":
    createWindow: (app) ->
      app.Document().make()
      return app.windows[0]
    loadResources: -> @loadResourcesInTabs(arguments...)


  "com.google.Chrome":
    createWindow: (app) -> return app.Window().make()
    loadResources: -> @loadResourcesInTabs(arguments...)


  "com.google.Chrome.canary":
    createWindow: (app) -> return app.Window().make()
    loadResources: -> @loadResourcesInTabs(arguments...)

