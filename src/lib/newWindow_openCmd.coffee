# ---
# doit:
#   cmd: |
#     sleep 0.3 & `dirname #{file}`/../../dist/`basename #{file} .coffee`.js

#   args:
#
# test:
# ---


executeReportingNewWindowIds = require('./executeReportingNewWindowIds')
runCmd = require('./runCmd')



#== quick-and-dirty test harness method.
global.main = (argv) ->
  bundleId = "com.torusknot.SourceTreeNotMAS"  # PARAM
  resourceUrls = [ "file:///Users/ilo/src/bigbearlabs/contexter" ] # PARAM
  module.exports(bundleId, resourceUrls)



module.exports =

newWindow_openCmd = (resourceUrls, handlerSpecifier) ->
  
  if resourceUrls.length != 1
    throw Error("new-window using `open` only supports 1 resource url.")

  resourceUrl = resourceUrls[0]

  bundleId = handlerSpecifier.bundleId ||
    throw Error("new-window using `open` requires bundle id.")

  bundlePath = handlerSpecifier.bundlePath

  # # launch app if it's not found and wait a little for it to warm up.
  # processesForBid = Application('System Events').applicationProcesses.whose({ bundleIdentifier: bundleId })
  # if processesForBid.length == 0
  #   Application(bundleId).activate()
  #   delay(1)
  #   # TODO consider periodically chaging window set to see if the count stabilises.

  newWindowIds = executeReportingNewWindowIds bundleId, ->
    open(bundleId, bundlePath, resourceUrl)

  # CASE no new windows
  # CASE more than 1 new window
  msg = null
  if newWindowIds.length != 1
    msg = "unexpected count of new window ids: #{newWindowIds}"

  newWindowId = newWindowIds.reverse()[0]

  return {
    new_window:
      id: newWindowId
    msg: msg
  }




#== extractables


open = (bundleId, bundlePath, resourceUrl) ->
  # run shell command to `open <resourceUrl>`.

  cmd =
    if bundlePath?
      "open -a '#{bundlePath}' #{resourceUrl}"
    else
      "open -b #{bundleId} #{resourceUrl}"
      
  runCmd(cmd)
