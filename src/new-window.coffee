# ---
# doit:
#   cmd: |
#     coffee -cp #{file} | osascript -l JavaScript - 'bundleId=com.google.Chrome.canary url=http://google.com'
#   args:
#
# test:
# ---

newWindow_openCmd = require './lib/newWindow_openCmd'
windowMaker = require './windowMaker'
argsHash = require './lib/argsHash'

stacktracer = require 'sourcemapped-stacktrace'
# WIP this lib has strong assumptions on browser-based context
# that we need to remove before we can use it in a jxa context.


DEBUG = true  # debug HACK


global.main = (argv) ->

  # for quick testing:
  # argv = ["bundleId=com.google.Chrome.canary", "url=http://google.com"]

  try

    args = argsHash(argv)

    bundleId = args.bundleId ||
      throw Error("e5: missing or bad argument: bundleId")

    appBundlePath = args.appBundlePath

    resourceUrls =
      if args.url
        [args.url]
      else if args.resourceUrls
        JSON.parse(args.resourceUrls)
    unless resourceUrls?
      throw Error("e6: missing or bad argument: url|resourceUrls")
            
      # err = "e4: no new_window directive for #{bundleId}"

    app = 
      if appBundlePath?
        Application(appBundlePath)
      else
        Application(bundleId)

    windowMaker = windowMaker(bundleId)

    messages = []

    result =

      try
        messages.push("using scripting API with maker for #{bundleId}")
        newWindow(app, resourceUrls, windowMaker)

      catch e
        messages.push("using scripting API failed; falling back to openCmd. error: #{e}")

        newWindow_openCmd(resourceUrls, {bundleId, bundlePath: appBundlePath})

        # TODO for consistency, we should eventually fold the _openCmd impl
        # into the window maker directives with a defaulting mechanism
        # (so we can avoid enumerating all apps that must use this default directive)

    if DEBUG
      result.trace = messages
      debugger

    return JSON.stringify(result)


  catch e
    # to debug exceptions, enable the 'pause on js context' safari developer option.
    debugger

    throw e

    # TODO uncaught error tracing out stderr is very had to debug.
    # catch and error out, with more relevant src info (e.g. .coffee line)
  

newWindow = (app, resourceUrls, windowMaker) ->

  window = windowMaker.createWindow(app)
  # delay(0.1)

  windowMaker.loadResources(app, window, resourceUrls)

  windowId = window.id()

  return {
    new_window:
      id: windowId
  }
