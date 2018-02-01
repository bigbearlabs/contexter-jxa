# ---
# doit:
#   cmd: |
#     coffee -cp #{file} | osascript -l JavaScript - '["file:///usr/local/bin", "file:///etc/"]'
#   args:
#
# test:
# ---


# ObjC.import('stdlib')


bundleId = 'com.apple.finder'
app = Application(bundleId)
# app.includeStandardAdditions = true

@run = (argv) ->
  # test with: 
  ## argv = '["file:///usr/local/bin"]'
  resourceUrlsString = JSON.parse(argv[0])
  return JSON.stringify(newWindow(resourceUrlsString))


newWindow = (resourceUrlsString) ->
  firstPathString = paths(resourceUrlsString)[0]
  firstPath = Path(firstPathString)

  window = app.FinderWindow().make()

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
