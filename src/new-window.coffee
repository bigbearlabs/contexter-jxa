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

DEBUG = true  # debug


global.main = (argv) ->

  # for quick testing:
  # argv = ["bundleId=com.google.Chrome.canary", "url=http://google.com"]

  args = argsHash(argv)

  bundleId = args.bundleId ||
    throw Error("e5: missing or bad argument: bundleId")

  resourceUrls =
    if args.url
      [args.url]
    else if args.resourceUrls
      JSON.parse(args.resourceUrls)
  unless resourceUrls?
    throw Error("e6: missing or bad argument: url|resourceUrls")
          
    # err = "e4: no new_window directive for #{bundleId}"

  app = Application(bundleId)

  windowMaker = windowMaker(bundleId)

  messages = []
  result =
    try
      messages.push("using scripting API with maker #{windowMaker}")
      newWindow(app, resourceUrls, windowMaker)
    catch e
      # throw e  # DEBUG
      messages.push("using scripting API failed; falling back to openCmd. error: #{e}")
      newWindow_openCmd(bundleId, resourceUrls)

  if DEBUG
    result.trace = messages
    debugger

  return JSON.stringify(result)



newWindow = (app, resourceUrls, windowMaker) ->

  window = windowMaker.createWindow(app)
  # delay(0.1)

  windowMaker.loadResources(app, window, resourceUrls)

  windowId = window.id()

  return {
    new_window:
      id: windowId
  }


# newWindowUsingOpen = (app, resourceUrls) ->
#   resourceUrls.forEach (url) ->
#     app.open(url)



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
