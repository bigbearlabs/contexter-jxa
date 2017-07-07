# ---
# doit:
#   cmd: |
#     coffee -cp #{file} | osascript -l JavaScript - '["file:///usr/local/bin"]'
#   args:
#
# test:
# ---

bundleId = 'com.googlecode.iterm2'
app = Application(bundleId)

@run = (argv) ->
  resourceUrls = JSON.parse(argv[0])
  JSON.stringify(newWindow(resourceUrls))


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
