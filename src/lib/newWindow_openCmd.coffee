# ---
# doit:
#   cmd: |
#     sleep 0.3 & `dirname #{file}`/../../dist/`basename #{file} .coffee`.js

#   args:
#
# test:
# ---


executeReportingNewWindowIds = require('./executeReportingNewWindowIds')



module.exports =

(bundleId, resourceUrls) ->
  # CASE resourceUrls.length != 1

  resourceUrl = resourceUrls[0]

  newWindowIds = executeReportingNewWindowIds bundleId, ->
    open(bundleId, resourceUrl)

  # CASE no new windows

  # CASE more than 1 new window

  newWindowId = newWindowIds.reverse()[0]

  return {
    new_window:
      id: newWindowId
  }




#== extractables


open = (bundleId, resourceUrl) ->
  # run shell command to `open <resourceUrl>`.
  cmd = "open -b #{bundleId} #{resourceUrl}"
  sh(cmd)




sh = (cmdString) ->
  app = Application.currentApplication()
  app.includeStandardAdditions = true
  app.doShellScript(cmdString)




#== quick-and-dirty test harness method.
global.main = (argv) ->
  bundleId = "com.torusknot.SourceTreeNotMAS"  # PARAM
  resourceUrls = [ "file:///Users/ilo/src/bigbearlabs/contexter" ] # PARAM
  module.exports(bundleId, resourceUrls)
