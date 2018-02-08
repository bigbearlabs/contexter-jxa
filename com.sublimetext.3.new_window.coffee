# ---
# doit:
#   cmd: |
#     coffee -cp #{file} | osascript -l JavaScript - 'resourceUrls=["file:///usr/local/bin", "file:///etc/"]'
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
  args = argsHash(argv)
  resourceUrls = JSON.parse(args.resourceUrls)
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
