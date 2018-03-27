# ---
# doit:
#   cmd: |
#     coffee -cp #{file} | osascript -l JavaScript - 'resourceUrls=["file:///usr/local/bin", "file:///etc/"]'
#   args:
#
# test:
# ---


# ObjC.import('stdlib')


bundleId = 'com.apple.finder'
app = Application(bundleId)
# app.includeStandardAdditions = true

@run = (argv) ->
  args = argsHash(argv)
  resourceUrls = JSON.parse(args.resourceUrls)
  return JSON.stringify(newWindow(resourceUrls))


newWindow = (resourceUrls) ->  
  window = app.FinderWindow().make()

  firstPathString = paths(resourceUrls)[0]
  firstPath = Path(firstPathString)
  window.properties = {
    target: Path(firstPath)
  }

  windowId = window.id()

  return \
    new_window:
      id: windowId
  

paths = (urlStrings) ->  # TACTICAL
  urlStrings.map (s) ->
    s2 = s.replace(/^file:\/\//, "")  # file:///xyz -> /xyz
    #   .replace("\"", "\\\"")  # quote '"'
    # return "\"#{s2}\""  # "/xyz"



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
