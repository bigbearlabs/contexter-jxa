# ---
# doit:
#   cmd: |
#     coffee -cp #{file} | osascript -l JavaScript - 'windowId=x bundleId=com.apple.Safari urlJsonStr=["http://google.com"]'
#   args:
#
# test:
# ---

# newWindow_openCmd = require './lib/newWindow_openCmd'
windowMaker = require './windowMaker'
argsHash = require './lib/argsHash'


# DEBUG = true  # debug HACK


global.main = (argv) ->

  # for quick testing:
  # argv = ["bundleId=com.apple.Safari", "windowId=x", 'urlJsonStr=["http://google.com"]']

  try

    args = argsHash(argv)

    bundleId = args.bundleId ||
      throw Error("e5: missing or bad argument: bundleId")
    app = Application(bundleId)

    resourceUrl = args.url

    windowId = args.windowId            
    window = 
      app.windows().find((w) -> "#{w.id()}" == windowId) ||
        throw Error("e11: couldn't find window for id #{windowId}")


    windowMaker = windowMaker(bundleId)

    messages = []

    result = addTab(app, window, resourceUrl, windowMaker)

    if DEBUG?
      result.trace = messages
      debugger

    return JSON.stringify(result)


  catch e
    # to debug exceptions, enable the 'pause on js context' safari developer option.
    debugger

    throw e

    # TODO uncaught error tracing out stderr is very had to debug.
    # catch and error out, with more relevant src info (e.g. .coffee line)
  

addTab = (app, window, resourceUrl, windowMaker) ->
  # library function updates (doesn't add) the the last tab, so add a tab to compensate.
  window.tabs.push(app.Tab())
  windowMaker.loadResourcesInTabs(app, window, [resourceUrl])

  return {}
