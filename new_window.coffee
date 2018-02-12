# ---
# doit:
#   cmd: |
#     coffee -cp #{file} | osascript -l JavaScript - 'bundleId=com.google.Chrome.canary url=http://google.com'
#   args:
#
# test:
# ---


# NOTE we could make this a very comprehensive script that falls back to the equivalent of NSWorkspace#open, but we won't since there doesn't seem to be too pressing a need to do so.

@run = (argv) =>

  # for quick testing:
  # argv = ["bundleId=com.google.Chrome.canary", "url=http://google.com"]

  args = argsHash(argv)

  @bundleId = args.bundleId
  unless @bundleId?
    err = "e5: missing or bad argument: bundleId"

  resourceUrls =
    if args.url
      [args.url]
    else if args.resourceUrls
      JSON.parse(args.resourceUrls)

  unless resourceUrls?
    err = "e6: missing or bad argument: url|resourceUrls"
          
  @directive = directives[@bundleId]
  unless @directive?
    err = "e4: no new_window directive for #{bundleId}"

  result =
    if err?
      {
        err: err
      }
    else
      newWindow(resourceUrls)

  return JSON.stringify(result)


newWindow = (resourceUrls) =>

  window = @directive.windowClass().make()
  # delay(0.1)

  # window = app.windows[0]
  return @directive.loadResources(window, resourceUrls)

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
      window.tabs.push(new app().Tab())
      window.tabs[window.tabs.length-1].url = resourceUrl

  return {
    new_window:
      id: window.id()
  }


app = -> Application(@bundleId)


directives = {
  "com.apple.Safari":
    windowClass: -> app().Document()
    loadResources: loadResourcesInTabs

  "com.apple.SafariTechnologyPreview":
    windowClass: -> app().Document()
    loadResources: loadResourcesInTabs

  "com.google.Chrome":
    windowClass: -> app().Window()
    loadResources: loadResourcesInTabs

  "com.google.Chrome.canary":
    windowClass: -> app().Window()
    loadResources: loadResourcesInTabs
}


## UTIL

# return a dictionary of args conventionally passed as an array of strings, 
# based on common sense expectations.
argsHash = (argv) ->
  # for each bit, split to <key>=<value>, to return a k-v pair.
  # reduce it down to a pojo and return.

  argsObj = argv.reduce (acc, token) ->
    [k, v] = token.split("=")
    acc[k] = v
    acc
  , {}

  return argsObj
