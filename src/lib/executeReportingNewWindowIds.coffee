
module.exports = 

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

sleepFor = `
  function ( sleepDuration ){
      var now = new Date().getTime();
      while(new Date().getTime() < now + sleepDuration){ /* do nothing */ }
  }
`

ObjC.import('Cocoa')

queryCGWindows = (bundleId) ->
  # $.NSBeep()
  list = $.CGWindowListCopyWindowInfo($.kCGWindowListExcludeDesktopElements, $.kCGNullWindowID)
  convertedList = ObjC.deepUnwrap(list)  # [CGWindowInfo].

  filteredList = convertedList
    .filter (cgInfo) ->
      pid = cgInfo["kCGWindowOwnerPID"]
      runningAppForPid = $.NSRunningApplication.runningApplicationWithProcessIdentifier(pid)
      runningAppBundleId = ObjC.unwrap(runningAppForPid.bundleIdentifier)
      runningAppBundleId == bundleId

  return filteredList
