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

    resourceUrls = [args.url]

    windowId = args.windowId            
    window = 
      app.windows().find((w) -> "#{w.id()}" == windowId) ||
        throw Error("e11: couldn't find window for id #{windowId}")


    windowMaker = windowMaker(bundleId)

    messages = []

    result =

      try
        messages.push("using scripting API with maker for #{bundleId}")

        addTab(app, window, resourceUrls, windowMaker)

      catch e
        # messages.push("using scripting API failed; falling back to openCmd. error: #{e}")

        # newWindow_openCmd(resourceUrls, {bundleId, bundlePath: appBundlePath})

        # # TODO for consistency, we should eventually fold the _openCmd impl
        # # into the window maker directives with a defaulting mechanism
        # # (so we can avoid enumerating all apps that must use this default directive)

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
  

addTab = (app, window, resourceUrls, windowMaker) ->

  windowMaker.loadResourcesInTabs(app, window, resourceUrls)

  return {}
