bundleId = 'com.google.Chrome'
app = Application(bundleId)

@run = (argv) ->
  resourceUrls = JSON.parse(argv[0])
  JSON.stringify(newWindow(resourceUrls))


newWindow = (resourceUrls) ->
  windowClass().make()
  delay(0.1)

  window = app.windows[0]
  return loadResources(window, resourceUrls)


windowClass = ->
  switch bundleId
    when "com.apple.Safari"
      app.Document()
    when "com.apple.SafariTechnologyPreview"
      app.Document()
    when "com.google.Chrome"
      app.Window()
    when "com.google.Chrome.canary"
      app.Window()
    else
      app.Window()
      # but i'd be surprised if this works...
    
  
loadResources = (window, resourceUrls) ->

  # windows with tabs
  # e.g. safari, chrome
  for resourceUrl, i in resourceUrls
    if i != 0
      window.tabs.push(new app.Tab())
    window.tabs[window.tabs.length-1].url = resourceUrl

  return {
    new_window:
      id: window.id()
  }
