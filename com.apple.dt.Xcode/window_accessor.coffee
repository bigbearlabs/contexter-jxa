@windowAccessor =

  bundleId: 'com.apple.dt.Xcode'

  skipSystemEventsProbe: true


  getUrl: (element) ->
    element.fileReference.fullPath()[0]

  getElementName: (element) ->
    element.fileReference.name()[0]


