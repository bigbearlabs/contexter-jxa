# ---
# doit:
#   cmd: |
#     coffee -cp #{file} | osascript -l JavaScript - 'resourceUrls=["file:///usr/local/bin"]'
#   args:
#
# test:
# ---

bundleId = 'com.googlecode.iterm2'
app = Application(bundleId)

@run = (argv) ->
  args = argsHash(argv)
  resourceUrls = JSON.parse(args.resourceUrls)


newWindow = (resourceUrls) ->
  path = $.NSURL.URLWithString(resourceUrls[0]).path.cString
  window = app.createWindowWithDefaultProfile()
  session = window.tabs[0].sessions[0]
  cmd ="cd '#{path}'"
  app.write(session,{text: cmd})

  return {
    new_window:
      id: window.id()
  }

  # TODO loop through resourceUrls, create new tabs and cd / otherwise restore context.



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
