module.exports = directives =

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
      app.Document().make()
      delay(0.5)
      return app.windows[0]
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

