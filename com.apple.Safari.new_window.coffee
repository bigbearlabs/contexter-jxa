bundleId = 'com.apple.Safari'
app = Application(bundleId)

@run = (argv) ->
  resourceUrls = JSON.parse(argv[0])
  newWindow(resourceUrls)


newWindow = (resourceUrls) ->
  app.Document().make()
  delay(0.2)

  for resourceUrl, i in resourceUrls 
    if i != 0
      app.windows[0].tabs.push(new app.Tab())
    app.windows[0].tabs[app.windows[0].tabs.length-1].url = resourceUrl
