returnFirstSuccessful = require('./lib/returnFirstSuccessful')
directives = require('./windowMaker_directives')
merged = require('./lib/merged')

module.exports =

  (bundleId) ->
    specificOperations = directives[bundleId]

    return \
      if specificOperations?
        merged(baseMaker, specificOperations)
      else
        baseMaker



baseMaker =
  createWindow: (app) -> return app.Document().make()
  loadResources: () -> @loadFirstResourceAsTargetPath(arguments...)


#== baseMaker pvt

# for windows with tabs
# e.g. safari, chrome
baseMaker.loadResourcesInTabs = (app, window, resourceUrls) ->
  for resourceUrl, i in resourceUrls
    if i != 0
      window.tabs.push(app.Tab())
    window.tabs[window.tabs.length-1].url = resourceUrl
    
baseMaker.loadFirstResourceAsTargetPath = (app, window, resourceUrls) ->
  firstPathString = paths(resourceUrls)[0]
  firstPath = Path(firstPathString)

  window.properties = {
    target: Path(firstPath)
  }


## UTIL

paths = (urlStrings) ->  # TACTICAL
  urlStrings.map (s) ->
    s2 = s.replace(/^file:\/\//, "")  # file:///xyz -> /xyz
    #   .replace("\"", "\\\"")  # quote '"'
    # return "\"#{s2}\""  # "/xyz"
