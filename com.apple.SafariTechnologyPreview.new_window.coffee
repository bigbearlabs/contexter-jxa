bundleId = 'com.apple.SafariTechnologyPreview'
app = Application(bundleId)

@run = (argv) ->
  resourceUrls = JSON.parse(argv[0])
  JSON.stringify(newWindow(resourceUrls))


newWindow = (resourceUrls) ->
  app.Document().make()
  delay(0.1)

  window = app.windows[0]
  for resourceUrl, i in resourceUrls 
    if i != 0
      window.tabs.push(new app.Tab())
    window.tabs[window.tabs.length-1].url = resourceUrl

  return {
    new_window:
      id: window.id()
  }
