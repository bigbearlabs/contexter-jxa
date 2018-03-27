# ---
# doit:
#   cmd: |
#     sleep 0.3 & `dirname #{file}`/../../dist/`basename #{file} .coffee`.js

#   args:
#
# test:
# ---

module.exports =

  (bundleId, resourceUrls) -> 
    # CASE resourceUrls.length != 1

    resourceUrl = resourceUrls[0]

    newWindowIds = executeReportingNewWindowIds bundleId, ->
      open(bundleId, resourceUrl)

    # CASE no new windows

    # CASE more than 1 new window

    newWindowId = newWindowIds[0]

    return JSON.stringify
      new_window:
        id: newWindowId


open = (bundleId, resourceUrl) ->
  # run shell command to `open <resourceUrl>`.
  cmd = "open -b #{bundleId} #{resourceUrl}"
  sh(cmd)

executeReportingNewWindowIds = (bundleId, operation) ->
  # execute the operation, taking before / after snapshots of window list, to return the diff.
  windowList = queryCGWindows(bundleId)

  operation()

  # need a delay with apps which are sluggish to open resources, e.g. Sourcetree
  sleepFor(1500)  # STUB

  windowListAfter = queryCGWindows(bundleId)

  # diff the window ids.
  windowIdsBefore = windowList.map (e) -> e["kCGWindowNumber"]
  windowIdsAfter = windowListAfter.map (e) -> e["kCGWindowNumber"]

  newIds = windowIdsAfter.filter (e) ->
    windowIdsBefore.indexOf(e) < 0

  return newIds



#== extractables

sh = (cmdString) ->
  app = Application.currentApplication()
  app.includeStandardAdditions = true
  app.doShellScript(cmdString)


ObjC.import('Cocoa')

queryCGWindows = (bundleId) ->
  # $.NSBeep()
  list = $.CGWindowListCopyWindowInfo($.kCGWindowListExcludeDesktopElements, $.kCGNullWindowID)
  convertedList = ObjC.deepUnwrap(list)  # [CGWindowInfo].
  return convertedList


sleepFor = `
  function ( sleepDuration ){
      var now = new Date().getTime();
      while(new Date().getTime() < now + sleepDuration){ /* do nothing */ } 
  }
`


#== quick-and-dirty test harness method.
global.main = (argv) ->
  bundleId = "com.torusknot.SourceTreeNotMAS"  # PARAM
  resourceUrls = [ "file:///Users/ilo/src/bigbearlabs/contexter" ] # PARAM
  module.exports(bundleId, resourceUrls)
