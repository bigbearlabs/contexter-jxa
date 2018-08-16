
ObjC.import('Cocoa')

module.exports = 

  # FIXME ambigious in the case of multiple processes with same bid.
queryCGWindows = (bundleId) ->
  # $.NSBeep()
  list = $.CGWindowListCopyWindowInfo($.kCGWindowListExcludeDesktopElements, $.kCGNullWindowID)
  convertedList = ObjC.deepUnwrap(list)  # [CGWindowInfo].

  filteredList = convertedList
    .filter (cgInfo) ->
      pid = cgInfo["kCGWindowOwnerPID"]
      runningAppForPid = $.NSRunningApplication.runningApplicationWithProcessIdentifier(pid)
      runningAppBundleId = ObjC.unwrap(runningAppForPid.bundleIdentifier)

      return runningAppBundleId == bundleId

  return filteredList
