# ---
# doit:
#   cmd: |
#     coffee -cp #{file} | osascript -l JavaScript - '["file:///usr/local/bin", "file:///etc/"]'
#   args:
#
# test:
# ---


# FIXME make input arguments more standard-friendly - to begin with, de-json the input.

ObjC.import('stdlib')


bundleId = 'com.sublimetext.3'
app = Application(bundleId)
app.includeStandardAdditions = true

@run = (argv) ->
  resourceUrls = JSON.parse(argv[0])
  return JSON.stringify(newWindow(resourceUrls))


newWindow = (resourceUrlsString) ->
  # TODO assert valid subl bin in path.

  params = [ "-n", quotedPaths(resourceUrlsString)... ]
  cmd = "/usr/local/bin/subl"  # HARDCODED

  result = exec(cmd, params)

  return \
    cmd: cmd
    params: params
    result: result
    new_window:
      id: "FIX_STUB!!!"
  

quotedPaths = (urlStrings) ->
  urlStrings.map (s) ->
    s2 = s.replace(/^file:\/\//, "")  # file:///xyz -> /xyz
      .replace("\"", "\\\"")  # quote '"'
    return "\"#{s2}\""  # "/xyz"

exec = (cmd, params) ->
  pathEnvVar = $.getenv('PATH')
  $.setenv("PATH", pathEnvVar, 1)
  status = $.system([cmd, params...].join(" "))
  # $.exit(status >> 8)
  if status != 0
    throw status
  "exec finished. TODO parse stdout,stderr"
