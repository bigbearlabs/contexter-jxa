let argsHash = require('./lib/argsHash')


global.main = (argv) => {

  let args = argsHash(argv)

  let windowId = args.windowId

  let w = Application("com.apple.Safari").windows().find( w => w.id() == windowId )

  if (w == null) {
    throw `window not found for id ${windowId}`
  }

  let originallyActiveTabIndex = (_activeTabIndex(w) || [null, 0])[1]
  let nullUrlIndexes = _nullUrlIndexes(w)

  for (let i of nullUrlIndexes) {
    doActivateSafariTab(w, i)
    // delay(1)
  }

  doActivateSafariTab(w, originallyActiveTabIndex)

  // TODO return result to stdout.
  return JSON.stringify({
    windowId: windowId,
    activeTabIndex: originallyActiveTabIndex,
    scannedTabs: nullUrlIndexes
  })
}


// side-effecting functions

function doActivateSafariTab(w, i) {
  let tab = w.tabs()[i]
  w.currentTab = tab
}


// deriver functions

function _nullUrlIndexes(w) {
  let tabs = w.tabs()
  let urls = tabs.map( t => t.url() )

  let urlIndexTuples = tabs.map((o, i) => [o.url(), i])

  let nullUrlIndexes = urlIndexTuples
    .filter( e => e[0] == null )
    .map( e => e[1] )
    
  return nullUrlIndexes
}

function _activeTabIndex(w) {
  let activeIndexTuples = w.tabs().map((t, i) => [t.visible(), i])
  return activeIndexTuples
    .find( t => t[0] == true )
}


// util functions

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
