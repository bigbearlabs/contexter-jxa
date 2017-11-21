# ---
# doit:
#   cmd: |
#     coffee -cp #{file} | osascript -l JavaScript - '["file:///usr/local/bin", "file:///etc/"]'
#   args:
#
# test:
# ---


ObjC.import('stdlib')


bundleId = 'com.sublimetext.3'
app = Application(bundleId)
app.includeStandardAdditions = true

@run = (argv) ->
  resourceUrls = JSON.parse(argv[0])
  return JSON.stringify(newWindow(resourceUrls))


newWindow = (resourceUrls) ->
  # TODO assert valid subl bin in path.

  params = [ "-n", paths(resourceUrls)... ]
  cmd = "subl"

  result = exec(cmd, params)

  return 
    cmd: cmd
    params: params
    result: result
  

paths = (urlStrings) ->
  urlStrings.map (s) -> 
    s2 = s.replace(/^file:\/\//, "")  # file:///xyz -> /xyz
      .replace("\"", "\\\"")  # quote '"'
    return "\"#{s2}\""  # "/xyz"

exec = (cmd, params) ->
  pathEnvVar = $.getenv('PATH')
  $.setenv("PATH", pathEnvVar, 1);  
  status = $.system([cmd, params...].join(" "))
  # $.exit(status >> 8)
  if status != 0
    throw status
  "exec finished. TODO parse stdout,stderr"