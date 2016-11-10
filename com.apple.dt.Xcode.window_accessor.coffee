@windowAccessor =

  bundleId: 'com.apple.dt.Xcode'

  skipSystemEventsProbe: true


  getUrl: (element) =>
    @returnFirstSuccessful [
    	-> element.file().toString()  # xcode 8
    	-> element.fileReference.fullPath()[0]  # xcode 7.*
    ]
  getElementName: (element) =>
    @returnFirstSuccessful [
    	-> element.name()  # # xcode 8
	    -> element.fileReference.name()[0]  # # xcode 7.*
	]
