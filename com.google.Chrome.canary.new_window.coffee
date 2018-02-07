bundleId = 'com.google.Chrome.canary'
app = Application(bundleId)


@run = (argv) ->
  resourceUrls = JSON.parse(argv[0])
  JSON.stringify(newWindow(resourceUrls))


newWindow = (resourceUrls) ->
  directive = directives[bundleId]
  if directive is null
    throw "no directive for #{bundleId}"

  window = directive.windowClass().make()
  # delay(0.1)

  # window = app.windows[0]
  return directive.loadResources(window, resourceUrls)

# newWindow = (resourceUrls) ->
#   window = windowClass().make()
#   # delay(0.1)

#   # window = app.windows[0]
#   return loadResources(window, resourceUrls)

    
# for windows with tabs
# e.g. safari, chrome
loadResourcesInTabs = (window, resourceUrls) ->
  for resourceUrl, i in resourceUrls
    if i != 0
      window.tabs.push(new app.Tab())
    window.tabs[window.tabs.length-1].url = resourceUrl

  return {
    new_window:
      id: window.id()
  }


directives = {
  "com.apple.Safari":
    windowClass: -> app.Document()
    loadResources: loadResourcesInTabs

  "com.apple.SafariTechnologyPreview":
    windowClass: -> app.Document()
    loadResources: loadResourcesInTabs

  "com.google.Chrome":
    windowClass: -> app.Window()
    loadResources: loadResourcesInTabs

  "com.google.Chrome.canary":
    windowClass: -> app.Window()
    loadResources: loadResourcesInTabs
}
