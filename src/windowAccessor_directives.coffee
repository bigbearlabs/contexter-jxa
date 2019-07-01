returnFirstSuccessful = require('./lib/returnFirstSuccessful')
runCmd = require('./lib/runCmd')


# TODO add bundle id mappings such that chrome canary uses directive for chrome, safari tech preview uses that for safari etc.


pinnedTabCount = null  # hackish global to count pinned tabs only once per lifecycle.

# directives for app-specific operations to override those defined in `baseAccessor`.
module.exports = directives =

  "com.apple.Safari":
    # obtain count of pinned tabs in order to exclude from elements to probe.
    getElementsData: (window) ->
      tabs = window.tabs()

      pinnedTabCount = pinnedTabCount || (tabs.length - @getSafariUnpinnedTabCount())
      elements = tabs.slice(pinnedTabCount)
      currentElementIndex = window.currentTab().index() - 1 - pinnedTabCount 

      return {elements, currentElementIndex}

    getSafariUnpinnedTabCount: () =>
      bundleId = "com.apple.Safari"
      app = Application('System Events').applicationProcesses.whose({ bundleIdentifier: bundleId })
      window = app.windows[0]
      unless window?
        throw Error('cx-jxa: no safari window in current space')

      tabGroup = window.groups[0]

      # exceptionally handle case where a 1-tab window doesn't show pinned sites.
      if tabGroup()[0] == null
        return 1

      tabs = tabGroup.radioButtons
      descriptions = tabs.roleDescription()[0]

      pinnedCount = descriptions.filter((desc) => 
        desc == "pinned tab"
      ).length

      return descriptions.length - pinnedCount

  "com.google.Chrome":
    getElementsData: (window) =>
      # browser-style script vocabulary
      elements = window.tabs()
      currentElementIndex =
        window.activeTabIndex() - 1 # chrome Version 56.0.2913.3 canary (64-bit)

      return {elements, currentElementIndex}

  "com.apple.dt.Xcode":

    skipSystemEventsProbe: true

    getUrl: (element) =>
      returnFirstSuccessful [
        -> element.file().toString()  # xcode 8
        -> element.fileReference.fullPath()[0]  # xcode 7.*
      ]

    getElementName: (element) =>
      returnFirstSuccessful [
        -> element.name()  # # xcode 8
        -> element.fileReference.name()[0]  # # xcode 7.*
      ]

    getWindows: (application) =>
      application.windows()
        .filter (w) =>
          # since xcode9, we can end up with a bunch of hidden windows that can cause a lot of errors.
          (w.id() || "-1").toString() != "-1"


  'com.googlecode.iterm2':

    skipSystemEventsProbe: true

    # return path of the current session. this is sluggish on old machines!
    getUrl: (element) ->
      try
        ttyName = element.tty()
        # console.log(ttyName)
        if ttyName
          # run a command that finds the working directory of a tty.
          # FIXME this command is very brittle.
          cmd = """
            short_tty=`basename #{ttyName}`
            tty_pid=`ps -f -o pid,etime,command | grep $short_tty | sort -k 9 | head -n 1 | awk '{print $2}'`
            /usr/sbin/lsof -a -p $tty_pid -d cwd -n -F n | grep '^n' | sed 's/^n//'
          """

          cmdOut = runCmd(cmd).trim()

          return cmdOut
        else
          throw Error('cx-jxa: no ttyName for window')

      catch e
        debugger

    getElementsData: (window) ->
      # for now, just the frontmost tab of an iterm window, since returning all elements will potentially be too slow.
      elements = window.tabs()
        .map (t) -> t.currentSession()
        .map (s) -> 
          id: s.id,
          tabId: s.id(),
          name: s.name,
          tty: s.tty

      currentId = window.currentSession().id()
      currentElementIndex = elements.map((e)-> e.id()).indexOf(currentId)

      return {elements, currentElementIndex}