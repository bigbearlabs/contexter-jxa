module.exports =
  runCmd = (cmdString) ->
    app = Application.currentApplication()
    app.includeStandardAdditions = true
    result = app.doShellScript(cmdString)
    return result