returnFirstSuccessful = require('./lib/returnFirstSuccessful')
directives = require('./windowAccessor_directives')
merged = require('./lib/merged')


module.exports = 

  (bundleId) ->
    specificAccessorOperations = directives[bundleId]

    return \
      if specificAccessorOperations?
        merged(baseAccessor, specificAccessorOperations)
      else 
        baseAccessor


# operations using scripting api to collect information on windows.
baseAccessor = 

  # return a url or posix path for a window's element.
  getUrl: (element) ->
    returnFirstSuccessful [
      ->
        element.url()
      ->
        # keynote
        element.file().toString()
      ->
        # preview
        element.path()
    ]

  # return one of the elements of a window which url is bookmarked.
  # the default implementation returns either the single element or the first element marked as 'current'.
  getAnchor: (elements) ->
    if elements.length == 1
      return elements[0]
 
    # for multiple elements, return the one marked as current.
    if currentElem = elements.find((e) ->
      e?.current
    )
      return currentElem

    throw JSON.stringify {
      msg: "cx-jxa: no element marked as current"
      data: elements
    }

  # return elements of a window.
  # elements can be anything that participates in a focus order, such as tabs, folder or mailbox.
  # if returning only one element for a window (simplest implementation), make sure it's in an array.
  getElements: (window) ->
    returnFirstSuccessful [
      ->
        # finder-style script vocabulary
        [ window.target() ]
      ->
        # browser-style script vocabulary
        window.tabs()
      ->
        # vocabulary for doc windows
        [ window.document() ]
    ]


  # ## window-level accessors

  getId: (window) ->
    window.id()

  getTitle: (window) ->
    window.name()

  # return index of the window's element which is frontmost.
  getCurrentElementIndex: (window, elements) ->
    returnFirstSuccessful [
      ->
        window.currentTab().index() - 1
      ->
        # for chrome, use activeTab instead.
        window.activeTabIndex() - 1 # chrome Version 56.0.2913.3 canary (64-bit)
      ->
        null
    ]

  # ## element-level accessors

  getElementName: (element) ->
    element.name()


  # ## app-level accessors

  getWindows: (application) ->
    application.windows()

    # DEV uncomment below to reduce probe volume to the frontmost window of the app.
    # [ application.windows()[0] ]

