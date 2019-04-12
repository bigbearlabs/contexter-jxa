ObjC.import('AppKit')


module.exports =

  runningApps = (bundleId) ->   # string

    apps = $.NSWorkspace.sharedWorkspace.runningApplications # Note these never take () unless they have arguments
    apps = ObjC.unwrap(apps) # Unwrap the NSArray instance to a normal JS array

    matchingApps = apps.filter (app) ->
      ObjC.unwrap(app.bundleIdentifier) == bundleId

    pids = matchingApps.map (runningApp) -> ObjC.unwrap(runningApp.processIdentifier)

    return pids.map (pid) -> Application(pid)
